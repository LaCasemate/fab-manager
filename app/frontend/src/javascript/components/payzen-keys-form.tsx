/**
 * Form to set the PayZen's username, password and public key
 */

import React, { ReactNode, useEffect, useState } from 'react';
import { Loader } from './loader';
import { useTranslation } from 'react-i18next';
import SettingAPI from '../api/setting';
import { SettingName } from '../models/setting';
import { FabInput } from './fab-input';


interface PayZenKeysFormProps {
  onValidKeys: (payZenSettings: Map<SettingName, string>) => void
}

const payZenSettings = [SettingName.PayZenUsername, SettingName.PayZenPassword, SettingName.PayZenEndpoint, SettingName.PayZenHmacKey, SettingName.PayZenPublicKey];
const payZenKeys = SettingAPI.query(payZenSettings);

const PayZenKeysFormComponent: React.FC<PayZenKeysFormProps> = ({ onValidKeys }) => {
  const { t } = useTranslation('admin');

  const defaultSettings: [SettingName, string][] = payZenSettings.map(name => [name, '']);
  const [settings, setSettings] = useState<Map<SettingName, string>>(new Map(defaultSettings));
  const [restApiAddOn, setRestApiAddOn] = useState<ReactNode>(null);
  const [restApiAddOnClassName, setRestApiAddOnClassName] = useState<string>('');
  const [publicKeyAddOn, setPublicKeyAddOn] = useState<ReactNode>(null);
  const [publicKeyAddOnClassName, setPublicKeyAddOnClassName] = useState<string>('');

  useEffect(() => {
    setSettings(payZenKeys.read());
  }, []);

  useEffect(() => {
    const validClassName = 'key-valid';
    if (publicKeyAddOnClassName === validClassName && restApiAddOnClassName === validClassName) {
      onValidKeys(settings);
    }
  }, [publicKeyAddOnClassName, restApiAddOnClassName]);


  /**
   * Check if the inputted public key is valid and assign it to the settings if the key is valid
   */
  const testPublicKey = (key: string) => {
    if (!key.match(/^[0-9]+:/)) {
      setPublicKeyAddOn(<i className="fa fa-times" />);
      setPublicKeyAddOnClassName('key-invalid');
      return;
    }
    setSettings(new Map(settings).set(SettingName.PayZenPublicKey, key));
    setPublicKeyAddOn(<i className="fa fa-check" />);
    setPublicKeyAddOnClassName('key-valid');
  }

  /**
   * Send a test call to the payZen REST API to check if the inputted settings key are valid
   */
  const testRestApi = (setting: SettingName.PayZenUsername | SettingName.PayZenPassword | SettingName.PayZenEndpoint | SettingName.PayZenHmacKey) => {
    return (key: string) => {
      // if (!key.match(/^sk_/)) {
      setRestApiAddOn(<i className="fa fa-times" />);
      setRestApiAddOnClassName('key-invalid');
      return;
      // }
      // StripeAPI.listAllCharges(key).then(() => {
      //   setSecretKey(key);
      //   setSecretKeyAddOn(<i className="fa fa-check" />);
      //   setSecretKeyAddOnClassName('key-valid');
      // }, reason => {
      //   if (reason.response.status === 401) {
      //     setSecretKeyAddOn(<i className="fa fa-times" />);
      //     setSecretKeyAddOnClassName('key-invalid');
      //   }
      // });
    };
  }

  /**
   * Check if an add-on icon must be shown for the API settings
   */
  const hasApiAddOn = () => {
    return restApiAddOn !== null;
  }

  return (
    <div className="payzen-keys-form">
      <div className="payzen-keys-info" dangerouslySetInnerHTML={{__html: t('app.admin.invoices.payment.payzen_keys_info_html')}} />
      <form name="payzenKeysForm">
        <fieldset>
          <legend>{t('app.admin.invoices.payment.client_keys')}</legend>
          <div className="payzen-public-input">
            <label htmlFor="payzen_public_key">{ t('app.admin.invoices.payment.public_key') } *</label>
            <FabInput id="payzen_public_key"
                      icon={<i className="fas fa-info" />}
                      value={settings.get(SettingName.PayZenPublicKey)}
                      onChange={testPublicKey}
                      addOn={publicKeyAddOn}
                      addOnClassName={publicKeyAddOnClassName}
                      debounce={200}
                      required />
          </div>
        </fieldset>
        <fieldset>
          <legend className={hasApiAddOn() ? 'with-addon' : ''}>
            <span>{t('app.admin.invoices.payment.api_keys')}</span>
            {hasApiAddOn() && <span className={`fieldset-legend--addon ${restApiAddOnClassName ?  restApiAddOnClassName : ''}`}>{restApiAddOn}</span>}
          </legend>
          <div className="payzen-api-user-input">
            <label htmlFor="payzen_username">{ t('app.admin.invoices.payment.username') } *</label>
            <FabInput id="payzen_username"
                      type="number"
                      icon={<i className="fas fa-user-alt" />}
                      value={settings.get(SettingName.PayZenUsername)}
                      onChange={testRestApi(SettingName.PayZenUsername)}
                      debounce={200}
                      required />
          </div>
          <div className="payzen-api-password-input">
            <label htmlFor="payzen_password">{ t('app.admin.invoices.payment.password') } *</label>
            <FabInput id="payzen_password"
                      icon={<i className="fas fa-key" />}
                      value={settings.get(SettingName.PayZenPassword)}
                      onChange={testRestApi(SettingName.PayZenPassword)}
                      debounce={200}
                      required />
          </div>
          <div className="payzen-api-endpoint-input">
            <label htmlFor="payzen_endpoint">{ t('app.admin.invoices.payment.endpoint') } *</label>
            <FabInput id="payzen_endpoint"
                      type="url"
                      icon={<i className="fas fa-anchor" />}
                      value={settings.get(SettingName.PayZenEndpoint)}
                      onChange={testRestApi(SettingName.PayZenEndpoint)}
                      debounce={200}
                      required />
          </div>
          <div className="payzen-api-hmac-input">
            <label htmlFor="payzen_hmac">{ t('app.admin.invoices.payment.hmac') } *</label>
            <FabInput id="payzen_hmac"
                      icon={<i className="fas fa-subscript" />}
                      value={settings.get(SettingName.PayZenHmacKey)}
                      onChange={testRestApi(SettingName.PayZenHmacKey)}
                      debounce={200}
                      required />
          </div>
        </fieldset>
      </form>
    </div>
  );
}

export const PayZenKeysForm: React.FC<PayZenKeysFormProps> = ({ onValidKeys }) => {
  return (
    <Loader>
      <PayZenKeysFormComponent onValidKeys={onValidKeys} />
    </Loader>
  );
}
