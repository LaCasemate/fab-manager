import axios, { AxiosInstance } from 'axios'

function client(key: string): AxiosInstance {
  return axios.create({
    baseURL: 'https://api.stripe.com/v1/',
    headers: {
      common: {
        Authorization: `Bearer ${key}`
      }
    }
  });
}

export default client;

