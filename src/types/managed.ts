import type { EmitterSubscription } from 'react-native';
import type { AuthenticateConfig, AuthenticationMethods } from './authenticate';

export type ManagedConfigCallBack<T> = {
  (config: T): void;
};

export interface EnterpriseMobilityManager {
  addListener<T>(callback: ManagedConfigCallBack<T>): EmitterSubscription;

  authenticate(opts: AuthenticateConfig): Promise<boolean>;

  deviceSecureWith(): Promise<AuthenticationMethods>;

  enableBlurScreen(enabled: boolean): void;

  applyBlurEffect: (radius: number) => void;

  removeBlurEffect: () => void;

  exitApp(): void;

  getManagedConfig<T>(): T;

  isDeviceSecured(): Promise<boolean>;

  openSecuritySettings(): void;

  setAppGroupId(identifier: string): void;
}
