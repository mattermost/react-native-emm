import type { EmitterSubscription } from 'react-native';
import type { AuthenticateConfig, AuthenticationMethods } from './authenticate';

export interface ManagedConfig {
  [key: string]: any;
}

export type ManagedConfigCallBack = {
  (config: ManagedConfig): void;
};

export interface EnterpriseMobilityManager {
  addListener(callback: ManagedConfigCallBack): EmitterSubscription;

  authenticate(opts: AuthenticateConfig): Promise<boolean>;

  deviceSecureWith(): Promise<AuthenticationMethods>;

  enableBlurScreen(enabled: boolean): void;

  exitApp(): void;

  getManagedConfig(): Promise<ManagedConfig>;

  isDeviceSecured(): Promise<boolean>;

  openSecuritySettings(): void;

  setAppGroupId(identifier: string): void;
}
