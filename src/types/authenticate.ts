export type AuthenticateConfig = {
  reason?: string;
  description?: string;
  fallback?: boolean;
  supressEnterPassword?: boolean;
  blurOnAuthenticate?: boolean;
};

export type AuthenticationMethods = {
  readonly face: boolean;
  readonly fingerprint: boolean;
  readonly passcode: boolean;
};
