# frozen_string_literal: true

# Asynchronously synchronize the projects with OpenLab-Projects
class OpenlabWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: true

  def initialize
    client = Openlab::Client.new(app_secret: Setting.get('openlab_app_secret'))
    @projets = Openlab::Projects.new(client)
    super
  end

  def perform(action, project_id)
    logger.debug ['Openlab sync', action, "project ID: #{project_id}"]

    case action.to_s
    when /create/
      project = Project.find(project_id)
      response = @projets.create(project.openlab_attributes)
    when /update/
      project = Project.find(project_id)
      response = @projets.update(project_id, project.openlab_attributes)
    when /destroy/
      response = @projets.destroy(project_id)
    else
      raise NotImplementedError
    end

    logger.debug ['Openlab sync', 'RESPONSE ERROR', response.inspect] unless response.success?
  rescue Errno::ECONNREFUSED => e
    logger.warn "Unable to connect to OpenProject, maybe the dev instance is not running: #{e}" if Rails.env.development?
  end
end
