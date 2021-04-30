import React, { useEffect, useState } from 'react';
import { react2angular } from 'react2angular';
import { useTranslation } from 'react-i18next';
import { useImmer } from 'use-immer';
import { FabInput } from '../../base/fab-input';
import { FabButton } from '../../base/fab-button';
import { Loader } from '../../base/loader';
import { HtmlTranslate } from '../../base/html-translate';
import { SettingName } from '../../../models/setting';
import { IApplication } from '../../../models/application';
import SettingAPI from '../../../api/setting';

declare var Application: IApplication;

interface PayzenSettingsProps {
  onEditKeys: (onlinePaymentModule: { value: boolean }) => void,
  onCurrencyUpdateSuccess: (currency: string) => void
}

// placeholder value for the hidden settings
const PAYZEN_HIDDEN = 'HiDdEnHIddEnHIdDEnHiDdEnHIddEnHIdDEn';

// settings related to PayZen that can be shown publicly
const payZenPublicSettings: Array<SettingName> = [SettingName.PayZenPublicKey, SettingName.PayZenEndpoint, SettingName.PayZenUsername];
// settings related to PayZen that must be kept on server-side
const payZenPrivateSettings: Array<SettingName> = [SettingName.PayZenPassword, SettingName.PayZenHmacKey];
// other settings related to PayZen
const payZenOtherSettings: Array<SettingName> = [SettingName.PayZenCurrency];
// all PayZen settings
const payZenSettings: Array<SettingName> = payZenPublicSettings.concat(payZenPrivateSettings).concat(payZenOtherSettings);

// icons for the inputs of each setting
const icons:Map<SettingName, string> = new Map([
  [SettingName.PayZenHmacKey, 'subscript'],
  [SettingName.PayZenPassword, 'key'],
  [SettingName.PayZenUsername, 'user'],
  [SettingName.PayZenEndpoint, 'link'],
  [SettingName.PayZenPublicKey, 'info']
])

/**
 * This component displays a summary of the PayZen account keys, with a button triggering the modal to edit them
 */
export const PayzenSettings: React.FC<PayzenSettingsProps> = ({ onEditKeys, onCurrencyUpdateSuccess }) => {
  const { t } = useTranslation('admin');

  // all the values of the settings related to PayZen
  const [settings, updateSettings] = useImmer<Map<SettingName, string>>(new Map(payZenSettings.map(name => [name, ''])));
  // store a possible error state for currency
  const [error, setError] = useState<string>('');

  /**
   * When the component is mounted, we initialize the values of the settings with those fetched from the API.
   * For the private settings, we initialize them with the placeholder value, if the setting is set.
   */
  useEffect(() => {
    const api = new SettingAPI();
    api.query(payZenPublicSettings.concat(payZenOtherSettings)).then(payZenKeys => {
      api.isPresent(SettingName.PayZenPassword).then(pzPassword => {
        api.isPresent(SettingName.PayZenHmacKey).then(pzHmac => {
          const map = new Map(payZenKeys);
          map.set(SettingName.PayZenPassword, pzPassword ? PAYZEN_HIDDEN :  '');
          map.set(SettingName.PayZenHmacKey, pzHmac ? PAYZEN_HIDDEN :  '');

          updateSettings(map);
        }).catch(error => { console.error(error); })
      }).catch(error => { console.error(error); });
    }).catch(error => { console.error(error); });
  }, []);


  /**
   * Callback triggered when the user clicks on the "update keys" button.
   * This will open the modal dialog allowing to change the keys
   */
  const handleKeysUpdate = (): void => {
    onEditKeys({ value: true });
  }

  /**
   * Callback triggered when the user changes the content of the currency input field.
   */
  const handleCurrencyUpdate = (value: string, validity?: ValidityState): void => {
    if (!validity || validity.valid) {
      setError('');
      updateSettings(draft => draft.set(SettingName.PayZenCurrency, value));
    } else {
      setError(t('app.admin.invoices.payment.payzen.currency_error'));
    }
  }

  /**
   * Callback triggered when the user clicks on the "save currency" button.
   * This will update the setting on the server.
   */
  const saveCurrency = (): void => {
    const api = new SettingAPI();
    api.update(SettingName.PayZenCurrency, settings.get(SettingName.PayZenCurrency)).then(result => {
      setError('');
      updateSettings(draft => draft.set(SettingName.PayZenCurrency, result.value));
      onCurrencyUpdateSuccess(result.value);
    }, reason => {
      setError(t('app.admin.invoices.payment.payzen.error_while_saving')+reason);
    })
  }

  return (
    <div className="payzen-settings">
      <h3 className="title">{t('app.admin.invoices.payment.payzen.payzen_keys')}</h3>
      <div className="payzen-keys">
        {payZenPublicSettings.concat(payZenPrivateSettings).map(setting => {
          return (
            <div className="key-wrapper" key={setting}>
              <label htmlFor={setting}>{t(`app.admin.invoices.payment.payzen.${setting}`)}</label>
              <FabInput defaultValue={settings.get(setting)}
                        id={setting}
                        type={payZenPrivateSettings.indexOf(setting) > -1 ? 'password' : 'text'}
                        icon={<i className={`fas fa-${icons.get(setting)}`} />}
                        readOnly
                        disabled />
            </div>
          );
        })}
        <div className="edit-keys">
          <FabButton className="edit-keys-btn" onClick={handleKeysUpdate}>{t('app.admin.invoices.payment.edit_keys')}</FabButton>
        </div>
      </div>
      <div className="payzen-currency">
        <h3 className="title">{t('app.admin.invoices.payment.payzen.currency')}</h3>
        <p className="currency-info">
          <HtmlTranslate trKey="app.admin.invoices.payment.payzen.currency_info_html" />
        </p>
        <div className="payzen-currency-form">
          <div className="currency-wrapper">
            <label htmlFor="payzen_currency">{t('app.admin.invoices.payment.payzen.payzen_currency')}</label>
            <FabInput defaultValue={settings.get(SettingName.PayZenCurrency)}
                      id="payzen_currency"
                      icon={<i className="fas fa-money-bill" />}
                      onChange={handleCurrencyUpdate}
                      maxLength={3}
                      pattern="[A-Z]{3}"
                      error={error} />
          </div>
          <FabButton className="save-currency" onClick={saveCurrency}>{t('app.admin.invoices.payment.payzen.save')}</FabButton>
        </div>
      </div>
    </div>
  );
}


const PayzenSettingsWrapper: React.FC<PayzenSettingsProps> = ({ onEditKeys, onCurrencyUpdateSuccess }) => {
  return (
    <Loader>
      <PayzenSettings onEditKeys={onEditKeys} onCurrencyUpdateSuccess={onCurrencyUpdateSuccess} />
    </Loader>
  );
}

Application.Components.component('payzenSettings', react2angular(PayzenSettingsWrapper, ['onEditKeys', 'onCurrencyUpdateSuccess']));
