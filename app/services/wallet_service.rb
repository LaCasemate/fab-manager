# frozen_string_literal: true

# Provides methods to manage wallets
class WalletService
  def initialize(user: nil, wallet: nil)
    @user = user
    @wallet = wallet
  end

  ## credit an amount to wallet, if credit success then return a wallet transaction and notify to admin
  def credit(amount)
    ActiveRecord::Base.transaction do
      if @wallet.credit(amount)
        transaction = WalletTransaction.new(
          invoicing_profile: @user.invoicing_profile,
          wallet: @wallet,
          transaction_type: 'credit',
          amount: amount
        )
        if transaction.save
          NotificationCenter.call type: 'notify_user_wallet_is_credited',
                                  receiver: @wallet.user,
                                  attached_object: transaction
          NotificationCenter.call type: 'notify_admin_user_wallet_is_credited',
                                  receiver: User.admins_and_managers,
                                  attached_object: transaction
          return transaction
        end
      end
      raise ActiveRecord::Rollback
    end
    false
  end

  ## debit an amount to wallet, if debit success then return a wallet transaction
  def debit(amount, transactable)
    ActiveRecord::Base.transaction do
      if @wallet.debit(amount)
        transaction = WalletTransaction.new(
          invoicing_profile: @user&.invoicing_profile,
          wallet: @wallet,
          transaction_type: 'debit',
          amount: amount,
          transactable: transactable
        )

        return transaction if transaction.save
      end
      raise ActiveRecord::Rollback
    end
    false
  end

  ## create a refund invoice associated with the given wallet transaction
  def create_avoir(wallet_transaction, avoir_date, description)
    avoir = Avoir.new
    avoir.type = 'Avoir'
    avoir.invoiced = wallet_transaction
    avoir.avoir_date = avoir_date
    avoir.created_at = avoir_date
    avoir.description = description
    avoir.payment_method = 'wallet'
    avoir.subscription_to_expire = false
    avoir.invoicing_profile_id = wallet_transaction.wallet.user.invoicing_profile.id
    avoir.statistic_profile_id = wallet_transaction.wallet.user.statistic_profile.id
    avoir.total = wallet_transaction.amount * 100.0
    avoir.save!

    ii = InvoiceItem.new
    ii.amount = wallet_transaction.amount * 100.0
    ii.description = I18n.t('invoices.wallet_credit')
    ii.invoice = avoir
    ii.save!
  end

  ##
  # Compute the amount decreased from the user's wallet, if applicable
  # @param payment {Invoice|PaymentSchedule}
  # @param user {User} the customer
  # @param coupon {Coupon|String} Coupon object or code
  ##
  def self.wallet_amount_debit(payment, user, coupon = nil)
    total = if payment.is_a? PaymentSchedule
              payment.payment_schedule_items.first.amount
            else
              payment.total
            end
    total = CouponService.new.apply(total, coupon, user.id) if coupon

    wallet_amount = (user.wallet.amount * 100).to_i

    wallet_amount >= total ? total : wallet_amount
  end

  ##
  # Subtract the amount of the transactable item (Subscription|Reservation) from the customer's wallet
  ##
  def self.debit_user_wallet(payment, user, transactable)
    wallet_amount = WalletService.wallet_amount_debit(payment, user)
    return unless wallet_amount.present? && wallet_amount != 0

    amount = wallet_amount / 100.0
    wallet_transaction = WalletService.new(user: user, wallet: user.wallet).debit(amount, transactable)
    # wallet debit success
    raise DebitWalletError unless wallet_transaction

    payment.set_wallet_transaction(wallet_amount, wallet_transaction.id)
  end
end
