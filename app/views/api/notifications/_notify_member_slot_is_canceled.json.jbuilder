# frozen_string_literal: true

json.title notification.notification_type
json.description t('.your_reservation_RESERVABLE_of_DATE_was_successfully_cancelled',
                   RESERVABLE: notification.attached_object.reservation&.reservable&.name,
                   DATE: I18n.l(notification.attached_object.start_at, format: :long))

