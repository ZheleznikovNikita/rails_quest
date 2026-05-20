class Quest2StudentService
  SEEDED_AGENT_CODENAMES = %w[Atlas Echo Nova Viper].freeze
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
  SEEDED_SKILL_NAMES = %w[Cryptography Field\ Medicine Infiltration Negotiation Recon].freeze

  class << self
    # @return [String]
    def all_agents
      seeded_agents.order(:codename).pluck(:codename).join("\n")
    end

    # @return [String]
    def all_missions
      Mission.where(title: SEEDED_MISSION_TITLES).order(:title).pluck(:title).join("\n")
    end

    # @return [String]
    def agents_with_missions
      seeded_agents.includes(:missions).map do |agent|
        missions = agent.missions.where(title: SEEDED_MISSION_TITLES).order(:title).pluck(:title)
        "#{agent.codename}: #{missions.join(', ')}"
      end.join("\n")
    end

    # @return [String]
    def agents_with_missions_sorted_by_mission_count
      seeded_agents.includes(:missions).to_a
                   .sort_by { |agent| [-agent.missions.where(title: SEEDED_MISSION_TITLES).size, agent.codename] }
                   .map do |agent|
                     missions = agent.missions.where(title: SEEDED_MISSION_TITLES).order(:title).pluck(:title)
                     count = missions.size
                     "#{agent.codename} (#{count}): #{missions.join(', ')}"
                   end.join("\n")
    end

    # @return [String]
    def agents_with_skills
      seeded_agents.includes(:skills).map do |agent|
        skills = agent.skills.where(name: SEEDED_SKILL_NAMES).order(:name).pluck(:name)
        "#{agent.codename}: #{skills.join(', ')}"
      end.join("\n")
    end

    # @return [String]
    def skills_by_agent_count
      Skill.where(name: SEEDED_SKILL_NAMES)
           .left_joins(:agent_skills)
           .group("skills.id")
           .select("skills.*, COUNT(agent_skills.id) AS agents_count")
           .order("agents_count DESC, skills.name ASC")
           .map do |skill|
             agents = skill.agents.where(codename: SEEDED_AGENT_CODENAMES).order(:codename).pluck(:codename)
             "#{skill.name} (#{skill.read_attribute(:agents_count)}): #{agents.join(', ')}"
           end.join("\n")
    end

    private

    def seeded_agents
      Agent.where(codename: SEEDED_AGENT_CODENAMES)
    end
  end
end
