import {
  DeviceEventEmitter,
  NativeModules,
  NativeEventEmitter,
  Platform,
} from 'react-native';
import type { EmitterSubscription } from 'react-native';

interface IEnterpriseMobilityManager {
  addListener(callback: ManagedConfigCallBack): EmitterSubscription;

  authenticate(opts: AuthenticateConfig): Promise<boolean>;

  deviceSecureWith(): Promise<AuthenticationMethods>;

  enableBlurScreen(enabled: boolean): void;

  exitApp(): void;

  getManagedConfig(): Promise<Record<string, any>>;

  isDeviceSecured(): Promise<boolean>;

  openSecuritySettings(): void;

  setAppGroupId(identifier: string): void;
}

const { Emm } = NativeModules;

const emitter =
  Platform.OS === 'ios' ? new NativeEventEmitter(Emm) : DeviceEventEmitter;
let cachedConfig: Record<string, any> = {};

export default {
  ...Emm,
  addListener: (callback: ManagedConfigCallBack) => {
    return emitter.addListener('managedConfigChanged', (config: any) => {
      cachedConfig = config;

      if (callback && typeof callback === 'function') {
        callback(config);
      }
    });
  },
  authenticate: async (opts: AuthenticateConfig) => {
    try {
      const options: AuthenticateConfig = {
        reason: opts.reason || '',
        description: opts.description || '',
        fallback: opts.fallback || true,
        supressEnterPassword: opts.supressEnterPassword || false,
      };

      await Emm.authenticate(options);

      return true;
    } catch {
      return false;
    }
  },
  getManagedConfig: async () => {
    if (Object.keys(cachedConfig).length > 0) {
      return cachedConfig;
    }

    const managed = await Emm.getManagedConfig();
    if (managed) {
      cachedConfig = managed;
    }

    return cachedConfig;
  },
  isDeviceSecured: async () => {
    try {
      const result: AuthenticationMethods = await Emm.deviceSecureWith();
      return result.face || result.fingerprint || result.passcode;
    } catch {
      return false;
    }
  },
  openSecuritySettings: () => {
    if (Platform.OS === 'android') {
      Emm.openSecuritySettings();
    }
  },
  setAppGroupId: (identifier: string) => {
    if (Platform.OS === 'ios') {
      Emm.setAppGroupId(identifier);
    }
  },
} as IEnterpriseMobilityManager;
