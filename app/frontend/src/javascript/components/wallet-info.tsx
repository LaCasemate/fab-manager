import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { IApplication } from '../models/application';
import '../lib/i18n';
import { Loader } from './base/loader';
import { User } from '../models/user';
import { Wallet } from '../models/wallet';
import { IFablab } from '../models/fablab';
import WalletLib from '../lib/wallet';
import { CartItems } from '../models/payment';
import { Reservation } from '../models/reservation';
import { SubscriptionRequest } from '../models/subscription';

declare var Application: IApplication;
declare var Fablab: IFablab;

interface WalletInfoProps {
  cartItems: CartItems,
  currentUser: User,
  wallet: Wallet,
  price: number,
}

/**
 * This component displays a summary of the amount paid with the virtual wallet, for the current transaction
 */
export const WalletInfo: React.FC<WalletInfoProps> = ({ cartItems, currentUser, wallet, price }) => {
  const { t } = useTranslation('shared');
  const [remainingPrice, setRemainingPrice] = useState(0);

  /**
   * Refresh the remaining price on each display
   */
  useEffect(() => {
    const wLib = new WalletLib(wallet);
    setRemainingPrice(wLib.computeRemainingPrice(price));
  });

  /**
   * Return the formatted localized amount for the given price (e.g. 20.5 => "20,50 €")
   */
  const formatPrice = (price: number): string => {
    return new Intl.NumberFormat(Fablab.intl_locale, {style: 'currency', currency: Fablab.intl_currency}).format(price);
  }
  /**
   * Check if the currently connected used is also the person making the reservation.
   * If the currently connected user (i.e. the operator), is an admin or a manager, he may book the reservation for someone else.
   */
  const isOperatorAndClient = (): boolean => {
    return currentUser.id == cartItems.customer_id;
  }
  /**
   * If the client has some money in his wallet & the price is not zero, then we should display this component.
   */
  const shouldBeShown = (): boolean => {
    return wallet.amount > 0 && price > 0;
  }
  /**
   * If the amount in the wallet is not enough to cover the whole price, then the user must pay the remaining price
   * using another payment mean.
   */
  const hasRemainingPrice = (): boolean => {
    return remainingPrice > 0;
  }
  /**
   * Does the current cart contains a payment schedule?
   */
  const isPaymentSchedule = (): boolean => {
    return cartItems.subscription && cartItems.payment_schedule;
  }
  /**
   * Return the human-readable name of the item currently bought with the wallet
   */
  const getPriceItem = (): string => {
    let item = 'other';
    if (cartItems.reservation) {
      item = 'reservation';
    } else if (cartItems.subscription) {
      if (cartItems.payment_schedule) {
        item = 'first_deadline';
      } else item = 'subscription';
    }

    return t(`app.shared.wallet.wallet_info.item_${item}`);
  }

  return (
    <div className="wallet-info">
      {shouldBeShown() && <div>
        {isOperatorAndClient() && <div>
          <h3>{t('app.shared.wallet.wallet_info.you_have_AMOUNT_in_wallet', {AMOUNT: formatPrice(wallet.amount)})}</h3>
          {!hasRemainingPrice() && <p>
            {t('app.shared.wallet.wallet_info.wallet_pay_ITEM', {ITEM: getPriceItem()})}
          </p>}
          {hasRemainingPrice() && <p>
            {t('app.shared.wallet.wallet_info.credit_AMOUNT_for_pay_ITEM', {
              AMOUNT: formatPrice(remainingPrice),
              ITEM: getPriceItem()
            })}
          </p>}
        </div>}
        {!isOperatorAndClient() && <div>
          <h3>{t('app.shared.wallet.wallet_info.client_have_AMOUNT_in_wallet', {AMOUNT: formatPrice(wallet.amount)})}</h3>
          {!hasRemainingPrice() && <p>
            {t('app.shared.wallet.wallet_info.client_wallet_pay_ITEM', {ITEM: getPriceItem()})}
          </p>}
          {hasRemainingPrice() && <p>
            {t('app.shared.wallet.wallet_info.client_credit_AMOUNT_for_pay_ITEM', {
              AMOUNT: formatPrice(remainingPrice),
              ITEM: getPriceItem()
            })}
          </p>}
        </div>}
        {!hasRemainingPrice() && isPaymentSchedule() && <p className="info-deadlines">
          <i className="fa fa-warning"/>
          <span>{t('app.shared.wallet.wallet_info.other_deadlines_no_wallet')}</span>
        </p>}
      </div>}
    </div>
  );
}

const WalletInfoWrapper: React.FC<WalletInfoProps> = ({ currentUser, cartItems, price, wallet }) => {
  return (
    <Loader>
      <WalletInfo currentUser={currentUser} cartItems={cartItems} price={price} wallet={wallet}/>
    </Loader>
  );
}

Application.Components.component('walletInfo', react2angular(WalletInfoWrapper, ['currentUser', 'price', 'cartItems', 'wallet']));
