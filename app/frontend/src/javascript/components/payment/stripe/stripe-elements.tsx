import React, { memo, useEffect, useState } from 'react';
import { Elements } from '@stripe/react-stripe-js';
import { loadStripe } from "@stripe/stripe-js";
import { SettingName } from '../../../models/setting';
import SettingAPI from '../../../api/setting';

// initial request to the API
const stripePublicKey = SettingAPI.get(SettingName.StripePublicKey);

/**
 * This component initializes the stripe's Elements tag with the API key
 */
export const StripeElements: React.FC = memo(({ children }) => {
  const [stripe, setStripe] = useState(undefined);

  /**
   * When this component is mounted, we initialize the <Elements> tag with the Stripe's public key
   */
  useEffect(() => {
    const key = stripePublicKey.read();
    const promise = loadStripe(key.value);
    setStripe(promise);
  }, [])

  return (
    <div>
      {stripe && <Elements stripe={stripe}>
        {children}
      </Elements>}
    </div>
  );
})
