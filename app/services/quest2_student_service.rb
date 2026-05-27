class Quest2StudentService
  SEEDED_AGENT_CODENAMES = ["Atlas", "Echo", "Nova", "Viper"].freeze
  SEEDED_MISSION_TITLES = [
    "Ember Trace",
    "Frozen Cipher",
    "Ghost Signal",
    "Glass Horizon",
    "Harbor Shield",
    "Iron Veil",
    "Midnight Relay",
    "Sapphire Run",
    "Silent Echo",
    "Solar Tide"
  ].freeze
  SEEDED_SKILL_NAMES = ["Cryptography", "Field Medicine", "Infiltration", "Negotiation", "Recon"].freeze

  class << self
    # @return [String]
    def all_agents
      Agent.where(codename: SEEDED_AGENT_CODENAMES).order(:codename).pluck(:codename).join("\n")
    end

    # @return [String]
    def all_missions
      Mission.where(title: SEEDED_MISSION_TITLES).order(:title).pluck(:title).join("\n")
    end

    # @return [String]
    def agents_with_missions
      mission_titles_sql = SEEDED_MISSION_TITLES.map { |t| ActiveRecord::Base.connection.quote(t) }.join(", ")

      missions_subq = <<~SQL.squish
        (SELECT group_concat(t.title, ', ') FROM (
          SELECT title FROM missions WHERE agent_id = agents.id AND title IN (#{mission_titles_sql}) ORDER BY title
        ) t)
      SQL

      Agent.where(codename: SEEDED_AGENT_CODENAMES)
           .order(:codename)
           .select("agents.codename, #{missions_subq} AS missions_list")
           .map { |a| "#{a.codename}: #{a.attributes['missions_list']}" }
           .join("\n")
    end

    # @return [String]
    def agents_with_missions_sorted_by_mission_count
      mission_titles_sql = SEEDED_MISSION_TITLES.map { |t| ActiveRecord::Base.connection.quote(t) }.join(", ")

      missions_list_subq = <<~SQL.squish
        (SELECT group_concat(t.title, ', ') FROM (
          SELECT title FROM missions WHERE agent_id = agents.id AND title IN (#{mission_titles_sql}) ORDER BY title
        ) t)
      SQL

      missions_count_subq = <<~SQL.squish
        (SELECT COUNT(*) FROM missions WHERE agent_id = agents.id AND title IN (#{mission_titles_sql}))
      SQL

      Agent.where(codename: SEEDED_AGENT_CODENAMES)
           .select("agents.codename, #{missions_list_subq} AS missions_list, #{missions_count_subq} AS missions_count")
           .map { |a| [a.codename, a.attributes['missions_count'].to_i, a.attributes['missions_list']] }
           .sort_by { |codename, count, _| [-count, codename] }
           .map { |codename, count, list| "#{codename} (#{count}): #{list}" }
           .join("\n")
    end

    # @return [String]
    def agents_with_skills
      skill_names_sql = SEEDED_SKILL_NAMES.map { |t| ActiveRecord::Base.connection.quote(t) }.join(", ")

      skills_list_subq = <<~SQL.squish
        (SELECT group_concat(t.name, ', ') FROM (
          SELECT s.name FROM skills s
          JOIN agent_skills ag ON ag.skill_id = s.id
          WHERE ag.agent_id = agents.id AND s.name IN (#{skill_names_sql})
          ORDER BY s.name
        ) t)
      SQL

      Agent.where(codename: SEEDED_AGENT_CODENAMES)
           .order(:codename)
           .select("agents.codename, #{skills_list_subq} AS skills_list")
           .map { |a| "#{a.codename}: #{a.attributes['skills_list']}" }
           .join("\n")
    end

    # @return [String]
    def skills_by_agent_count
      agent_codenames_sql = SEEDED_AGENT_CODENAMES.map { |t| ActiveRecord::Base.connection.quote(t) }.join(", ")

      agents_count_subq = <<~SQL.squish
        (SELECT COUNT(DISTINCT ag.agent_id) FROM agent_skills ag
         JOIN agents a ON a.id = ag.agent_id
         WHERE ag.skill_id = skills.id AND a.codename IN (#{agent_codenames_sql}))
      SQL

      agents_list_subq = <<~SQL.squish
        (SELECT group_concat(t.codename, ', ') FROM (
          SELECT a.codename FROM agent_skills ag
          JOIN agents a ON a.id = ag.agent_id
          WHERE ag.skill_id = skills.id AND a.codename IN (#{agent_codenames_sql})
          ORDER BY a.codename
        ) t)
      SQL

      Skill.where(name: SEEDED_SKILL_NAMES)
           .select("skills.name, #{agents_count_subq} AS agents_count, #{agents_list_subq} AS agents_list")
           .order("agents_count DESC, skills.name ASC")
           .map { |s| "#{s.name} (#{s.attributes['agents_count'].to_i}): #{s.attributes['agents_list']}" }
           .join("\n")
    end
  end
end
