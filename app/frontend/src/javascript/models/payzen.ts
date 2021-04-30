export interface SdkTestResponse {
  success: boolean
}

export interface CreateTokenResponse {
  formToken: string
  orderId: string
}

export interface CreatePaymentResponse extends CreateTokenResponse {}

export interface ConfirmPaymentResponse {
  todo?: any
}

export interface CheckHashResponse {
  validity: boolean
}

export interface OrderDetails {
  mode?: 'TEST' | 'PRODUCTION',
  orderCurrency?: string,
  orderEffectiveAmount?: number,
  orderId?: string,
  orderTotalAmount?: number,
  _type: 'V4/OrderDetails'
}

export interface Customer {
  email?: string,
  reference?: string,
  billingDetails?: {
    address?: string,
    address2?: string,
    category?: 'PRIVATE' | 'COMPANY',
    cellPhoneNumber?: string,
    city?: string
    country?: string,
    district?: string,
    firstName?: string,
    identityCode?: string,
    language?: 'DE' | 'EN' | 'ZH' | 'ES' | 'FR' | 'IT' | 'JP' | 'NL' | 'PL' | 'PT' | 'RU',
    lastName?: string,
    phoneNumber?: string,
    state?: string,
    streetNumber?: string,
    title?: string,
    zipCode?: string,
    _type: 'V4/Customer/BillingDetails'
  },
  shippingDetails: {
    address?: string,
    address2?: string,
    category?: 'PRIVATE' | 'COMPANY',
    city?: string
    country?: string,
    deliveryCompanyName?: string,
    district?: string,
    firstName?: string,
    identityCode?: string,
    lastName?: string,
    legalName?: string,
    phoneNumber?: string,
    shippingMethod?: 'RECLAIM_IN_SHOP' | 'RELAY_POINT' | 'RECLAIM_IN_STATION' | 'PACKAGE_DELIVERY_COMPANY' | 'ETICKET',
    shippingSpeed?: 'STANDARD' | 'EXPRESS' | 'PRIORITY',
    state?: string,
    streetNumber?: string,
    zipCode?: string,
    _type: 'V4/Customer/ShippingDetails'
  },
  shoppingCart: {
    insuranceAmount?: number,
    shippingAmount?: number,
    taxAmount?: number
    cartItemInfo: Array<{
      productAmount?: string,
      productLabel?: string
      productQty?: number,
      productRef?: string,
      productType?: 'FOOD_AND_GROCERY' | 'AUTOMOTIVE' | 'ENTERTAINMENT' | 'HOME_AND_GARDEN' | 'HOME_APPLIANCE' | 'AUCTION_AND_GROUP_BUYING' | 'FLOWERS_AND_GIFTS' | 'COMPUTER_AND_SOFTWARE' | 'HEALTH_AND_BEAUTY' | 'SERVICE_FOR_INDIVIDUAL' | 'SERVICE_FOR_BUSINESS' | 'SPORTS' | 'CLOTHING_AND_ACCESSORIES' | 'TRAVEL' | 'HOME_AUDIO_PHOTO_VIDEO' | 'TELEPHONY',
      productVat?: number,
    }>,
    _type: 'V4/Customer/ShoppingCart'
  }
  _type: 'V4/Customer/Customer'
}

export interface PaymentTransaction {
  amount?: number,
  creationDate?: string,
  currency?: string,
  detailedErrorCode? : string,
  detailedErrorMessage?: string,
  detailedStatus?: 'ACCEPTED' | 'AUTHORISED' | 'AUTHORISED_TO_VALIDATE' | 'CANCELLED' | 'CAPTURED' | 'EXPIRED' | 'PARTIALLY_AUTHORISED' | 'REFUSED' | 'UNDER_VERIFICATION' | 'WAITING_AUTHORISATION' | 'WAITING_AUTHORISATION_TO_VALIDATE' | 'ERROR',
  effectiveStrongAuthentication?: 'ENABLED' | 'DISABLED' ,
  errorCode?: string,
  errorMessage?: string,
  metadata?: any,
  operationType?: 'DEBIT' | 'CREDIT' | 'VERIFICATION',
  orderDetails?: OrderDetails,
  paymentMethodToken?: string,
  paymentMethodType?: 'CARD',
  shopId?: string,
  status?: 'PAID' | 'UNPAID' | 'RUNNING' | 'PARTIALLY_PAID',
  transactionDetails?: {
    creationContext?: 'CHARGE' | 'REFUND',
    effectiveAmount?: number,
    effectiveCurrency?: string,
    liabilityShift?: 'YES' | 'NO',
    mid?: string,
    parentTransactionUuid?: string,
    sequenceNumber?: string,
    cardDetails?: any,
    fraudManagement?: any,
    taxAmount?: number,
    taxRate?: number,
    preTaxAmount?: number,
    externalTransactionId?: number,
    dcc?: any,
    nsu?: string,
    tid?: string,
    acquirerNetwork?: string,
    taxRefundAmount?: number,
    occurrenceType?: string
  },
  uuid?: string,
  _type: 'V4/PaymentTransaction'
}

export interface Payment {
  customer: Customer,
  orderCycle: 'OPEN' | 'CLOSED',
  orderDetails: OrderDetails,
  orderStatus: 'PAID' | 'UNPAID' | 'RUNNING' | 'PARTIALLY_PAID',
  serverDate: string,
  shopId: string,
  transactions: Array<PaymentTransaction>,
  _type: 'V4/Payment'
}

export interface ProcessPaymentAnswer {
  clientAnswer: Payment,
  hash: string,
  hashAlgorithm: string,
  hashKey: string,
  rawClientAnswer: string
  _type: 'V4/Charge/ProcessPaymentAnswer'
}

export interface KryptonError {
  children: Array<KryptonError>,
  detailedErrorCode: string,
  detailedErrorMessage: string,
  errorCode: string,
  errorMessage: string,
  field: any,
  formId: string,
  metadata: {
    answer: ProcessPaymentAnswer,
    formToken: string
  },
  _errorKey: string,
  _type: 'krypton/error'
}

export interface KryptonFocus {
  field: string,
  formId: string,
  _type: 'krypton/focus'
}

export interface KryptonConfig {
  formToken?: string,
  'kr-public-key'?: string,
  'kr-language'?: string,
  'kr-post-url-success'?: string,
  'kr-get-url-success'?: string,
  'kr-post-url-refused'?: string,
  'kr-get-url-refused'?: string,
  'kr-clear-on-error'?: boolean,
  'kr-hide-debug-toolbar'?: boolean,
  'kr-spa-mode'?: boolean
}

type DefaultCallback = () => void
type BrandChangedCallback = (event: {KR: KryptonClient, cardInfo: {brand: string}}) => void
type ErrorCallback = (event: KryptonError) => void
type FocusCallback = (event: KryptonFocus) => void
type InstallmentChangedCallback = (event: {KR: KryptonClient, installmentInfo: {brand: string, hasInterests: boolean, installmentCount: number, totalAmount: number}}) => void
type SubmitCallback = (event: ProcessPaymentAnswer) => boolean
type ClickCallback = (event: any) => boolean

export interface KryptonClient {
  addForm: (selector: string) => Promise<{KR: KryptonClient, result: {formId: string}}>,
  showForm: (formId: string) => Promise<{KR: KryptonClient}>,
  hideForm: (formId: string) => Promise<{KR: KryptonClient}>,
  removeForms: () => Promise<{KR: KryptonClient}>,
  attachForm: (selector: string) => Promise<{KR: KryptonClient}>,
  onBrandChanged: (callback: BrandChangedCallback) => Promise<{KR: KryptonClient}>,
  onError: (callback: ErrorCallback) => Promise<{KR: KryptonClient}>,
  onFocus: (callback: FocusCallback) => Promise<{KR: KryptonClient}>,
  onInstallmentChanged: (callback: InstallmentChangedCallback) => Promise<{KR: KryptonClient}>
  onFormReady: (callback: DefaultCallback) => Promise<{KR: KryptonClient}>,
  onFormCreated: (callback: DefaultCallback) => Promise<{KR: KryptonClient}>,
  onSubmit: (callback: SubmitCallback) => Promise<{KR: KryptonClient}>,
  button: {
    onClick: (callback: ClickCallback | Promise<boolean>) => Promise<{KR: KryptonClient}>
  },
  openPopin: () => Promise<{KR: KryptonClient}>,
  closePopin: () => Promise<{KR: KryptonClient}>,
  fields: {
    focus: (selector: string) => Promise<{KR: KryptonClient}>,
  },
  setFormConfig: (config: KryptonConfig) => Promise<{KR: KryptonClient}>,
  setShopName: (name: string) => Promise<{KR: KryptonClient}>,
  setFormToken: (formToken: string) => Promise<{KR: KryptonClient}>,
  validateForm: () => Promise<{KR: KryptonClient, result?: KryptonError}>,
  submit: () => Promise<{KR: KryptonClient}>,
}
