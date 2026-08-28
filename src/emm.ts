import {
  NativeEventEmitter,
  Platform,
} from 'react-native';

import {
  AuthenticationError,
  AuthenticationOutcome,
  type AuthenticateConfig,
  type AuthenticationMethods,
} from './types/authenticate';
import type {
  EnterpriseMobilityManager,
  ManagedConfigCallBack,
} from './types/managed';

import RNEmm from './emm-native';

const emitter = new NativeEventEmitter(RNEmm);

const OUTCOMES: readonly AuthenticationOutcome[] = [
  AuthenticationOutcome.Failed,
  AuthenticationOutcome.Cancelled,
  AuthenticationOutcome.Indeterminate,
];

// Unrecognised codes are indeterminate: we cannot claim the user failed.
const toAuthenticationError = (error: unknown) => {
  const code = (error as {code?: string} | undefined)?.code;
  const outcome = OUTCOMES.find((value) => value === code) ?? AuthenticationOutcome.Indeterminate;
  const message = (error as {message?: string} | undefined)?.message;

  return new AuthenticationError(outcome, message);
};

const Emm: EnterpriseMobilityManager = {
  addListener: <T>(callback: ManagedConfigCallBack<T>) => {
    return emitter.addListener('managedConfigChanged', (config: T) => {
      callback(config);
    });
  },
  authenticate: async (opts: AuthenticateConfig) => {
    const options: AuthenticateConfig = {
      reason: opts.reason || '',
      description: opts.description || '',
      fallback: opts.fallback ?? true,
      supressEnterPassword: opts.supressEnterPassword || false,
      blurOnAuthenticate: opts.blurOnAuthenticate || false,
    };

    try {
      await RNEmm.authenticate(options);
      return true;
    } catch (error) {
      throw toAuthenticationError(error);
    }
  },
  getManagedConfig: <T>() => RNEmm.getManagedConfig() as T,
  isDeviceSecured: async () => {
    try {
      const result: AuthenticationMethods = await RNEmm.deviceSecureWith();
      return result.face || result.fingerprint || result.passcode;
    } catch (error) {
      throw toAuthenticationError(error);
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
