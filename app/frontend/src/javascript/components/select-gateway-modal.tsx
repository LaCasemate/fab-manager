/**
 * This component allows an administrator to select and configure a payment gateway.
 * The configuration of a payment gateway is required to enable the online payments.
 */

import React, { BaseSyntheticEvent, useEffect, useState } from 'react';
import { react2angular } from 'react2angular';
import { useTranslation } from 'react-i18next';
import { StripeKeysForm } from './payment/stripe/stripe-keys-form';
import { PayZenKeysForm } from './payment/payzen/payzen-keys-form';
import { FabModal, ModalSize } from './base/fab-modal';
import { Loader } from './base/loader';
import { User } from '../models/user';
import { Gateway } from '../models/gateway';
import { SettingBulkResult, SettingName } from '../models/setting';
import { IApplication } from '../models/application';
import SettingAPI from '../api/setting';


declare var Application: IApplication;

interface SelectGatewayModalModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  currentUser: User,
  onError: (errors: Map<SettingName, SettingBulkResult>|any) => void,
  onSuccess: (results: Map<SettingName, SettingBulkResult>) => void,
}

// initial request to the API
const paymentGateway = SettingAPI.get(SettingName.PaymentGateway);

const SelectGatewayModal: React.FC<SelectGatewayModalModalProps> = ({ isOpen, toggleModal, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [preventConfirmGateway, setPreventConfirmGateway] = useState<boolean>(true);
  const [selectedGateway, setSelectedGateway] = useState<string>('');
  const [gatewayConfig, setGatewayConfig] = useState<Map<SettingName, string>>(new Map());

  useEffect(() => {
    const gateway = paymentGateway.read();
    setSelectedGateway(gateway.value);
  }, []);

  /**
   * Callback triggered when the user has filled and confirmed the settings of his gateway
   */
  const onGatewayConfirmed = () => {
    setPreventConfirmGateway(true);
    updateSettings();
    setPreventConfirmGateway(false);
  }

  /**
   * Save the gateway provided by the target input into the component state
   */
  const setGateway = (event: BaseSyntheticEvent) => {
    const gateway = event.target.value;
    setSelectedGateway(gateway);
  }

  /**
   * Check if any payment gateway was selected
   */
  const hasSelectedGateway = (): boolean => {
    return selectedGateway !== '';
  }

  /**
   * Callback triggered when the embedded form has validated all the stripe keys
   */
  const handleValidStripeKeys = (publicKey: string, secretKey: string): void => {
    setGatewayConfig((prev) => {
      const newMap = new Map(prev);
      newMap.set(SettingName.StripeSecretKey, secretKey);
      newMap.set(SettingName.StripePublicKey, publicKey);
      return newMap;
    });
    setPreventConfirmGateway(false);
  }

  /**
   * Callback triggered when the embedded for has validated all the PayZen keys
   */
  const handleValidPayZenKeys = (payZenKeys: Map<SettingName, string>): void => {
    setGatewayConfig(payZenKeys);
    setPreventConfirmGateway(false);
  }

  /**
   * Send the new gateway settings to the API to save them
   */
  const updateSettings = (): void => {
    const settings = new Map<SettingName, string>(gatewayConfig);
    settings.set(SettingName.PaymentGateway, selectedGateway);

    const api = new SettingAPI();
    api.bulkUpdate(settings).then(result => {
      if (Array.from(result.values()).filter(item => !item.status).length > 0) {
        onError(result);
      } else {
        onSuccess(result);
      }
    }, reason => {
      onError(reason);
    });
  }

  return (
    <FabModal title={t('app.admin.invoices.payment.gateway_modal.select_gateway_title')}
              isOpen={isOpen}
              toggleModal={toggleModal}
              width={ModalSize.medium}
              className="gateway-modal"
              confirmButton={t('app.admin.invoices.payment.gateway_modal.confirm_button')}
              onConfirm={onGatewayConfirmed}
              preventConfirm={preventConfirmGateway}>
      {!hasSelectedGateway() && <p className="info-gateway">
        {t('app.admin.invoices.payment.gateway_modal.gateway_info')}
      </p>}
      <label htmlFor="gateway">{t('app.admin.invoices.payment.gateway_modal.select_gateway')}</label>
      <select id="gateway" className="select-gateway" onChange={setGateway} value={selectedGateway}>
        <option />
        <option value={Gateway.Stripe}>{t('app.admin.invoices.payment.gateway_modal.stripe')}</option>
        <option value={Gateway.PayZen}>{t('app.admin.invoices.payment.gateway_modal.payzen')}</option>
      </select>
      {selectedGateway === Gateway.Stripe && <StripeKeysForm onValidKeys={handleValidStripeKeys} />}
      {selectedGateway === Gateway.PayZen && <PayZenKeysForm onValidKeys={handleValidPayZenKeys} />}
    </FabModal>
  );
};

const SelectGatewayModalWrapper: React.FC<SelectGatewayModalModalProps> = ({ isOpen, toggleModal, currentUser, onSuccess, onError }) => {
  return (
    <Loader>
      <SelectGatewayModal isOpen={isOpen} toggleModal={toggleModal} currentUser={currentUser} onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
}

Application.Components.component('selectGatewayModal', react2angular(SelectGatewayModalWrapper, ['isOpen', 'toggleModal', 'currentUser', 'onSuccess', 'onError']));
