import React, { FunctionComponent, ReactNode, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import WalletLib from '../../lib/wallet';
import { WalletInfo } from '../wallet-info';
import { FabModal, ModalSize } from '../base/fab-modal';
import { HtmlTranslate } from '../base/html-translate';
import { CustomAssetName } from '../../models/custom-asset';
import { IFablab } from '../../models/fablab';
import { CartItems } from '../../models/payment';
import { PaymentSchedule } from '../../models/payment-schedule';
import { User } from '../../models/user';
import CustomAssetAPI from '../../api/custom-asset';
import PriceAPI from '../../api/price';
import WalletAPI from '../../api/wallet';

declare var Fablab: IFablab;


export interface GatewayFormProps {
  onSubmit: () => void,
  onSuccess: (result: any) => void,
  onError: (message: string) => void,
  customer: User,
  operator: User,
  className?: string,
  paymentSchedule?: boolean,
  cartItems?: CartItems,
  formId: string,
}

interface AbstractPaymentModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: any) => void,
  cartItems: CartItems,
  currentUser: User,
  schedule: PaymentSchedule,
  customer: User,
  logoFooter: ReactNode,
  GatewayForm: FunctionComponent<GatewayFormProps>,
  formId: string,
  className?: string,
  formClassName?: string,
}


// initial request to the API
const cgvFile = CustomAssetAPI.get(CustomAssetName.CgvFile);

/**
 * This component is an abstract modal that must be extended by each payment gateway to include its payment form.
 *
 * This component must not be called directly but must be extended for each implemented payment gateway
 * @see https://reactjs.org/docs/composition-vs-inheritance.html
 */
export const AbstractPaymentModal: React.FC<AbstractPaymentModalProps> = ({ isOpen, toggleModal, afterSuccess, cartItems, currentUser, schedule, customer, logoFooter, GatewayForm, formId, className, formClassName }) => {
  // customer's wallet
  const [wallet, setWallet] = useState(null);
  // server-computed price with all details
  const [price, setPrice] = useState(null);
  // remaining price = total price - wallet amount
  const [remainingPrice, setRemainingPrice] = useState(0);
  // is the component ready to display?
  const [ready, setReady] = useState(false);
  // errors to display in the UI (gateway errors mainly)
  const [errors, setErrors] = useState(null);
  // are we currently processing the payment (ie. the form was submit, but the process is still running)?
  const [submitState, setSubmitState] = useState(false);
  // did the user accepts the terms of services (CGV)?
  const [tos, setTos] = useState(false);

  const { t } = useTranslation('shared');
  const cgv = cgvFile.read();


  /**
   * On each display:
   * - Refresh the wallet
   * - Refresh the price
   * - Refresh the remaining price
   */
  useEffect(() => {
    if (!cartItems) return;
    WalletAPI.getByUser(cartItems.customer_id).then((wallet) => {
      setWallet(wallet);
      PriceAPI.compute(cartItems).then((res) => {
        setPrice(res);
        const wLib = new WalletLib(wallet);
        setRemainingPrice(wLib.computeRemainingPrice(res.price));
        setReady(true);
      })
    })
  }, [cartItems]);

  /**
   * Check if there is currently an error to display
   */
  const hasErrors = (): boolean => {
    return errors !== null;
  }

  /**
   * Check if the user accepts the Terms of Sales document
   */
  const hasCgv = (): boolean => {
    return cgv != null;
  }

  /**
   * Triggered when the user accepts or declines the Terms of Sales
   */
  const toggleTos = (): void => {
    setTos(!tos);
  }

  /**
   * Check if we are currently creating a payment schedule
   */
  const isPaymentSchedule = (): boolean => {
    return schedule !== undefined;
  }

  /**
   * Return the formatted localized amount for the given price (eg. 20.5 => "20,50 €")
   */
  const formatPrice = (amount: number): string => {
    return new Intl.NumberFormat(Fablab.intl_locale, {style: 'currency', currency: Fablab.intl_currency}).format(amount);
  }

  /**
   * Set the component as 'currently submitting'
   */
  const handleSubmit = (): void => {
    setSubmitState(true);
  }

  /**
   * After sending the form with success, process the resulting payment method
   */
  const handleFormSuccess = async (result: any): Promise<void> => {
    setSubmitState(false);
    afterSuccess(result);
  }

  /**
   * When the payment form raises an error, it is handled by this callback which display it in the modal.
   */
  const handleFormError = (message: string): void => {
    setSubmitState(false);
    setErrors(message);
  }

  /**
   * Check the form can be submitted.
   * => We're not currently already submitting the form, and, if the terms of service are enabled, the user must agree with them.
   */
  const canSubmit = (): boolean => {
    let terms = true;
    if (hasCgv()) { terms = tos; }
    return !submitState && terms;
  }


  return (
    <FabModal title={t('app.shared.payment.online_payment') }
              isOpen={isOpen}
              toggleModal={toggleModal}
              width={ModalSize.medium}
              closeButton={false}
              customFooter={logoFooter}
              className={`payment-modal ${className ? className : ''}`}>
      {ready && <div>
        <WalletInfo cartItems={cartItems} currentUser={currentUser} wallet={wallet} price={price?.price} />
        <GatewayForm onSubmit={handleSubmit}
                     onSuccess={handleFormSuccess}
                     onError={handleFormError}
                     operator={currentUser}
                     className={`gateway-form ${formClassName ? formClassName : ''}`}
                     formId={formId}
                     cartItems={cartItems}
                     customer={customer}
                     paymentSchedule={isPaymentSchedule()}>
          {hasErrors() && <div className="payment-errors">
            {errors}
          </div>}
          {isPaymentSchedule() && <div className="payment-schedule-info">
            <HtmlTranslate trKey="app.shared.payment.payment_schedule_html" options={{ DEADLINES: schedule.items.length }} />
          </div>}
          {hasCgv() && <div className="terms-of-sales">
            <input type="checkbox" id="acceptToS" name="acceptCondition" checked={tos} onChange={toggleTos} required />
            <label htmlFor="acceptToS">{ t('app.shared.payment.i_have_read_and_accept_') }
              <a href={cgv.custom_asset_file_attributes.attachment_url} target="_blank">
                { t('app.shared.payment._the_general_terms_and_conditions') }
              </a>
            </label>
          </div>}
        </GatewayForm>
        {!submitState && <button type="submit"
                                 disabled={!canSubmit()}
                                 form={formId}
                                 className="validate-btn">
          {t('app.shared.payment.confirm_payment_of_', { AMOUNT: formatPrice(remainingPrice) })}
        </button>}
        {submitState && <div className="payment-pending">
          <div className="fa-2x">
            <i className="fas fa-circle-notch fa-spin" />
          </div>
        </div>}
      </div>}
    </FabModal>
  );
}
