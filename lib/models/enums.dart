/// Shared enumerations used across models and features.
library;

/// Type of account / verification subject.
enum UserType {
  individual,
  business;

  String get label => this == UserType.individual ? 'Individual' : 'Business';

  static UserType fromString(String? value) =>
      value == 'business' ? UserType.business : UserType.individual;
}

/// Overall status of a verification record.
enum VerificationStatus {
  pending,
  inProgress,
  completed,
  failed;

  static VerificationStatus fromString(String? value) =>
      VerificationStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => VerificationStatus.pending,
      );
}

/// Individual check outcome.
enum CheckResult {
  pass,
  fail,
  notApplicable;

  static CheckResult fromString(String? value) => CheckResult.values.firstWhere(
        (e) => e.name == value,
        orElse: () => CheckResult.notApplicable,
      );
}

/// Payment lifecycle status.
enum PaymentStatus {
  created,
  authorized,
  captured,
  failed,
  refunded;

  static PaymentStatus fromString(String? value) =>
      PaymentStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaymentStatus.created,
      );
}

/// Subscription tiers for business accounts.
enum SubscriptionTier {
  free,
  starter,
  professional,
  enterprise;

  String get label => switch (this) {
        SubscriptionTier.free => 'Free',
        SubscriptionTier.starter => 'Starter',
        SubscriptionTier.professional => 'Professional',
        SubscriptionTier.enterprise => 'Enterprise',
      };

  static SubscriptionTier fromString(String? value) =>
      SubscriptionTier.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SubscriptionTier.free,
      );
}
