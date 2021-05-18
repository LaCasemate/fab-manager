# frozen_string_literal: true

json.title notification.notification_type
amount = notification.attached_object.amount
json.description t('.wallet_is_credited',
                   AMOUNT: number_to_currency(amount),
                   USER: notification.attached_object.wallet.user&.profile&.full_name || t('api.notifications.deleted_user'),
                   ADMIN: notification.attached_object.user&.profile&.full_name || t('api.notifications.deleted_user'))

