# frozen_string_literal: true

# User is a physical or moral person with its authentication parameters
# It is linked to the Profile model with hold information about this person (like address, name, etc.)
class User < ApplicationRecord
  include NotifyWith::NotificationReceiver
  include NotifyWith::NotificationAttachedObject
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable,
         :confirmable
  rolify

  # enable OmniAuth authentication only if needed
  devise :omniauthable, omniauth_providers: [AuthProvider.active.strategy_name.to_sym] unless
      AuthProvider.active.providable_type == DatabaseProvider.name

  extend FriendlyId
  friendly_id :username, use: :slugged

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile

  has_one :invoicing_profile, dependent: :nullify
  accepts_nested_attributes_for :invoicing_profile

  has_one :statistic_profile, dependent: :nullify
  accepts_nested_attributes_for :statistic_profile

  has_many :project_users, dependent: :destroy
  has_many :projects, through: :project_users

  belongs_to :group

  has_many :users_credits, dependent: :destroy
  has_many :credits, through: :users_credits

  has_many :training_credits, through: :users_credits, source: :training_credit
  has_many :machine_credits, through: :users_credits, source: :machine_credit

  has_many :user_tags, dependent: :destroy
  has_many :tags, through: :user_tags
  accepts_nested_attributes_for :tags, allow_destroy: true

  has_many :exports, dependent: :destroy
  has_many :imports, dependent: :nullify

  has_one :payment_gateway_object, as: :item

  # fix for create admin user
  before_save do
    email&.downcase!
  end

  before_create :assign_default_role
  after_commit :create_stripe_customer, on: [:create]
  after_commit :notify_admin_when_user_is_created, on: :create
  after_create :init_dependencies
  after_update :notify_group_changed, if: :saved_change_to_group_id?
  after_update :update_invoicing_profile, if: :invoicing_data_was_modified?
  after_update :update_statistic_profile, if: :statistic_data_was_modified?
  before_destroy :remove_orphan_drafts

  attr_accessor :cgu
  delegate :first_name, to: :profile
  delegate :last_name, to: :profile
  delegate :subscriptions, to: :statistic_profile
  delegate :reservations, to: :statistic_profile
  delegate :trainings, to: :statistic_profile
  delegate :my_projects, to: :statistic_profile
  delegate :wallet, to: :invoicing_profile
  delegate :wallet_transactions, to: :invoicing_profile
  delegate :invoices, to: :invoicing_profile

  validate :cgu_must_accept, if: :new_record?

  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }

  scope :active, -> { where(is_active: true) }
  scope :without_subscription, -> { includes(statistic_profile: [:subscriptions]).where(subscriptions: { statistic_profile_id: nil }) }
  scope :with_subscription, -> { joins(statistic_profile: [:subscriptions]) }
  scope :not_confirmed, -> { where(confirmed_at: nil) }
  scope :inactive_for_3_years, -> { where('users.last_sign_in_at < ?', 3.years.ago) }

  def to_json(*)
    ApplicationController.new.view_context.render(
      partial: 'api/members/member',
      locals: { member: self },
      formats: [:json],
      handlers: [:jbuilder]
    )
  end

  def self.admins
    User.with_role(:admin)
  end

  def self.members
    User.with_role(:member)
  end

  def self.partners
    User.with_role(:partner)
  end

  def self.managers
    User.with_role(:manager)
  end

  def self.admins_and_managers
    User.with_any_role(:admin, :manager)
  end

  def self.online_payers
    User.with_any_role(:manager, :member)
  end

  def self.adminsys
    return unless Rails.application.secrets.adminsys_email.present?

    User.find_by(email: Rails.application.secrets.adminsys_email)
  end

  def training_machine?(machine)
    return true if admin? || manager?

    trainings.map(&:machines).flatten.uniq.include?(machine)
  end

  def training_reservation_by_machine(machine)
    reservations.where(reservable_type: 'Training', reservable_id: machine.trainings.map(&:id)).first
  end

  def subscribed_plan
    return nil if subscription.nil? || subscription.expired_at < DateTime.current

    subscription.plan
  end

  def subscription
    subscriptions.order(:created_at).last
  end

  def admin?
    has_role? :admin
  end

  def member?
    has_role? :member
  end

  def manager?
    has_role? :manager
  end

  def partner?
    has_role? :partner
  end

  def role
    if admin?
      'admin'
    elsif manager?
      'manager'
    elsif member?
      'member'
    else
      'other'
    end
  end

  def all_projects
    my_projects.to_a.concat projects
  end

  def generate_subscription_invoice(operator_profile_id)
    return unless subscription

    subscription.generate_and_save_invoice(operator_profile_id)
  end

  def active_for_authentication?
    super && is_active?
  end

  def self.from_omniauth(auth)
    active_provider = AuthProvider.active
    raise SecurityError, 'The identity provider does not match the activated one' if active_provider.strategy_name != auth.provider

    where(provider: auth.provider, uid: auth.uid).first_or_create.tap do |user|
      # execute this regardless of whether record exists or not (-> User#tap)
      # this will init or update the user thanks to the information retrieved from the SSO
      user.profile ||= Profile.new
      auth.info.mapping.each do |key, value|
        user.set_data_from_sso_mapping(key, value)
      end
      user.password = Devise.friendly_token[0, 20]
    end
  end

  def need_completion?
    statistic_profile.gender.nil? || profile.first_name.blank? || profile.last_name.blank? || username.blank? ||
      email.blank? || encrypted_password.blank? || group_id.nil? || statistic_profile.birthday.blank? ||
      (Setting.get('phone_required') && profile.phone.blank?) ||
      (Setting.get('address_required') && invoicing_profile.address&.address&.blank?)
  end

  ## Retrieve the requested data in the User and user's Profile tables
  ## @param sso_mapping {String} must be of form 'user._field_' or 'profile._field_'. Eg. 'user.email'
  def get_data_from_sso_mapping(sso_mapping)
    parsed = /^(user|profile)\.(.+)$/.match(sso_mapping)
    if parsed[1] == 'user'
      self[parsed[2].to_sym]
    elsif parsed[1] == 'profile'
      case sso_mapping
      when 'profile.avatar'
        profile.user_avatar.remote_attachment_url
      when 'profile.address'
        invoicing_profile.address.address
      when 'profile.organization_name'
        invoicing_profile.organization.name
      when 'profile.organization_address'
        invoicing_profile.organization.address.address
      else
        profile[parsed[2].to_sym]
      end
    end
  end

  ## Set some data on the current user, according to the sso_key given
  ## @param sso_mapping {String} must be of form 'user._field_' or 'profile._field_'. Eg. 'user.email'
  ## @param data {*} the data to put in the given key. Eg. 'user@example.com'
  def set_data_from_sso_mapping(sso_mapping, data)
    if sso_mapping.to_s.start_with? 'user.'
      self[sso_mapping[5..-1].to_sym] = data unless data.nil?
    elsif sso_mapping.to_s.start_with? 'profile.'
      case sso_mapping.to_s
      when 'profile.avatar'
        profile.user_avatar ||= UserAvatar.new
        profile.user_avatar.remote_attachment_url = data
      when 'profile.address'
        invoicing_profile.address ||= Address.new
        invoicing_profile.address.address = data
      when 'profile.organization_name'
        invoicing_profile.organization ||= Organization.new
        invoicing_profile.organization.name = data
      when 'profile.organization_address'
        invoicing_profile.organization ||= Organization.new
        invoicing_profile.organization.address ||= Address.new
        invoicing_profile.organization.address.address = data
      else
        profile[sso_mapping[8..-1].to_sym] = data unless data.nil?
      end
    end
  end

  ## used to allow the migration of existing users between authentication providers
  def generate_auth_migration_token
    update_attributes(auth_token: Devise.friendly_token)
  end

  ## link the current user to the given provider (omniauth attributes hash)
  ## and remove the auth_token to mark his account as "migrated"
  def link_with_omniauth_provider(auth)
    active_provider = AuthProvider.active
    raise SecurityError, 'The identity provider does not match the activated one' if active_provider.strategy_name != auth.provider

    if User.where(provider: auth.provider, uid: auth.uid).size.positive?
      raise DuplicateIndexError, "This #{active_provider.name} account is already linked to an existing user"
    end

    update_attributes(provider: auth.provider, uid: auth.uid, auth_token: nil)
  end

  ## Merge the provided User's SSO details into the current user and drop the provided user to ensure the unity
  ## @param sso_user {User} the provided user will be DELETED after the merge was successful
  def merge_from_sso(sso_user)
    # update the attributes to link the account to the sso account
    self.provider = sso_user.provider
    self.uid = sso_user.uid

    # remove the token
    self.auth_token = nil
    self.merged_at = DateTime.current

    # check that the email duplication was resolved
    if sso_user.email.end_with? '-duplicate'
      email_addr = sso_user.email.match(/^<([^>]+)>.{20}-duplicate$/)[1]
      raise(DuplicateIndexError, email_addr) unless email_addr == email
    end

    # update the user's profile to set the data managed by the SSO
    auth_provider = AuthProvider.from_strategy_name(sso_user.provider)
    auth_provider.sso_fields.each do |field|
      value = sso_user.get_data_from_sso_mapping(field)
      # we do not merge the email field if its end with the special value '-duplicate' as this means
      # that the user is currently merging with the account that have the same email than the sso
      set_data_from_sso_mapping(field, value) unless field == 'user.email' && value.end_with?('-duplicate')
    end

    # run the account transfer in an SQL transaction to ensure data integrity
    User.transaction do
      # remove the temporary account
      sso_user.destroy
      # finally, save the new details
      save!
    end
  end

  def self.mapping
    # we protect some fields as they are designed to be managed by the system and must not be updated externally
    blacklist = %w[id encrypted_password reset_password_token reset_password_sent_at remember_created_at
                   sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip confirmation_token
                   confirmed_at confirmation_sent_at unconfirmed_email failed_attempts unlock_token locked_at created_at
                   updated_at slug provider auth_token merged_at]
    User.columns_hash
        .map { |k, v| [k, v.type.to_s] }
        .delete_if { |col| blacklist.include?(col[0]) }
  end

  # will update the statistic_profile after a group switch or a role update
  def update_statistic_profile
    raise NoProfileError if statistic_profile.nil? || statistic_profile.id.nil?

    statistic_profile.update_attributes(
      group_id: group_id,
      role_id: roles.first.id
    )
  end

  def organization?
    !invoicing_profile.organization.nil?
  end

  protected

  # remove projects drafts that are not linked to another user
  def remove_orphan_drafts
    orphans = my_projects
              .joins('LEFT JOIN project_users ON projects.id = project_users.project_id')
              .where('project_users.project_id IS NULL')
              .where(state: 'draft')
    orphans.map(&:destroy!)
  end

  def confirmation_required?
    Setting.get('confirmation_required') ? super : false
  end

  private

  def assign_default_role
    add_role(:member) if roles.blank?
  end

  def cached_has_role?(role)
    roles = Rails.cache.fetch(
      roles_for: { object_id: object_id },
      expires_in: 1.day,
      race_condition_ttl: 2.seconds
    ) { roles.map(&:name) }
    roles.include?(role.to_s)
  end

  def cgu_must_accept
    errors.add(:cgu, I18n.t('activerecord.errors.messages.empty')) if cgu == '0'
  end

  def create_stripe_customer
    StripeWorker.perform_async(:create_stripe_customer, id)
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def notify_admin_when_user_is_created
    if need_completion? && !provider.nil?
      NotificationCenter.call type: 'notify_admin_when_user_is_imported',
                              receiver: User.admins,
                              attached_object: self
    else
      NotificationCenter.call type: 'notify_admin_when_user_is_created',
                              receiver: User.admins_and_managers,
                              attached_object: self
    end
  end

  def notify_group_changed
    return unless changes[:group_id]&.first

    ex_group = Group.find(changes[:group_id].first)
    meta_data = { ex_group_name: ex_group.name }

    NotificationCenter.call type: :notify_admin_user_group_changed,
                            receiver: User.admins_and_managers,
                            attached_object: self,
                            meta_data: meta_data

    NotificationCenter.call type: :notify_user_user_group_changed,
                            receiver: self,
                            attached_object: self
  end

  def invoicing_data_was_modified?
    saved_change_to_email?
  end

  def statistic_data_was_modified?
    saved_change_to_group_id?
  end

  def init_dependencies
    if invoicing_profile.nil?
      ip = InvoicingProfile.create!(
        user: self,
        email: email,
        first_name: first_name,
        last_name: last_name
      )
    end
    if wallet.nil?
      ip ||= invoicing_profile
      Wallet.create!(
        invoicing_profile: ip
      )
    end
    if statistic_profile.nil?
      StatisticProfile.create!(
        user: self,
        group_id: group_id,
        role_id: roles.first.id
      )
    else
      update_statistic_profile
    end
  end

  def update_invoicing_profile
    raise NoProfileError if invoicing_profile.nil?

    invoicing_profile.update_attributes(
      email: email
    )
  end
end
