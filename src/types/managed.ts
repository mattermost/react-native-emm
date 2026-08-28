import type { EmitterSubscription } from 'react-native';
import type { AuthenticateConfig, AuthenticationMethods } from './authenticate';

export type ManagedConfigCallBack<T> = {
  (config: T): void;
};

export interface EnterpriseMobilityManager {
  addListener<T>(callback: ManagedConfigCallBack<T>): EmitterSubscription;

  /** Rejects with {@link AuthenticationError} carrying the outcome. */
  authenticate(opts: AuthenticateConfig): Promise<boolean>;

  deviceSecureWith(): Promise<AuthenticationMethods>;

  enableBlurScreen(enabled: boolean): void;

  applyBlurEffect: (radius: number) => void;

  removeBlurEffect: () => void;

  exitApp(): void;

  getManagedConfig<T>(): T;

  /** Rejects with {@link AuthenticationError} when the check cannot be performed. */
  isDeviceSecured(): Promise<boolean>;

  openSecuritySettings(): void;

  setAppGroupId(identifier: string): void;
}
