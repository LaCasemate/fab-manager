import stripeClient from '../clients/stripe-client';
import { AxiosResponse } from 'axios';

export default class StripeAPI {
  /**
   * @see https://stripe.com/docs/api/tokens/create_pii
   */
  static async createPIIToken(key: string, piiId: string): Promise<any> {
    const params = new URLSearchParams();
    params.append('pii[id_number]', piiId);

    const config = {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    }

    const res: AxiosResponse = await stripeClient(key).post('tokens', params, config);
    return res?.data;
  }

  /**
   * @see https://stripe.com/docs/api/charges/list
   */
  static async listAllCharges(key: string): Promise<any> {
    const res: AxiosResponse = await stripeClient(key).get('charges');
    return res?.data;
  }
}
