import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import wrapPromise, { IWrapPromise } from '../lib/wrap-promise';
import { Wallet } from '../models/wallet';

export default class WalletAPI {
  static async getByUser (user_id: number): Promise<Wallet> {
    const res: AxiosResponse = await apiClient.get(`/api/wallet/by_user/${user_id}`);
    return res?.data;
  }
}

