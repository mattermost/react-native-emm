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
  ManagedConfig,
  ManagedConfigCallBack,
} from './types/managed';

const { Emm } = NativeModules;

const emitter =
  Platform.OS === 'ios' ? new NativeEventEmitter(Emm) : DeviceEventEmitter;
let cachedConfig: ManagedConfig = {};

const EMM: EnterpriseMobilityManager = {
  ...Emm,
  addListener: (callback: ManagedConfigCallBack) => {
    return emitter.addListener(
      'managedConfigChanged',
      (config: ManagedConfig) => {
        cachedConfig = config;

        if (callback && typeof callback === 'function') {
          callback(config);
        }
      }
    );
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

    const config = await Emm.getManagedConfig();
    if (config) {
      cachedConfig = config;
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
};

export default EMM;
