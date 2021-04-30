# frozen_string_literal: true

# ProjectUser is the relation table between a Project and an User.
# Users are collaborators to a Project, with write access if they have confirmed their participation.
class ProjectUser < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  belongs_to :project
  belongs_to :user

  before_create :generate_valid_token
  after_commit :notify_project_collaborator_to_valid, on: :create
  after_update :notify_project_author_when_collaborator_valid, if: :saved_change_to_is_valid?

  private

  def generate_valid_token
    loop do
      self.valid_token = SecureRandom.hex
      break unless self.class.exists?(valid_token: valid_token)
    end
  end

  def notify_project_collaborator_to_valid
    NotificationCenter.call type: 'notify_project_collaborator_to_valid',
                            receiver: user,
                            attached_object: self
  end

  def notify_project_author_when_collaborator_valid
    NotificationCenter.call type: 'notify_project_author_when_collaborator_valid',
                            receiver: project.author.user,
                            attached_object: self
  end
end
