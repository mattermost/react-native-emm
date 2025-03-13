import {type TurboModule, TurboModuleRegistry} from 'react-native';
import type { Float, UnsafeObject } from 'react-native/Libraries/Types/CodegenTypes';

type AuthenticateConfig = {
  reason?: string;
  description?: string;
  fallback?: boolean;
  supressEnterPassword?: boolean;
  blurOnAuthenticate?: boolean;
};

type AuthenticationMethods = {
  readonly face: boolean;
  readonly fingerprint: boolean;
  readonly passcode: boolean;
};

export interface Spec extends TurboModule {
    readonly getConstants:() => {};

    addListener: (eventType: string) => void;
    removeListeners: (count: number) => void;

    authenticate(options: AuthenticateConfig): Promise<boolean>;
    deviceSecureWith: () => Promise<AuthenticationMethods>;
    exitApp: () => void;
    getManagedConfig: () => UnsafeObject;
    openSecuritySettings: () => void;
    setAppGroupId: (identifier: string) => void;
    setBlurScreen: (enabled: boolean) => void;
    applyBlurEffect: (radius: Float) => void;
    removeBlurEffect: () => void;
};

export default TurboModuleRegistry.get<Spec>('Emm');
