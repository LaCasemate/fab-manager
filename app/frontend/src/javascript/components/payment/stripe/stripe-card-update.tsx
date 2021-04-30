import React, { FormEvent } from 'react';
import { CardElement, useElements, useStripe } from '@stripe/react-stripe-js';
import { SetupIntent } from "@stripe/stripe-js";
import { PaymentConfirmation } from '../../../models/payment';
import { User } from '../../../models/user';
import StripeAPI from '../../../api/stripe';

interface StripeCardUpdateProps {
  onSubmit: () => void,
  onSuccess: (result: SetupIntent|PaymentConfirmation|any) => void,
  onError: (message: string) => void,
  customerId: number,
  operator: User,
  className?: string,
}

/**
 * A simple form component to collect and update the credit card details, for Stripe.
 *
 * The form validation button must be created elsewhere, using the attribute form="stripe-card".
 */
export const StripeCardUpdate: React.FC<StripeCardUpdateProps> = ({ onSubmit, onSuccess, onError, className, customerId, operator, children }) => {

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
        // we start by associating the payment method with the user
        const { client_secret } = await StripeAPI.setupIntent(customerId);
        const { error } = await stripe.confirmCardSetup(client_secret, {
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
          // then we update the default payment method
          const res = await StripeAPI.updateCard(customerId, paymentMethod.id);
          onSuccess(res);
        }
      } catch (err) {
        // catch api errors
        onError(err);
      }
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
    <form onSubmit={handleSubmit} id="stripe-card" className={className}>
      <CardElement options={cardOptions} />
      {children}
    </form>
  );
}
