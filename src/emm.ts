import {
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

import RNEmm from './emm-native';

const emitter = new NativeEventEmitter(RNEmm);

const Emm: EnterpriseMobilityManager = {
  addListener: <T>(callback: ManagedConfigCallBack<T>) => {
    return emitter.addListener('managedConfigChanged', (config: T) => {
      callback(config);
    });
  },
  authenticate: async (opts: AuthenticateConfig) => {
    try {
      const options: AuthenticateConfig = {
        reason: opts.reason || '',
        description: opts.description || '',
        fallback: opts.fallback || true,
        supressEnterPassword: opts.supressEnterPassword || false,
        blurOnAuthenticate: opts.blurOnAuthenticate || false,
      };

      await RNEmm.authenticate(options);

      return true;
    } catch {
      return false;
    }
  },
  getManagedConfig: <T>() => RNEmm.getManagedConfig() as T,
  isDeviceSecured: async () => {
    try {
      const result: AuthenticationMethods = await RNEmm.deviceSecureWith();
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
  deviceSecureWith: function (): Promise<AuthenticationMethods> {
    return RNEmm.deviceSecureWith();
  },
  enableBlurScreen: function (enabled: boolean): void {
    return RNEmm.setBlurScreen(enabled);
  },
  applyBlurEffect: (radius = 8) => RNEmm.applyBlurEffect(radius),
  removeBlurEffect: () => RNEmm.removeBlurEffect(),
  exitApp: function (): void {
    RNEmm.exitApp();
  }
};

export default Emm;
