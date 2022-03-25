import {
  DeviceEventEmitter,
  NativeModules,
  NativeEventEmitter,
  Platform,
} from 'react-native';

import type {
  AuthenticateConfig,
  AuthenticationMethods,
} from './types/authenticate';
import type {
  EnterpriseMobilityManager,
  ManagedConfigCallBack,
} from './types/managed';

const { Emm } = NativeModules;

const emitter =
  Platform.OS === 'ios' ? new NativeEventEmitter(Emm) : DeviceEventEmitter;

const EMM: EnterpriseMobilityManager = {
  ...Emm,
  addListener: <T>(callback: ManagedConfigCallBack<T>) => {
    return emitter.addListener('managedConfigChanged', (config: T) => {
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
  getManagedConfig: <T>() => Emm.getManagedConfig() as T,
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
};

export default EMM;
