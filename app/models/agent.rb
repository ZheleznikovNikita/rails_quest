class Agent < ApplicationRecord
  has_many :missions, dependent: :destroy
  has_many :agent_skills, dependent: :destroy
  has_many :skills, through: :agent_skills

  validates :codename, presence: true, uniqueness: true
  validates :level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :active, inclusion: { in: [ true, false ] }
end
