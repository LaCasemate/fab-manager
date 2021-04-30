import React, { useEffect, useState } from 'react';
import { useStripe } from '@stripe/react-stripe-js';
import { useTranslation } from 'react-i18next';

interface StripeConfirmProps {
  clientSecret: string,
  onResponse: () => void,
}

/**
 * This component runs a 3D secure confirmation for the given Stripe payment (identified by clientSecret).
 * A message is shown, depending on the result of the confirmation.
 * In case of success, a callback "onResponse" is also run.
 */
export const StripeConfirm: React.FC<StripeConfirmProps> = ({ clientSecret, onResponse }) => {
  const stripe = useStripe();
  const { t } = useTranslation('shared');

  // the message displayed to the user
  const [message, setMessage] = useState<string>(t('app.shared.stripe_confirm.pending'));
  // the style class of the message
  const [type, setType] = useState<string>('info');

  /**
   * When the component is mounted, run the 3DS confirmation.
   */
  useEffect(() => {
    stripe.confirmCardPayment(clientSecret).then(function(result) {
      onResponse();
      if (result.error) {
        // Display error.message in your UI.
        setType('error');
        setMessage(result.error.message);
      } else {
        // The setup has succeeded. Display a success message.
        setType('success');
        setMessage(t('app.shared.stripe_confirm.success'));
      }
    });
  }, []);

  return <div className="stripe-confirm">
    <div className={`message--${type}`}><span className="message-text">{message}</span></div>
  </div>;
}
