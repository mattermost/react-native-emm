import {
  DeviceEventEmitter,
  EmitterSubscription,
  NativeModules,
  NativeEventEmitter,
  Platform,
} from 'react-native';

export type AuthenticateProps = {
  reason?: string;
  description?: string;
  fallback?: boolean;
  supressEnterPassword?: boolean;
};

export type SecurityType = {
  face: boolean;
  fingerprint: boolean;
  passcode: boolean;
};

type EventCallBack = (config: any) => void;

type RNEmmType = {
  addListener(callback: EventCallBack): EmitterSubscription;

  authenticate(opts: AuthenticateProps): Promise<boolean>;

  deviceSecureWith(): Promise<SecurityType>;

  enableBlurScreen(enabled: boolean): void;

  exitApp(): void;

  getManagedConfig(): Promise<any>;

  isDeviceSecured(): Promise<boolean>;

  openSecuritySettings(): void;

  setAppGroupId(identifier: string): void;
};

const { RNEmm } = NativeModules;

const emitter =
  Platform.OS === 'ios' ? new NativeEventEmitter(RNEmm) : DeviceEventEmitter;
let cachedConfig: any = {};

export default {
  ...RNEmm,
  addListener: (callback: EventCallBack) => {
    return emitter.addListener('managedConfigChanged', (config: any) => {
      cachedConfig = config;

      if (callback && typeof callback === 'function') {
        callback(config);
      }
    });
  },
  authenticate: async (opts: AuthenticateProps) => {
    try {
      const options: AuthenticateProps = {
        reason: opts.reason || '',
        description: opts.description || '',
        fallback: opts.fallback || true,
        supressEnterPassword: opts.supressEnterPassword || false,
      };

      await RNEmm.authenticate(options);

      return true;
    } catch {
      return false;
    }
  },
  getManagedConfig: async () => {
    if (Object.keys(cachedConfig).length > 0) {
      return cachedConfig;
    }

    cachedConfig = await RNEmm.getManagedConfig();

    return cachedConfig;
  },
  isDeviceSecured: async () => {
    try {
      const result: SecurityType = await RNEmm.deviceSecureWith();
      return result.face || result.fingerprint || result.passcode;
    } catch {
      return false;
    }
  },
  openSecuritySettings: () => {
    if (Platform.OS === 'android') {
      RNEmm.openSecuritySettings();
    }
  },
  setAppGroupId: (identifier: string) => {
    if (Platform.OS === 'ios') {
      RNEmm.setAppGroupId(identifier);
    }
  },
} as RNEmmType;
