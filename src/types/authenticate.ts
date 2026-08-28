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

export const AuthenticationOutcome = {
  /** A credential was offered and rejected. */
  Failed: 'E_AUTH_FAILED',
  /** Dismissed before any credential was evaluated. */
  Cancelled: 'E_CANCELLED',
  /** Could not be attempted; not a verdict about the user or the device. */
  Indeterminate: 'E_INDETERMINATE',
} as const;

export type AuthenticationOutcome =
  (typeof AuthenticationOutcome)[keyof typeof AuthenticationOutcome];

export class AuthenticationError extends Error {
  readonly outcome: AuthenticationOutcome;

  constructor(outcome: AuthenticationOutcome, message?: string) {
    super(message ?? outcome);
    this.name = 'AuthenticationError';
    this.outcome = outcome;
  }
}
