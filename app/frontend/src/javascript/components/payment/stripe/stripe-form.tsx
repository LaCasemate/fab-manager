import React, { FormEvent } from 'react';
import { CardElement, useElements, useStripe } from '@stripe/react-stripe-js';
import { SetupIntent } from "@stripe/stripe-js";
import { useTranslation } from 'react-i18next';
import { GatewayFormProps } from '../abstract-payment-modal';
import { PaymentConfirmation } from '../../../models/payment';
import StripeAPI from '../../../api/stripe';

interface StripeFormProps extends GatewayFormProps {
  onSuccess: (result: SetupIntent|PaymentConfirmation) => void,
}

/**
 * A form component to collect the credit card details and to create the payment method on Stripe.
 * The form validation button must be created elsewhere, using the attribute form={formId}.
 */
export const StripeForm: React.FC<StripeFormProps> = ({ onSubmit, onSuccess, onError, children, className, paymentSchedule = false, cartItems, customer, operator, formId }) => {

  const { t } = useTranslation('shared');

  const stripe = useStripe();
  const elements = useElements();

  /**
   * Handle the submission of the form. Depending on the configuration, it will create the payment method on Stripe,
   * or it will process a payment with the inputted card.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    onSubmit();

    // Stripe.js has not loaded yet
    if (!stripe || !elements) { return; }

    const cardElement = elements.getElement(CardElement);
    const { error, paymentMethod } = await stripe.createPaymentMethod({
      type: 'card',
      card: cardElement,
    });

    if (error) {
      // stripe error
      onError(error.message);
    } else {
      try {
        if (!paymentSchedule) {
          // process the normal payment pipeline, including SCA validation
          const res = await StripeAPI.confirm(paymentMethod.id, cartItems);
          await handleServerConfirmation(res);
        } else {
          // we start by associating the payment method with the user
          const { client_secret } = await StripeAPI.setupIntent(customer.id);
          const { setupIntent, error } = await stripe.confirmCardSetup(client_secret, {
            payment_method: paymentMethod.id,
            mandate_data: {
              customer_acceptance: {
                type: 'online',
                online: {
                  ip_address: operator.ip_address,
                  user_agent: navigator.userAgent
                }
              }
            }
          })
          if (error) {
            onError(error.message);
          } else {
            // then we confirm the payment schedule
            const res = await StripeAPI.confirmPaymentSchedule(setupIntent.id, cartItems);
            onSuccess(res);
          }
        }
      } catch (err) {
        // catch api errors
        onError(err);
      }
    }
  }

  /**
   * Process the server response about the Strong-customer authentication (SCA)
   * @param response can be a PaymentConfirmation, or a Reservation (if the reservation succeeded), or a Subscription (if the subscription succeeded)
   * @see app/controllers/api/payments_controller.rb#on_reservation_success
   * @see app/controllers/api/payments_controller.rb#on_subscription_success
   * @see app/controllers/api/payments_controller.rb#generate_payment_response
   */
  const handleServerConfirmation = async (response: PaymentConfirmation|any) => {
    if (response.error) {
      if (response.error.statusText) {
        onError(response.error.statusText);
      } else {
        onError(`${t('app.shared.messages.payment_card_error')} ${response.error}`);
      }
    } else if (response.requires_action) {
      // Use Stripe.js to handle required card action
      const result = await stripe.handleCardAction(response.payment_intent_client_secret);
      if (result.error) {
        onError(result.error.message);
      } else {
        // The card action has been handled
        // The PaymentIntent can be confirmed again on the server
        try {
          const confirmation = await StripeAPI.confirm(result.paymentIntent.id, cartItems);
          await handleServerConfirmation(confirmation);
        } catch (e) {
          onError(e);
        }
      }
    } else {
      onSuccess(response);
    }
  }


  /**
   * Options for the Stripe's card input
   */
  const cardOptions = {
    style: {
      base: {
        fontSize: '16px',
        color: '#424770',
        '::placeholder': { color: '#aab7c4' }
      },
      invalid: {
        color: '#9e2146',
        iconColor: '#9e2146'
      },
    },
    hidePostalCode: true
  };

  return (
    <form onSubmit={handleSubmit} id={formId} className={className ? className : ''}>
      <CardElement options={cardOptions} />
      {children}
    </form>
  );
}
