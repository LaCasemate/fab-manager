import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { CartItems } from '../models/payment';
import { ComputePriceResult } from '../models/price';

export default class PriceAPI {
  static async compute (cartItems: CartItems): Promise<ComputePriceResult> {
    const res: AxiosResponse = await apiClient.post(`/api/prices/compute`, cartItems);
    return res?.data;
  }
}

