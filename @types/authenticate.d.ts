interface AuthenticateConfig {
  reason?: string;
  description?: string;
  fallback?: boolean;
  supressEnterPassword?: boolean;
}

interface AuthenticationMethods {
  readonly face: boolean;
  readonly fingerprint: boolean;
  readonly passcode: boolean;
}
