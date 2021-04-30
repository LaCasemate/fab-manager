import React, { FormEvent, FunctionComponent, useEffect, useRef, useState } from 'react';
import KRGlue from "@lyracom/embedded-form-glue";
import { GatewayFormProps } from '../abstract-payment-modal';
import SettingAPI from '../../../api/setting';
import { SettingName } from '../../../models/setting';
import PayzenAPI from '../../../api/payzen';
import { Loader } from '../../base/loader';
import {
  CreateTokenResponse,
  KryptonClient,
  KryptonError,
  ProcessPaymentAnswer
} from '../../../models/payzen';

/**
 * A form component to collect the credit card details and to create the payment method on Stripe.
 * The form validation button must be created elsewhere, using the attribute form={formId}.
 */
export const PayzenForm: React.FC<GatewayFormProps> = ({ onSubmit, onSuccess, onError, children, className, paymentSchedule = false, cartItems, customer, operator, formId }) => {

  const PayZenKR = useRef<KryptonClient>(null);
  const [loadingClass, setLoadingClass] = useState<'hidden' | 'loader' | 'loader-overlay'>('loader');

  useEffect(() => {
    const api = new SettingAPI();
    api.query([SettingName.PayZenEndpoint, SettingName.PayZenPublicKey]).then(settings => {
      createToken().then(formToken => {
        // Load the remote library
        KRGlue.loadLibrary(settings.get(SettingName.PayZenEndpoint), settings.get(SettingName.PayZenPublicKey))
          .then(({ KR }) =>
            KR.setFormConfig({
              formToken: formToken.formToken,
            })
          )
          .then(({ KR }) => KR.addForm("#payzenPaymentForm"))
          .then(({ KR, result }) => KR.showForm(result.formId))
          .then(({ KR }) => KR.onFormReady(handleFormReady))
          .then(({ KR }) => KR.onFormCreated(handleFormCreated))
          .then(({ KR }) => PayZenKR.current = KR);
      }).catch(error => onError(error));
    });
  }, [cartItems, paymentSchedule, customer]);

  /**
   * Ask the API to create the form token.
   * Depending on the current transaction (schedule or not), a PayZen Token or Payment may be created.
   */
  const createToken = async (): Promise<CreateTokenResponse> => {
    if (paymentSchedule) {
      return await PayzenAPI.chargeCreateToken(cartItems, customer);
    } else {
      return await PayzenAPI.chargeCreatePayment(cartItems, customer);
    }
  }

  /**
   * Callback triggered on PayZen successful payments
   * @see https://docs.lyra.com/fr/rest/V4.0/javascript/features/reference.html#kronsubmit
   */
  const onPaid = (event: ProcessPaymentAnswer): boolean => {
    PayzenAPI.checkHash(event.hashAlgorithm, event.hashKey, event.hash, event.rawClientAnswer).then(async (hash) => {
      if (hash.validity) {
        const transaction = event.clientAnswer.transactions[0];

        if (event.clientAnswer.orderStatus === 'PAID') {
          PayzenAPI.confirm(event.clientAnswer.orderDetails.orderId, cartItems).then((confirmation) =>  {
            PayZenKR.current.removeForms().then(() => {
              onSuccess(confirmation);
            });
          })
        } else {
          const error = `${transaction?.errorMessage}. ${transaction?.detailedErrorMessage || ''}`;
          onError(error || event.clientAnswer.orderStatus);
        }
      }
    });
    return true;
  };

  /**
   * Callback triggered when the PayZen form was entirely loaded and displayed
   * @see https://docs.lyra.com/fr/rest/V4.0/javascript/features/reference.html#%C3%89v%C3%A9nements
   */
  const handleFormReady = () => {
    setLoadingClass('hidden');
  };

  /**
   * Callback triggered when the PayZen form has started to show up but is not entirely loaded
   * @see https://docs.lyra.com/fr/rest/V4.0/javascript/features/reference.html#%C3%89v%C3%A9nements
   */
  const handleFormCreated = () => {
    setLoadingClass('loader-overlay');
  }

  /**
   * Callback triggered when the PayZen payment was refused
   * @see https://docs.lyra.com/fr/rest/V4.0/javascript/features/reference.html#kronerror
   */
  const handleError = (answer: KryptonError) => {
    const message = `${answer.errorMessage}. ${answer.detailedErrorMessage ? answer.detailedErrorMessage : ''}`;
    onError(message);
  }

  /**
   * Handle the submission of the form.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    onSubmit();

    try {
      const { result } = await PayZenKR.current.validateForm();
      if (result === null) {
        await PayZenKR.current.onSubmit(onPaid);
        await PayZenKR.current.onError(handleError);
        await PayZenKR.current.submit();
      }
    } catch (err) {
      // catch api errors
      onError(err);
    }
  }

  const Loader: FunctionComponent = () => {
    return (
      <div className={`fa-3x ${loadingClass}`}>
        <i className="fas fa-circle-notch fa-spin" />
      </div>
    );
  };

  return (
    <form onSubmit={handleSubmit} id={formId} className={className ? className : ''}>
      <Loader />
      <div className="container">
        <div id="payzenPaymentForm" />
      </div>
      {children}
    </form>
  );
}
