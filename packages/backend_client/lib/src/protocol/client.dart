/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:backend_client/src/protocol/otp_challenge_response.dart' as _i3;
import 'package:backend_client/src/protocol/login_response.dart' as _i4;
import 'package:backend_client/src/protocol/user_list_item.dart' as _i5;
import 'package:backend_client/src/protocol/roster_data.dart' as _i6;
import 'package:backend_client/src/protocol/roster_lists.dart' as _i7;
import 'package:backend_client/src/protocol/admin_profile.dart' as _i8;
import 'package:backend_client/src/protocol/audit_entry.dart' as _i9;
import 'package:backend_client/src/protocol/InventoryCategory.dart' as _i10;
import 'package:backend_client/src/protocol/InventoryItemInfo.dart' as _i11;
import 'package:backend_client/src/protocol/inventory_transaction.dart' as _i12;
import 'package:backend_client/src/protocol/inventory_audit_log.dart' as _i13;
import 'package:backend_client/src/protocol/admin_dashboard_overview.dart'
    as _i14;
import 'package:backend_client/src/protocol/dashboard_analytics.dart' as _i15;
import 'package:backend_client/src/protocol/report_top_medicine.dart' as _i16;
import 'package:backend_client/src/protocol/report_medicine_stock_range.dart'
    as _i17;
import 'package:backend_client/src/protocol/report_lab_test_range.dart' as _i18;
import 'dart:typed_data' as _i19;
import 'package:backend_client/src/protocol/notification.dart' as _i20;
import 'package:backend_client/src/protocol/dispenser_profile_r.dart' as _i21;
import 'package:backend_client/src/protocol/prescription.dart' as _i22;
import 'package:backend_client/src/protocol/prescription_detail.dart' as _i23;
import 'package:backend_client/src/protocol/dispense_request.dart' as _i24;
import 'package:backend_client/src/protocol/dispense_history_entry.dart'
    as _i25;
import 'package:backend_client/src/protocol/doctor_home_data.dart' as _i26;
import 'package:backend_client/src/protocol/doctor_profile.dart' as _i27;
import 'package:backend_client/src/protocol/PrescribedItem.dart' as _i28;
import 'package:backend_client/src/protocol/patient_external_report.dart'
    as _i29;
import 'package:backend_client/src/protocol/patient_record_list.dart' as _i30;
import 'package:backend_client/src/protocol/patient_record_prescription_details.dart'
    as _i31;
import 'package:backend_client/src/protocol/patient_return_tests.dart' as _i32;
import 'package:backend_client/src/protocol/test_result_create_upload.dart'
    as _i33;
import 'package:backend_client/src/protocol/staff_profile.dart' as _i34;
import 'package:backend_client/src/protocol/lab_today.dart' as _i35;
import 'package:backend_client/src/protocol/lab_ten_history.dart' as _i36;
import 'package:backend_client/src/protocol/patient_reponse.dart' as _i37;
import 'package:backend_client/src/protocol/patient_report.dart' as _i38;
import 'package:backend_client/src/protocol/prescription_list.dart' as _i39;
import 'package:backend_client/src/protocol/StaffInfo.dart' as _i40;
import 'package:backend_client/src/protocol/ambulance_contact.dart' as _i41;
import 'package:backend_client/src/protocol/onduty_staff.dart' as _i42;
import 'package:backend_client/src/protocol/greeting.dart' as _i43;
import 'protocol.dart' as _i44;

/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Sends an OTP to [newEmail] for verifying profile email change.
  /// Requires an authenticated user.
  _i2.Future<_i3.OtpChallengeResponse> requestProfileEmailChangeOtp(
    String newEmail,
  ) => caller.callServerEndpoint<_i3.OtpChallengeResponse>(
    'auth',
    'requestProfileEmailChangeOtp',
    {'newEmail': newEmail},
  );

  /// Verify OTP for profile email change (does not update DB).
  _i2.Future<bool> verifyProfileEmailChangeOtp(
    String newEmail,
    String otp,
    String otpToken,
  ) => caller.callServerEndpoint<bool>(
    'auth',
    'verifyProfileEmailChangeOtp',
    {
      'newEmail': newEmail,
      'otp': otp,
      'otpToken': otpToken,
    },
  );

  /// Update the authenticated user's email, requiring OTP proof.
  /// Also marks `email_otp_verified = TRUE` because the new email was verified.
  _i2.Future<String> updateMyEmailWithOtp(
    String newEmail,
    String otp,
    String otpToken,
  ) => caller.callServerEndpoint<String>(
    'auth',
    'updateMyEmailWithOtp',
    {
      'newEmail': newEmail,
      'otp': otp,
      'otpToken': otpToken,
    },
  );

  _i2.Future<_i4.LoginResponse> login(
    String email,
    String password, {
    String? deviceId,
  }) => caller.callServerEndpoint<_i4.LoginResponse>(
    'auth',
    'login',
    {
      'email': email,
      'password': password,
      'deviceId': deviceId,
    },
  );

  /// Signup requirement redesign: only phone verification (OTP) during signup.
  /// No email OTP is required here.
  /// Since no SMS API, OTP is returned as debugOtp for UI popup.
  _i2.Future<_i3.OtpChallengeResponse> startSignupPhoneOtp(
    String email,
    String phone,
  ) => caller.callServerEndpoint<_i3.OtpChallengeResponse>(
    'auth',
    'startSignupPhoneOtp',
    {
      'email': email,
      'phone': phone,
    },
  );

  /// Verify login OTP after password was correct but user required OTP.
  /// Returns a normal LoginResponse containing the session token.
  _i2.Future<_i4.LoginResponse> verifyLoginOtp(
    String email,
    String otp,
    String otpToken, {
    String? deviceId,
  }) => caller.callServerEndpoint<_i4.LoginResponse>(
    'auth',
    'verifyLoginOtp',
    {
      'email': email,
      'otp': otp,
      'otpToken': otpToken,
      'deviceId': deviceId,
    },
  );

  /// Logout: client should delete its auth token.
  ///
  /// Note: we intentionally do not store per-session token revocation state.
  /// This keeps the DB minimal as requested (only tracks `email_otp_verified`).
  _i2.Future<bool> logout() => caller.callServerEndpoint<bool>(
    'auth',
    'logout',
    {},
  );

  _i2.Future<String> register(
    String email,
    String password,
    String name,
    String role,
  ) => caller.callServerEndpoint<String>(
    'auth',
    'register',
    {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    },
  );

  _i2.Future<String> resendOtp(
    String email,
    String password,
    String name,
    String role,
  ) => caller.callServerEndpoint<String>(
    'auth',
    'resendOtp',
    {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    },
  );

  /// After signup email OTP verified, start phone verification.
  /// Since no SMS API, OTP is returned as debugOtp for UI popup.
  _i2.Future<_i3.OtpChallengeResponse> verifySignupEmailAndStartPhoneOtp(
    String email,
    String emailOtp,
    String emailOtpToken,
    String phone,
  ) => caller.callServerEndpoint<_i3.OtpChallengeResponse>(
    'auth',
    'verifySignupEmailAndStartPhoneOtp',
    {
      'email': email,
      'emailOtp': emailOtp,
      'emailOtpToken': emailOtpToken,
      'phone': phone,
    },
  );

  /// Finalize signup by verifying phone OTP, then creating the user.
  /// Returns LoginResponse with session token (auto-login after signup).
  _i2.Future<_i4.LoginResponse> completeSignupWithPhoneOtp(
    String email,
    String phone,
    String phoneOtp,
    String phoneOtpToken,
    String password,
    String name,
    String role,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? gender,
  ) => caller.callServerEndpoint<_i4.LoginResponse>(
    'auth',
    'completeSignupWithPhoneOtp',
    {
      'email': email,
      'phone': phone,
      'phoneOtp': phoneOtp,
      'phoneOtpToken': phoneOtpToken,
      'password': password,
      'name': name,
      'role': role,
      'bloodGroup': bloodGroup,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    },
  );

  /// Public helper: send a welcome email using Resend API. Returns true on success.
  _i2.Future<bool> sendWelcomeEmailViaResend(
    String email,
    String name,
  ) => caller.callServerEndpoint<bool>(
    'auth',
    'sendWelcomeEmailViaResend',
    {
      'email': email,
      'name': name,
    },
  );

  _i2.Future<String> verifyOtp(
    String email,
    String otp,
    String token,
    String password,
    String name,
    String role,
    String? phone,
    String? bloodGroup,
    String? allergies,
  ) => caller.callServerEndpoint<String>(
    'auth',
    'verifyOtp',
    {
      'email': email,
      'otp': otp,
      'token': token,
      'password': password,
      'name': name,
      'role': role,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
    },
  );

  /// Request a password reset: generate OTP and JWT token (expires in 2 minutes)
  /// Returns the token if email was sent successfully, otherwise an error message.
  _i2.Future<String> requestPasswordReset(String email) =>
      caller.callServerEndpoint<String>(
        'auth',
        'requestPasswordReset',
        {'email': email},
      );

  /// Verify password reset OTP using the client-provided token.
  /// Returns 'OK' on success or an error message on failure.
  _i2.Future<String> verifyPasswordReset(
    String email,
    String otp,
    String token,
  ) => caller.callServerEndpoint<String>(
    'auth',
    'verifyPasswordReset',
    {
      'email': email,
      'otp': otp,
      'token': token,
    },
  );

  /// Reset the user's password. Token must be a valid JWT created by requestPasswordReset.
  _i2.Future<String> resetPassword(
    String email,
    String token,
    String newPassword,
  ) => caller.callServerEndpoint<String>(
    'auth',
    'resetPassword',
    {
      'email': email,
      'token': token,
      'newPassword': newPassword,
    },
  );

  /// Universal: all roles can change password with the same rules.
  /// Identifies user by email (same as your login uses email).
  _i2.Future<String> changePasswordUniversal(
    String email,
    String currentPassword,
    String newPassword,
  ) => caller.callServerEndpoint<String>(
    'auth',
    'changePasswordUniversal',
    {
      'email': email,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    },
  );
}

/// AdminEndpoints: server-side methods used by the admin UI to manage users,
/// inventory, rosters, audit logs and notifications.
/// {@category Endpoint}
class EndpointAdminEndpoints extends _i1.EndpointRef {
  EndpointAdminEndpoints(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminEndpoints';

  /// List users filtered by role. Use role = 'ALL' to fetch all users.
  _i2.Future<List<_i5.UserListItem>> listUsersByRole(
    String role,
    int limit,
  ) => caller.callServerEndpoint<List<_i5.UserListItem>>(
    'adminEndpoints',
    'listUsersByRole',
    {
      'role': role,
      'limit': limit,
    },
  );

  /// Toggle user's active flag. Returns true on success.
  _i2.Future<bool> toggleUserActive(String userId) =>
      caller.callServerEndpoint<bool>(
        'adminEndpoints',
        'toggleUserActive',
        {'userId': userId},
      );

  /// Normalize and validate a phone number. Accepts various input forms and
  /// returns normalized form like '+88XXXXXXXXXXX' where X... is 11 digits.
  /// Returns null if invalid.
  /// Create a new user record. Expects passwordHash to already be hashed by the caller.
  _i2.Future<String> createUser(
    String name,
    String email,
    String passwordHash,
    String role,
    String? phone,
  ) => caller.callServerEndpoint<String>(
    'adminEndpoints',
    'createUser',
    {
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'role': role,
      'phone': phone,
    },
  );

  /// Create user by hashing the provided raw password server-side.
  _i2.Future<String> createUserWithPassword(
    String name,
    String email,
    String password,
    String role,
    String? phone,
  ) => caller.callServerEndpoint<String>(
    'adminEndpoints',
    'createUserWithPassword',
    {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
    },
  );

  _i2.Future<List<_i6.Roster>> getRosters(
    String? staffId,
    DateTime? fromDate,
    DateTime? toDate, {
    required bool includeDeleted,
  }) => caller.callServerEndpoint<List<_i6.Roster>>(
    'adminEndpoints',
    'getRosters',
    {
      'staffId': staffId,
      'fromDate': fromDate,
      'toDate': toDate,
      'includeDeleted': includeDeleted,
    },
  );

  _i2.Future<bool> deleteRoster(int rosterId) =>
      caller.callServerEndpoint<bool>(
        'adminEndpoints',
        'deleteRoster',
        {'rosterId': rosterId},
      );

  _i2.Future<bool> saveRoster(
    String rosterId,
    String staffId,
    String shiftType,
    DateTime shiftDate,
    String timeRange,
    String status,
    String? approvedBy,
  ) => caller.callServerEndpoint<bool>(
    'adminEndpoints',
    'saveRoster',
    {
      'rosterId': rosterId,
      'staffId': staffId,
      'shiftType': shiftType,
      'shiftDate': shiftDate,
      'timeRange': timeRange,
      'status': status,
      'approvedBy': approvedBy,
    },
  );

  _i2.Future<List<_i7.Rosterlists>> listStaff(int limit) =>
      caller.callServerEndpoint<List<_i7.Rosterlists>>(
        'adminEndpoints',
        'listStaff',
        {'limit': limit},
      );

  /// Get admin profile (name, email, phone, profilePictureUrl) by email (userId)
  _i2.Future<_i8.AdminProfileRespond?> getAdminProfile(String userId) =>
      caller.callServerEndpoint<_i8.AdminProfileRespond?>(
        'adminEndpoints',
        'getAdminProfile',
        {'userId': userId},
      );

  /// Update admin profile: name, phone, optional profilePictureData.
  /// Accepts:
  /// - null: no change to picture
  /// - an http(s) URL: stored as-is
  _i2.Future<String> updateAdminProfile(
    String userId,
    String name,
    String phone,
    String? profilePictureData,
    String? designation,
    String? qualification,
  ) => caller.callServerEndpoint<String>(
    'adminEndpoints',
    'updateAdminProfile',
    {
      'userId': userId,
      'name': name,
      'phone': phone,
      'profilePictureData': profilePictureData,
      'designation': designation,
      'qualification': qualification,
    },
  );

  /// Change password for given user (identified by email/userId). Verifies current password before updating.
  _i2.Future<String> changePassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) => caller.callServerEndpoint<String>(
    'adminEndpoints',
    'changePassword',
    {
      'userId': userId,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    },
  );

  _i2.Future<void> createAuditLog({
    required int adminId,
    required String action,
    String? targetId,
  }) => caller.callServerEndpoint<void>(
    'adminEndpoints',
    'createAuditLog',
    {
      'adminId': adminId,
      'action': action,
      'targetId': targetId,
    },
  );

  _i2.Future<List<_i9.AuditEntry>> getAuditLogs() =>
      caller.callServerEndpoint<List<_i9.AuditEntry>>(
        'adminEndpoints',
        'getAuditLogs',
        {},
      );

  /// Fetch recent audit logs within the last [hours] hours.
  /// Used by Admin Dashboard Recent Activity (last 24h).
  _i2.Future<List<_i9.AuditEntry>> getRecentAuditLogs(
    int hours,
    int limit,
  ) => caller.callServerEndpoint<List<_i9.AuditEntry>>(
    'adminEndpoints',
    'getRecentAuditLogs',
    {
      'hours': hours,
      'limit': limit,
    },
  );

  _i2.Future<bool> addAmbulanceContact(
    String title,
    String phoneBn,
    String phoneEn,
    bool isPrimary,
  ) => caller.callServerEndpoint<bool>(
    'adminEndpoints',
    'addAmbulanceContact',
    {
      'title': title,
      'phoneBn': phoneBn,
      'phoneEn': phoneEn,
      'isPrimary': isPrimary,
    },
  );

  _i2.Future<bool> updateAmbulanceContact(
    int id,
    String title,
    String phoneBn,
    String phoneEn,
    bool isPrimary,
  ) => caller.callServerEndpoint<bool>(
    'adminEndpoints',
    'updateAmbulanceContact',
    {
      'id': id,
      'title': title,
      'phoneBn': phoneBn,
      'phoneEn': phoneEn,
      'isPrimary': isPrimary,
    },
  );
}

/// {@category Endpoint}
class EndpointAdminInventoryEndpoints extends _i1.EndpointRef {
  EndpointAdminInventoryEndpoints(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminInventoryEndpoints';

  _i2.Future<bool> addInventoryCategory(
    String name,
    String? description,
  ) => caller.callServerEndpoint<bool>(
    'adminInventoryEndpoints',
    'addInventoryCategory',
    {
      'name': name,
      'description': description,
    },
  );

  _i2.Future<List<_i10.InventoryCategory>> listInventoryCategories() =>
      caller.callServerEndpoint<List<_i10.InventoryCategory>>(
        'adminInventoryEndpoints',
        'listInventoryCategories',
        {},
      );

  _i2.Future<bool> addInventoryItem({
    required int categoryId,
    required String itemName,
    required String unit,
    required int minimumStock,
    required int initialStock,
    required bool canRestockDispenser,
  }) => caller.callServerEndpoint<bool>(
    'adminInventoryEndpoints',
    'addInventoryItem',
    {
      'categoryId': categoryId,
      'itemName': itemName,
      'unit': unit,
      'minimumStock': minimumStock,
      'initialStock': initialStock,
      'canRestockDispenser': canRestockDispenser,
    },
  );

  _i2.Future<bool> updateInventoryStock({
    required int itemId,
    required int quantity,
    required String type,
  }) => caller.callServerEndpoint<bool>(
    'adminInventoryEndpoints',
    'updateInventoryStock',
    {
      'itemId': itemId,
      'quantity': quantity,
      'type': type,
    },
  );

  _i2.Future<bool> updateDispenserRestockFlag({
    required int itemId,
    required bool canRestock,
  }) => caller.callServerEndpoint<bool>(
    'adminInventoryEndpoints',
    'updateDispenserRestockFlag',
    {
      'itemId': itemId,
      'canRestock': canRestock,
    },
  );

  _i2.Future<List<_i11.InventoryItemInfo>> listInventoryItems() =>
      caller.callServerEndpoint<List<_i11.InventoryItemInfo>>(
        'adminInventoryEndpoints',
        'listInventoryItems',
        {},
      );

  _i2.Future<bool> updateMinimumThreshold({
    required int itemId,
    required int newThreshold,
  }) => caller.callServerEndpoint<bool>(
    'adminInventoryEndpoints',
    'updateMinimumThreshold',
    {
      'itemId': itemId,
      'newThreshold': newThreshold,
    },
  );

  _i2.Future<List<_i12.InventoryTransactionInfo>> getItemTransactions(
    int itemId,
  ) => caller.callServerEndpoint<List<_i12.InventoryTransactionInfo>>(
    'adminInventoryEndpoints',
    'getItemTransactions',
    {'itemId': itemId},
  );

  _i2.Future<List<_i13.InventoryAuditLog>> getInventoryAuditLogs(
    int limit,
    int offset,
  ) => caller.callServerEndpoint<List<_i13.InventoryAuditLog>>(
    'adminInventoryEndpoints',
    'getInventoryAuditLogs',
    {
      'limit': limit,
      'offset': offset,
    },
  );
}

/// {@category Endpoint}
class EndpointAdminReportEndpoints extends _i1.EndpointRef {
  EndpointAdminReportEndpoints(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminReportEndpoints';

  _i2.Future<_i14.AdminDashboardOverview> getAdminDashboardOverview() =>
      caller.callServerEndpoint<_i14.AdminDashboardOverview>(
        'adminReportEndpoints',
        'getAdminDashboardOverview',
        {},
      );

  _i2.Future<_i15.DashboardAnalytics> getDashboardAnalytics() =>
      caller.callServerEndpoint<_i15.DashboardAnalytics>(
        'adminReportEndpoints',
        'getDashboardAnalytics',
        {},
      );

  /// Medicine usage report within a dispensed date range.
  ///
  /// Expected semantics: [from] is inclusive, [to] is exclusive (recommended).
  _i2.Future<List<_i16.TopMedicine>> getMedicineUsageByDateRange(
    DateTime from,
    DateTime to,
  ) => caller.callServerEndpoint<List<_i16.TopMedicine>>(
    'adminReportEndpoints',
    'getMedicineUsageByDateRange',
    {
      'from': from,
      'to': to,
    },
  );

  /// Medicine usage + stock snapshot report within a date range.
  ///
  /// Semantics: [from] is inclusive start (usually 00:00), [toExclusive] is
  /// exclusive end (usually next-day 00:00).
  ///
  /// Returns rows per medicine used in the range with:
  /// - fromQuantity: last known stock at or before [from]
  /// - used: total dispensed within [from, toExclusive)
  /// - toQuantity: last known stock at or before [toExclusive]
  _i2.Future<List<_i17.MedicineStockRangeRow>> getMedicineStockUsageByDateRange(
    DateTime from,
    DateTime toExclusive,
  ) => caller.callServerEndpoint<List<_i17.MedicineStockRangeRow>>(
    'adminReportEndpoints',
    'getMedicineStockUsageByDateRange',
    {
      'from': from,
      'toExclusive': toExclusive,
    },
  );

  /// Returns the list of dates (date-only, midnight) that have dispensed items.
  /// Useful for disabling dates that have no data.
  _i2.Future<List<DateTime>> getDispensedAvailableDates() =>
      caller.callServerEndpoint<List<DateTime>>(
        'adminReportEndpoints',
        'getDispensedAvailableDates',
        {},
      );

  /// Lab test summary within a date range.
  ///
  /// Semantics: [from] is inclusive start, [toExclusive] is exclusive end.
  _i2.Future<List<_i18.LabTestRangeRow>> getLabTestTotalsByDateRange(
    DateTime from,
    DateTime toExclusive,
  ) => caller.callServerEndpoint<List<_i18.LabTestRangeRow>>(
    'adminReportEndpoints',
    'getLabTestTotalsByDateRange',
    {
      'from': from,
      'toExclusive': toExclusive,
    },
  );
}

/// {@category Endpoint}
class EndpointFileUpload extends _i1.EndpointRef {
  EndpointFileUpload(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'fileUpload';

  /// Upload a file (image or PDF). Returns the relative URL path on success.
  _i2.Future<String?> uploadFile(
    _i19.ByteData bytes,
    String folder,
    String fileName,
  ) => caller.callServerEndpoint<String?>(
    'fileUpload',
    'uploadFile',
    {
      'bytes': bytes,
      'folder': folder,
      'fileName': fileName,
    },
  );
}

/// {@category Endpoint}
class EndpointNotification extends _i1.EndpointRef {
  EndpointNotification(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notification';

  _i2.Future<bool> createNotification({
    required String title,
    required String message,
  }) => caller.callServerEndpoint<bool>(
    'notification',
    'createNotification',
    {
      'title': title,
      'message': message,
    },
  );

  _i2.Future<List<_i20.NotificationInfo>> getMyNotifications({
    required int limit,
  }) => caller.callServerEndpoint<List<_i20.NotificationInfo>>(
    'notification',
    'getMyNotifications',
    {'limit': limit},
  );

  _i2.Future<Map<String, int>> getMyNotificationCounts() =>
      caller.callServerEndpoint<Map<String, int>>(
        'notification',
        'getMyNotificationCounts',
        {},
      );

  _i2.Future<_i20.NotificationInfo?> getNotificationById({
    required int notificationId,
  }) => caller.callServerEndpoint<_i20.NotificationInfo?>(
    'notification',
    'getNotificationById',
    {'notificationId': notificationId},
  );

  _i2.Future<bool> markAsRead({required int notificationId}) =>
      caller.callServerEndpoint<bool>(
        'notification',
        'markAsRead',
        {'notificationId': notificationId},
      );

  _i2.Future<bool> markAllAsRead() => caller.callServerEndpoint<bool>(
    'notification',
    'markAllAsRead',
    {},
  );
}

/// {@category Endpoint}
class EndpointPassword extends _i1.EndpointRef {
  EndpointPassword(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'password';

  _i2.Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => caller.callServerEndpoint<String>(
    'password',
    'changePassword',
    {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    },
  );
}

/// {@category Endpoint}
class EndpointDispenser extends _i1.EndpointRef {
  EndpointDispenser(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'dispenser';

  _i2.Future<_i21.DispenserProfileR?> getDispenserProfile() =>
      caller.callServerEndpoint<_i21.DispenserProfileR?>(
        'dispenser',
        'getDispenserProfile',
        {},
      );

  /// 2️⃣ Update dispenser profile
  _i2.Future<String> updateDispenserProfile({
    required String name,
    required String phone,
    required String qualification,
    required String designation,
    String? profilePictureUrl,
  }) => caller.callServerEndpoint<String>(
    'dispenser',
    'updateDispenserProfile',
    {
      'name': name,
      'phone': phone,
      'qualification': qualification,
      'designation': designation,
      'profilePictureUrl': profilePictureUrl,
    },
  );

  /// Fetch only inventory items that the dispenser can restock
  _i2.Future<List<_i11.InventoryItemInfo>> listInventoryItems() =>
      caller.callServerEndpoint<List<_i11.InventoryItemInfo>>(
        'dispenser',
        'listInventoryItems',
        {},
      );

  _i2.Future<bool> restockItem({
    required int itemId,
    required int quantity,
  }) => caller.callServerEndpoint<bool>(
    'dispenser',
    'restockItem',
    {
      'itemId': itemId,
      'quantity': quantity,
    },
  );

  _i2.Future<List<_i13.InventoryAuditLog>> getDispenserHistory() =>
      caller.callServerEndpoint<List<_i13.InventoryAuditLog>>(
        'dispenser',
        'getDispenserHistory',
        {},
      );

  /// Fetch all prescriptions that have not yet been dispensed
  /// Fetch pending prescriptions (not dispensed, not outside)
  _i2.Future<List<_i22.Prescription>> getPendingPrescriptions() =>
      caller.callServerEndpoint<List<_i22.Prescription>>(
        'dispenser',
        'getPendingPrescriptions',
        {},
      );

  _i2.Future<_i23.PrescriptionDetail?> getPrescriptionDetail(
    int prescriptionId,
  ) => caller.callServerEndpoint<_i23.PrescriptionDetail?>(
    'dispenser',
    'getPrescriptionDetail',
    {'prescriptionId': prescriptionId},
  );

  _i2.Future<_i11.InventoryItemInfo?> getStockByFirstWord(
    String medicineName,
  ) => caller.callServerEndpoint<_i11.InventoryItemInfo?>(
    'dispenser',
    'getStockByFirstWord',
    {'medicineName': medicineName},
  );

  _i2.Future<List<_i11.InventoryItemInfo>> searchInventoryItems(String query) =>
      caller.callServerEndpoint<List<_i11.InventoryItemInfo>>(
        'dispenser',
        'searchInventoryItems',
        {'query': query},
      );

  /// ডিসপেন্স করার মেইন ট্রানজ্যাকশন (Atomic Transaction)
  _i2.Future<bool> dispensePrescription({
    required int prescriptionId,
    required int dispenserId,
    required List<_i24.DispenseItemRequest> items,
  }) => caller.callServerEndpoint<bool>(
    'dispenser',
    'dispensePrescription',
    {
      'prescriptionId': prescriptionId,
      'dispenserId': dispenserId,
      'items': items,
    },
  );

  /// Detailed dispense history (patient + items) for current dispenser
  _i2.Future<List<_i25.DispenseHistoryEntry>> getDispenserDispenseHistory({
    required int limit,
  }) => caller.callServerEndpoint<List<_i25.DispenseHistoryEntry>>(
    'dispenser',
    'getDispenserDispenseHistory',
    {'limit': limit},
  );
}

/// {@category Endpoint}
class EndpointDoctor extends _i1.EndpointRef {
  EndpointDoctor(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'doctor';

  /// Doctor home dashboard data
  _i2.Future<_i26.DoctorHomeData> getDoctorHomeData() =>
      caller.callServerEndpoint<_i26.DoctorHomeData>(
        'doctor',
        'getDoctorHomeData',
        {},
      );

  _i2.Future<Map<String, String?>> getDoctorInfo() =>
      caller.callServerEndpoint<Map<String, String?>>(
        'doctor',
        'getDoctorInfo',
        {},
      );

  /// ডাক্তারের আইডি দিয়ে তার সই এবং নাম খুঁজে বের করা
  _i2.Future<_i27.DoctorProfile?> getDoctorProfile(int doctorId) =>
      caller.callServerEndpoint<_i27.DoctorProfile?>(
        'doctor',
        'getDoctorProfile',
        {'doctorId': doctorId},
      );

  /// Update doctor's user and staff profile. If staff_profiles row doesn't exist, insert it.
  /// Expects profilePictureUrl and signatureUrl to be remote URLs (uploads happen on frontend).
  _i2.Future<bool> updateDoctorProfile(
    int doctorId,
    String name,
    String email,
    String phone,
    String? profilePictureUrl,
    String? designation,
    String? qualification,
    String? signatureUrl,
  ) => caller.callServerEndpoint<bool>(
    'doctor',
    'updateDoctorProfile',
    {
      'doctorId': doctorId,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
      'designation': designation,
      'qualification': qualification,
      'signatureUrl': signatureUrl,
    },
  );

  _i2.Future<Map<String, String?>> getPatientByPhone(String phone) =>
      caller.callServerEndpoint<Map<String, String?>>(
        'doctor',
        'getPatientByPhone',
        {'phone': phone},
      );

  /// নতুন প্রেসক্রিপশন সেভ করা
  _i2.Future<int> createPrescription(
    _i22.Prescription prescription,
    List<_i28.PrescribedItem> items,
    String patientPhone,
  ) => caller.callServerEndpoint<int>(
    'doctor',
    'createPrescription',
    {
      'prescription': prescription,
      'items': items,
      'patientPhone': patientPhone,
    },
  );

  _i2.Future<List<_i29.PatientExternalReport>> getReportsForDoctor(
    int doctorId,
  ) => caller.callServerEndpoint<List<_i29.PatientExternalReport>>(
    'doctor',
    'getReportsForDoctor',
    {'doctorId': doctorId},
  );

  /// Track if a test report was reviewed by the assigned doctor.
  _i2.Future<bool> markReportReviewed(int reportId) =>
      caller.callServerEndpoint<bool>(
        'doctor',
        'markReportReviewed',
        {'reportId': reportId},
      );

  _i2.Future<int> revisePrescription({
    required int originalPrescriptionId,
    required String newAdvice,
    required List<_i28.PrescribedItem> newItems,
  }) => caller.callServerEndpoint<int>(
    'doctor',
    'revisePrescription',
    {
      'originalPrescriptionId': originalPrescriptionId,
      'newAdvice': newAdvice,
      'newItems': newItems,
    },
  );

  /// List page: all prescriptions (latest first) + optional search by name/phone
  _i2.Future<List<_i30.PatientPrescriptionListItem>>
  getPatientPrescriptionList({
    String? query,
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i30.PatientPrescriptionListItem>>(
    'doctor',
    'getPatientPrescriptionList',
    {
      'query': query,
      'limit': limit,
      'offset': offset,
    },
  );

  /// Bottom sheet: single prescription full details + medicines
  _i2.Future<_i31.PatientPrescriptionDetails?> getPrescriptionDetails({
    required int prescriptionId,
  }) => caller.callServerEndpoint<_i31.PatientPrescriptionDetails?>(
    'doctor',
    'getPrescriptionDetails',
    {'prescriptionId': prescriptionId},
  );
}

/// {@category Endpoint}
class EndpointLab extends _i1.EndpointRef {
  EndpointLab(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'lab';

  /// Fetch all lab tests using your raw SQL schema
  _i2.Future<List<_i32.LabTests>> getAllLabTests() =>
      caller.callServerEndpoint<List<_i32.LabTests>>(
        'lab',
        'getAllLabTests',
        {},
      );

  _i2.Future<bool> createTestResult({
    required int testId,
    required String patientName,
    required String mobileNumber,
    required String patientType,
  }) => caller.callServerEndpoint<bool>(
    'lab',
    'createTestResult',
    {
      'testId': testId,
      'patientName': patientName,
      'mobileNumber': mobileNumber,
      'patientType': patientType,
    },
  );

  /// Create a new lab test record
  _i2.Future<bool> createLabTest(_i32.LabTests test) =>
      caller.callServerEndpoint<bool>(
        'lab',
        'createLabTest',
        {'test': test},
      );

  /// Update an existing lab test (Admin style using QueryParameters)
  _i2.Future<bool> updateLabTest(_i32.LabTests test) =>
      caller.callServerEndpoint<bool>(
        'lab',
        'updateLabTest',
        {'test': test},
      );

  /// Dummy SMS sender: logs message to server logs (no real SMS)
  _i2.Future<bool> sendDummySms({
    required String mobileNumber,
    required String message,
  }) => caller.callServerEndpoint<bool>(
    'lab',
    'sendDummySms',
    {
      'mobileNumber': mobileNumber,
      'message': message,
    },
  );

  _i2.Future<bool> submitResult({required int resultId}) =>
      caller.callServerEndpoint<bool>(
        'lab',
        'submitResult',
        {'resultId': resultId},
      );

  /// Submit or resubmit result + dummy SMS notification.
  /// Upload happens on frontend; backend only stores the URL.
  _i2.Future<bool> submitResultWithUrl({
    required int resultId,
    required String attachmentUrl,
  }) => caller.callServerEndpoint<bool>(
    'lab',
    'submitResultWithUrl',
    {
      'resultId': resultId,
      'attachmentUrl': attachmentUrl,
    },
  );

  _i2.Future<List<_i33.TestResult>> getAllTestResults() =>
      caller.callServerEndpoint<List<_i33.TestResult>>(
        'lab',
        'getAllTestResults',
        {},
      );

  /// Fetch Lab Staff profile for the authenticated user
  _i2.Future<_i34.StaffProfileDto?> getStaffProfile() =>
      caller.callServerEndpoint<_i34.StaffProfileDto?>(
        'lab',
        'getStaffProfile',
        {},
      );

  /// Update Staff Profile (Users + Staff_Profiles tables)
  _i2.Future<bool> updateStaffProfile({
    required String name,
    required String phone,
    required String email,
    required String designation,
    required String qualification,
    String? profilePictureUrl,
  }) => caller.callServerEndpoint<bool>(
    'lab',
    'updateStaffProfile',
    {
      'name': name,
      'phone': phone,
      'email': email,
      'designation': designation,
      'qualification': qualification,
      'profilePictureUrl': profilePictureUrl,
    },
  );

  _i2.Future<_i35.LabToday> getLabHomeTwoDaySummary() =>
      caller.callServerEndpoint<_i35.LabToday>(
        'lab',
        'getLabHomeTwoDaySummary',
        {},
      );

  _i2.Future<List<_i36.LabTenHistory>> getLast10TestHistory() =>
      caller.callServerEndpoint<List<_i36.LabTenHistory>>(
        'lab',
        'getLast10TestHistory',
        {},
      );
}

/// {@category Endpoint}
class EndpointPatient extends _i1.EndpointRef {
  EndpointPatient(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'patient';

  _i2.Future<_i37.PatientProfile?> getPatientProfile() =>
      caller.callServerEndpoint<_i37.PatientProfile?>(
        'patient',
        'getPatientProfile',
        {},
      );

  /// List lab tests from the `tests` table. Returns a list of maps with keys:
  /// test_name, description, student_fee, teacher_fee, outside_fee, available
  _i2.Future<List<_i32.LabTests>> listTests() =>
      caller.callServerEndpoint<List<_i32.LabTests>>(
        'patient',
        'listTests',
        {},
      );

  /// Return the role of a user (stored as text in users.role) by email/userId.
  /// Returns uppercase role string or empty string if not found.
  _i2.Future<String> getUserRole() => caller.callServerEndpoint<String>(
    'patient',
    'getUserRole',
    {},
  );

  _i2.Future<String> updatePatientProfile(
    String name,
    String phone,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
  ) => caller.callServerEndpoint<String>(
    'patient',
    'updatePatientProfile',
    {
      'name': name,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'profileImageUrl': profileImageUrl,
    },
  );

  /// Fetch logged-in patient's lab reports using phone number
  _i2.Future<List<_i38.PatientReportDto>> getMyLabReports() =>
      caller.callServerEndpoint<List<_i38.PatientReportDto>>(
        'patient',
        'getMyLabReports',
        {},
      );

  _i2.Future<List<_i39.PrescriptionList>> getMyPrescriptionList() =>
      caller.callServerEndpoint<List<_i39.PrescriptionList>>(
        'patient',
        'getMyPrescriptionList',
        {},
      );

  _i2.Future<bool> finalizeReportUpload({
    required int prescriptionId,
    required String reportType,
    required String fileUrl,
  }) => caller.callServerEndpoint<bool>(
    'patient',
    'finalizeReportUpload',
    {
      'prescriptionId': prescriptionId,
      'reportType': reportType,
      'fileUrl': fileUrl,
    },
  );

  _i2.Future<List<_i29.PatientExternalReport>> getMyExternalReports() =>
      caller.callServerEndpoint<List<_i29.PatientExternalReport>>(
        'patient',
        'getMyExternalReports',
        {},
      );

  /// ১. রোগীর সব প্রেসক্রিপশনের লিস্ট আনা
  _i2.Future<List<_i39.PrescriptionList>> getPrescriptionList(int patientId) =>
      caller.callServerEndpoint<List<_i39.PrescriptionList>>(
        'patient',
        'getPrescriptionList',
        {'patientId': patientId},
      );

  /// সরাসরি Patient ID (User ID) দিয়ে প্রেসক্রিপশন লিস্ট আনা
  _i2.Future<List<_i39.PrescriptionList>> getPrescriptionsByPatientId(
    int patientId,
  ) => caller.callServerEndpoint<List<_i39.PrescriptionList>>(
    'patient',
    'getPrescriptionsByPatientId',
    {'patientId': patientId},
  );

  /// ২. একটি নির্দিষ্ট প্রেসক্রিপশনের বিস্তারিত তথ্য (PDF এর জন্য)
  _i2.Future<_i23.PrescriptionDetail?> getPrescriptionDetail(
    int prescriptionId,
  ) => caller.callServerEndpoint<_i23.PrescriptionDetail?>(
    'patient',
    'getPrescriptionDetail',
    {'prescriptionId': prescriptionId},
  );

  /// Fetch all active medical staff (Admin, Doctor, Dispenser, Labstaff)
  /// Fetch all active medical staff (Admin, Doctor, Dispenser, Labstaff)
  _i2.Future<List<_i40.StaffInfo>> getMedicalStaff() =>
      caller.callServerEndpoint<List<_i40.StaffInfo>>(
        'patient',
        'getMedicalStaff',
        {},
      );

  _i2.Future<List<_i41.AmbulanceContact>> getAmbulanceContacts() =>
      caller.callServerEndpoint<List<_i41.AmbulanceContact>>(
        'patient',
        'getAmbulanceContacts',
        {},
      );

  _i2.Future<List<_i42.OndutyStaff>> getOndutyStaff() =>
      caller.callServerEndpoint<List<_i42.OndutyStaff>>(
        'patient',
        'getOndutyStaff',
        {},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i43.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i43.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i44.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    auth = EndpointAuth(this);
    adminEndpoints = EndpointAdminEndpoints(this);
    adminInventoryEndpoints = EndpointAdminInventoryEndpoints(this);
    adminReportEndpoints = EndpointAdminReportEndpoints(this);
    fileUpload = EndpointFileUpload(this);
    notification = EndpointNotification(this);
    password = EndpointPassword(this);
    dispenser = EndpointDispenser(this);
    doctor = EndpointDoctor(this);
    lab = EndpointLab(this);
    patient = EndpointPatient(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointAuth auth;

  late final EndpointAdminEndpoints adminEndpoints;

  late final EndpointAdminInventoryEndpoints adminInventoryEndpoints;

  late final EndpointAdminReportEndpoints adminReportEndpoints;

  late final EndpointFileUpload fileUpload;

  late final EndpointNotification notification;

  late final EndpointPassword password;

  late final EndpointDispenser dispenser;

  late final EndpointDoctor doctor;

  late final EndpointLab lab;

  late final EndpointPatient patient;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'auth': auth,
    'adminEndpoints': adminEndpoints,
    'adminInventoryEndpoints': adminInventoryEndpoints,
    'adminReportEndpoints': adminReportEndpoints,
    'fileUpload': fileUpload,
    'notification': notification,
    'password': password,
    'dispenser': dispenser,
    'doctor': doctor,
    'lab': lab,
    'patient': patient,
    'greeting': greeting,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
