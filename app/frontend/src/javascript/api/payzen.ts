import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { CartItems } from '../models/payment';
import { User } from '../models/user';
import {
  CheckHashResponse,
  ConfirmPaymentResponse,
  CreatePaymentResponse,
  CreateTokenResponse,
  SdkTestResponse
} from '../models/payzen';

export default class PayzenAPI {

  static async chargeSDKTest(baseURL: string, username: string, password: string): Promise<SdkTestResponse> {
    const res: AxiosResponse<SdkTestResponse> = await apiClient.post('/api/payzen/sdk_test', { base_url: baseURL, username, password });
    return res?.data;
  }

  static async chargeCreatePayment(cartItems: CartItems, customer: User): Promise<CreatePaymentResponse> {
    const res: AxiosResponse<CreatePaymentResponse> = await apiClient.post('/api/payzen/create_payment', { cart_items: cartItems, customer_id: customer.id });
    return res?.data;
  }

  static async chargeCreateToken(cartItems: CartItems, customer: User): Promise<CreateTokenResponse> {
    const res: AxiosResponse = await  apiClient.post('/api/payzen/create_token', { cart_items: cartItems, customer_id: customer.id });
    return res?.data;
  }

  static async checkHash(algorithm: string, hashKey: string, hash: string, data: string): Promise<CheckHashResponse> {
    const res: AxiosResponse<CheckHashResponse> = await apiClient.post('/api/payzen/check_hash', { algorithm, hash_key: hashKey, hash, data });
    return res?.data;
  }

  static async confirm(orderId: string, cartItems: CartItems): Promise<ConfirmPaymentResponse> {
    const res: AxiosResponse<ConfirmPaymentResponse> = await apiClient.post('/api/payzen/confirm_payment', { cart_items: cartItems, order_id: orderId });
    return res?.data;
  }
}
