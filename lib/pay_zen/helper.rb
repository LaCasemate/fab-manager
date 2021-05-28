# frozen_string_literal: true

# PayZen payement gateway
module PayZen; end

## Provides various methods around the PayZen payment gateway
class PayZen::Helper
  class << self
    ## Is the PayZen gateway enabled?
    def enabled?
      return false unless Setting.get('online_payment_module')
      return false unless Setting.get('payment_gateway') == 'payzen'

      res = true
      %w[payzen_username payzen_password payzen_endpoint payzen_public_key payzen_hmac payzen_currency].each do |pz_setting|
        res = false unless Setting.get(pz_setting).present?
      end
      res
    end

    ## generate an unique string reference for the content of a cart
    def generate_ref(cart_items, customer)
      require 'sha3'

      content = { cart_items: cart_items, customer: customer }.to_json + DateTime.current.to_s
      # It's safe to truncate a hash. See https://crypto.stackexchange.com/questions/74646/sha3-255-one-bit-less
      SHA3::Digest.hexdigest(:sha224, content)[0...24]
    end

    ## Generate a hash map compatible with PayZen 'V4/Customer/Customer'
    def generate_customer(customer_id, operator_id, cart_items)
      customer = User.find(customer_id)
      operator = User.find(operator_id)

      address = if customer.organization?
                  customer.invoicing_profile.organization.address&.address
                else
                  customer.invoicing_profile.address&.address
                end

      {
        reference: customer.id,
        email: customer.invoicing_profile.email,
        billingDetails: {
          firstName: customer.invoicing_profile.first_name,
          lastName: customer.invoicing_profile.last_name,
          legalName: customer.organization? ? customer.invoicing_profile.organization.name : nil,
          address: address
        },
        shippingDetails: {
          category: customer.organization? ? 'COMPANY' : 'PRIVATE',
          shippingMethod: 'ETICKET'
        },
        shoppingCart: generate_shopping_cart(cart_items, customer, operator)
      }
    end

    ## Generate a hash map compatible with PayZen 'V4/Customer/ShoppingCart'
    def generate_shopping_cart(cart_items, customer, operator)
      cs = CartService.new(operator)
      cart = cs.from_hash(cart_items)
      {
        cartItemInfo: cart.items.map do |item|
          {
            productAmount: item.price[:amount].to_i.to_s,
            productLabel: item.name,
            productQty: 1.to_s,
            productType: customer.organization? ? 'SERVICE_FOR_BUSINESS' : 'SERVICE_FOR_INDIVIDUAL'
          }
        end
      }
    end

    ## Check the PayZen signature for integrity
    def check_hash(algorithm, hash_key, hash_proof, data, key = nil)
      supported_hash_algorithm = ['sha256_hmac']

      # check if the hash algorithm is supported
      raise ::PayzenError, "hash algorithm not supported: #{algorithm}. Update your SDK" unless supported_hash_algorithm.include? algorithm

      # if key is not defined, we use kr-hash-key parameter to choose it
      if key.nil?
        if hash_key == 'sha256_hmac'
          key = Setting.get('payzen_hmac')
        elsif hash_key == 'password'
          key = Setting.get('payzen_password')
        else
          raise ::PayzenError, 'invalid hash-key parameter'
        end
      end

      hash = OpenSSL::HMAC.hexdigest('SHA256', key, data)

      # return true if calculated hash and sent hash are the same
      hash == hash_proof
    end
  end
end
