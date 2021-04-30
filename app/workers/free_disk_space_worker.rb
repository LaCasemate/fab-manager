# frozen_string_literal: true

# Periodically check if the free disk space available on the host is above the configured limit, otherwise trigger an email alert
class FreeDiskSpaceWorker
  include Sidekiq::Worker

  def perform
    require 'sys/filesystem'

    stat = Sys::Filesystem.stat('.')
    mb_available = stat.block_size * stat.blocks_available / 1024 / 1024

    return if mb_available > Rails.application.secrets.disk_space_mb_alert

    NotificationCenter.call type: 'notify_admin_free_disk_space',
                            receiver: User.adminsys || User.admins,
                            attached_object: Role.first,
                            meta_data: {
                              mb_available: mb_available,
                              threshold: Rails.application.secrets.disk_space_mb_alert
                            }
  end
end
