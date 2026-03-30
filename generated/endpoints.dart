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
import 'package:serverpod/serverpod.dart' as _i1;
import '../auth/auth_endpoint.dart' as _i2;
import '../endpoints/admin/admin_endpoints.dart' as _i3;
import '../endpoints/admin/admin_inventory_endpoints.dart' as _i4;
import '../endpoints/admin/admin_report_endpoints.dart' as _i5;
import '../endpoints/file_upload_endpoint.dart' as _i6;
import '../endpoints/notifications_endpoint.dart' as _i7;
import '../endpoints/password_endpoint.dart' as _i8;
import '../endpoints/roles/dispenser_endpoints.dart' as _i9;
import '../endpoints/roles/doctor_endpoints.dart' as _i10;
import '../endpoints/roles/lab_endpoints.dart' as _i11;
import '../endpoints/roles/patient_endpoints.dart' as _i12;
import '../greeting_endpoint.dart' as _i13;
import 'dart:typed_data' as _i14;
import 'package:backend_server/src/generated/dispense_request.dart' as _i15;
import 'package:backend_server/src/generated/prescription.dart' as _i16;
import 'package:backend_server/src/generated/PrescribedItem.dart' as _i17;
import 'package:backend_server/src/generated/patient_return_tests.dart' as _i18;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'auth': _i2.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'adminEndpoints': _i3.AdminEndpoints()
        ..initialize(
          server,
          'adminEndpoints',
          null,
        ),
      'adminInventoryEndpoints': _i4.AdminInventoryEndpoints()
        ..initialize(
          server,
          'adminInventoryEndpoints',
          null,
        ),
      'adminReportEndpoints': _i5.AdminReportEndpoints()
        ..initialize(
          server,
          'adminReportEndpoints',
          null,
        ),
      'fileUpload': _i6.FileUploadEndpoint()
        ..initialize(
          server,
          'fileUpload',
          null,
        ),
      'notification': _i7.NotificationEndpoint()
        ..initialize(
          server,
          'notification',
          null,
        ),
      'password': _i8.PasswordEndpoint()
        ..initialize(
          server,
          'password',
          null,
        ),
      'dispenser': _i9.DispenserEndpoint()
        ..initialize(
          server,
          'dispenser',
          null,
        ),
      'doctor': _i10.DoctorEndpoint()
        ..initialize(
          server,
          'doctor',
          null,
        ),
      'lab': _i11.LabEndpoint()
        ..initialize(
          server,
          'lab',
          null,
        ),
      'patient': _i12.PatientEndpoint()
        ..initialize(
          server,
          'patient',
          null,
        ),
      'greeting': _i13.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'requestProfileEmailChangeOtp': _i1.MethodConnector(
          name: 'requestProfileEmailChangeOtp',
          params: {
            'newEmail': _i1.ParameterDescription(
              name: 'newEmail',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint)
                  .requestProfileEmailChangeOtp(
                    session,
                    params['newEmail'],
                  ),
        ),
        'verifyProfileEmailChangeOtp': _i1.MethodConnector(
          name: 'verifyProfileEmailChangeOtp',
          params: {
            'newEmail': _i1.ParameterDescription(
              name: 'newEmail',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otp': _i1.ParameterDescription(
              name: 'otp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otpToken': _i1.ParameterDescription(
              name: 'otpToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint)
                  .verifyProfileEmailChangeOtp(
                    session,
                    params['newEmail'],
                    params['otp'],
                    params['otpToken'],
                  ),
        ),
        'updateMyEmailWithOtp': _i1.MethodConnector(
          name: 'updateMyEmailWithOtp',
          params: {
            'newEmail': _i1.ParameterDescription(
              name: 'newEmail',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otp': _i1.ParameterDescription(
              name: 'otp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otpToken': _i1.ParameterDescription(
              name: 'otpToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).updateMyEmailWithOtp(
                    session,
                    params['newEmail'],
                    params['otp'],
                    params['otpToken'],
                  ),
        ),
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'deviceId': _i1.ParameterDescription(
              name: 'deviceId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint).login(
                session,
                params['email'],
                params['password'],
                deviceId: params['deviceId'],
              ),
        ),
        'startSignupPhoneOtp': _i1.MethodConnector(
          name: 'startSignupPhoneOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).startSignupPhoneOtp(
                    session,
                    params['email'],
                    params['phone'],
                  ),
        ),
        'verifyLoginOtp': _i1.MethodConnector(
          name: 'verifyLoginOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otp': _i1.ParameterDescription(
              name: 'otp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otpToken': _i1.ParameterDescription(
              name: 'otpToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'deviceId': _i1.ParameterDescription(
              name: 'deviceId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint).verifyLoginOtp(
                session,
                params['email'],
                params['otp'],
                params['otpToken'],
                deviceId: params['deviceId'],
              ),
        ),
        'logout': _i1.MethodConnector(
          name: 'logout',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).logout(session),
        ),
        'register': _i1.MethodConnector(
          name: 'register',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint).register(
                session,
                params['email'],
                params['password'],
                params['name'],
                params['role'],
              ),
        ),
        'resendOtp': _i1.MethodConnector(
          name: 'resendOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint).resendOtp(
                session,
                params['email'],
                params['password'],
                params['name'],
                params['role'],
              ),
        ),
        'verifySignupEmailAndStartPhoneOtp': _i1.MethodConnector(
          name: 'verifySignupEmailAndStartPhoneOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'emailOtp': _i1.ParameterDescription(
              name: 'emailOtp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'emailOtpToken': _i1.ParameterDescription(
              name: 'emailOtpToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint)
                  .verifySignupEmailAndStartPhoneOtp(
                    session,
                    params['email'],
                    params['emailOtp'],
                    params['emailOtpToken'],
                    params['phone'],
                  ),
        ),
        'completeSignupWithPhoneOtp': _i1.MethodConnector(
          name: 'completeSignupWithPhoneOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phoneOtp': _i1.ParameterDescription(
              name: 'phoneOtp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phoneOtpToken': _i1.ParameterDescription(
              name: 'phoneOtpToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'bloodGroup': _i1.ParameterDescription(
              name: 'bloodGroup',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'dateOfBirth': _i1.ParameterDescription(
              name: 'dateOfBirth',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'gender': _i1.ParameterDescription(
              name: 'gender',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint)
                  .completeSignupWithPhoneOtp(
                    session,
                    params['email'],
                    params['phone'],
                    params['phoneOtp'],
                    params['phoneOtpToken'],
                    params['password'],
                    params['name'],
                    params['role'],
                    params['bloodGroup'],
                    params['dateOfBirth'],
                    params['gender'],
                  ),
        ),
        'sendWelcomeEmailViaResend': _i1.MethodConnector(
          name: 'sendWelcomeEmailViaResend',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint)
                  .sendWelcomeEmailViaResend(
                    session,
                    params['email'],
                    params['name'],
                  ),
        ),
        'verifyOtp': _i1.MethodConnector(
          name: 'verifyOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otp': _i1.ParameterDescription(
              name: 'otp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'bloodGroup': _i1.ParameterDescription(
              name: 'bloodGroup',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'allergies': _i1.ParameterDescription(
              name: 'allergies',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint).verifyOtp(
                session,
                params['email'],
                params['otp'],
                params['token'],
                params['password'],
                params['name'],
                params['role'],
                params['phone'],
                params['bloodGroup'],
                params['allergies'],
              ),
        ),
        'requestPasswordReset': _i1.MethodConnector(
          name: 'requestPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).requestPasswordReset(
                    session,
                    params['email'],
                  ),
        ),
        'verifyPasswordReset': _i1.MethodConnector(
          name: 'verifyPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otp': _i1.ParameterDescription(
              name: 'otp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).verifyPasswordReset(
                    session,
                    params['email'],
                    params['otp'],
                    params['token'],
                  ),
        ),
        'resetPassword': _i1.MethodConnector(
          name: 'resetPassword',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint).resetPassword(
                session,
                params['email'],
                params['token'],
                params['newPassword'],
              ),
        ),
        'changePasswordUniversal': _i1.MethodConnector(
          name: 'changePasswordUniversal',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'currentPassword': _i1.ParameterDescription(
              name: 'currentPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint)
                  .changePasswordUniversal(
                    session,
                    params['email'],
                    params['currentPassword'],
                    params['newPassword'],
                  ),
        ),
      },
    );
    connectors['adminEndpoints'] = _i1.EndpointConnector(
      name: 'adminEndpoints',
      endpoint: endpoints['adminEndpoints']!,
      methodConnectors: {
        'listUsersByRole': _i1.MethodConnector(
          name: 'listUsersByRole',
          params: {
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .listUsersByRole(
                    session,
                    params['role'],
                    params['limit'],
                  ),
        ),
        'toggleUserActive': _i1.MethodConnector(
          name: 'toggleUserActive',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .toggleUserActive(
                    session,
                    params['userId'],
                  ),
        ),
        'createUser': _i1.MethodConnector(
          name: 'createUser',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'passwordHash': _i1.ParameterDescription(
              name: 'passwordHash',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .createUser(
                    session,
                    params['name'],
                    params['email'],
                    params['passwordHash'],
                    params['role'],
                    params['phone'],
                  ),
        ),
        'createUserWithPassword': _i1.MethodConnector(
          name: 'createUserWithPassword',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .createUserWithPassword(
                    session,
                    params['name'],
                    params['email'],
                    params['password'],
                    params['role'],
                    params['phone'],
                  ),
        ),
        'getRosters': _i1.MethodConnector(
          name: 'getRosters',
          params: {
            'staffId': _i1.ParameterDescription(
              name: 'staffId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'fromDate': _i1.ParameterDescription(
              name: 'fromDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'toDate': _i1.ParameterDescription(
              name: 'toDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'includeDeleted': _i1.ParameterDescription(
              name: 'includeDeleted',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .getRosters(
                    session,
                    params['staffId'],
                    params['fromDate'],
                    params['toDate'],
                    includeDeleted: params['includeDeleted'],
                  ),
        ),
        'deleteRoster': _i1.MethodConnector(
          name: 'deleteRoster',
          params: {
            'rosterId': _i1.ParameterDescription(
              name: 'rosterId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .deleteRoster(
                    session,
                    params['rosterId'],
                  ),
        ),
        'saveRoster': _i1.MethodConnector(
          name: 'saveRoster',
          params: {
            'rosterId': _i1.ParameterDescription(
              name: 'rosterId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'staffId': _i1.ParameterDescription(
              name: 'staffId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'shiftType': _i1.ParameterDescription(
              name: 'shiftType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'shiftDate': _i1.ParameterDescription(
              name: 'shiftDate',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'timeRange': _i1.ParameterDescription(
              name: 'timeRange',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'approvedBy': _i1.ParameterDescription(
              name: 'approvedBy',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .saveRoster(
                    session,
                    params['rosterId'],
                    params['staffId'],
                    params['shiftType'],
                    params['shiftDate'],
                    params['timeRange'],
                    params['status'],
                    params['approvedBy'],
                  ),
        ),
        'listStaff': _i1.MethodConnector(
          name: 'listStaff',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminEndpoints'] as _i3.AdminEndpoints).listStaff(
                    session,
                    params['limit'],
                  ),
        ),
        'getAdminProfile': _i1.MethodConnector(
          name: 'getAdminProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .getAdminProfile(
                    session,
                    params['userId'],
                  ),
        ),
        'updateAdminProfile': _i1.MethodConnector(
          name: 'updateAdminProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'profilePictureData': _i1.ParameterDescription(
              name: 'profilePictureData',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'designation': _i1.ParameterDescription(
              name: 'designation',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'qualification': _i1.ParameterDescription(
              name: 'qualification',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .updateAdminProfile(
                    session,
                    params['userId'],
                    params['name'],
                    params['phone'],
                    params['profilePictureData'],
                    params['designation'],
                    params['qualification'],
                  ),
        ),
        'changePassword': _i1.MethodConnector(
          name: 'changePassword',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'currentPassword': _i1.ParameterDescription(
              name: 'currentPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .changePassword(
                    session,
                    params['userId'],
                    params['currentPassword'],
                    params['newPassword'],
                  ),
        ),
        'createAuditLog': _i1.MethodConnector(
          name: 'createAuditLog',
          params: {
            'adminId': _i1.ParameterDescription(
              name: 'adminId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'action': _i1.ParameterDescription(
              name: 'action',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'targetId': _i1.ParameterDescription(
              name: 'targetId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .createAuditLog(
                    session,
                    adminId: params['adminId'],
                    action: params['action'],
                    targetId: params['targetId'],
                  ),
        ),
        'getAuditLogs': _i1.MethodConnector(
          name: 'getAuditLogs',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .getAuditLogs(session),
        ),
        'getRecentAuditLogs': _i1.MethodConnector(
          name: 'getRecentAuditLogs',
          params: {
            'hours': _i1.ParameterDescription(
              name: 'hours',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .getRecentAuditLogs(
                    session,
                    params['hours'],
                    params['limit'],
                  ),
        ),
        'addAmbulanceContact': _i1.MethodConnector(
          name: 'addAmbulanceContact',
          params: {
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phoneBn': _i1.ParameterDescription(
              name: 'phoneBn',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phoneEn': _i1.ParameterDescription(
              name: 'phoneEn',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'isPrimary': _i1.ParameterDescription(
              name: 'isPrimary',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .addAmbulanceContact(
                    session,
                    params['title'],
                    params['phoneBn'],
                    params['phoneEn'],
                    params['isPrimary'],
                  ),
        ),
        'updateAmbulanceContact': _i1.MethodConnector(
          name: 'updateAmbulanceContact',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phoneBn': _i1.ParameterDescription(
              name: 'phoneBn',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phoneEn': _i1.ParameterDescription(
              name: 'phoneEn',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'isPrimary': _i1.ParameterDescription(
              name: 'isPrimary',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i3.AdminEndpoints)
                  .updateAmbulanceContact(
                    session,
                    params['id'],
                    params['title'],
                    params['phoneBn'],
                    params['phoneEn'],
                    params['isPrimary'],
                  ),
        ),
      },
    );
    connectors['adminInventoryEndpoints'] = _i1.EndpointConnector(
      name: 'adminInventoryEndpoints',
      endpoint: endpoints['adminInventoryEndpoints']!,
      methodConnectors: {
        'addInventoryCategory': _i1.MethodConnector(
          name: 'addInventoryCategory',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminInventoryEndpoints']
                          as _i4.AdminInventoryEndpoints)
                      .addInventoryCategory(
                        session,
                        params['name'],
                        params['description'],
                      ),
        ),
        'listInventoryCategories': _i1.MethodConnector(
          name: 'listInventoryCategories',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminInventoryEndpoints']
                          as _i4.AdminInventoryEndpoints)
                      .listInventoryCategories(session),
        ),
        'addInventoryItem': _i1.MethodConnector(
          name: 'addInventoryItem',
          params: {
            'categoryId': _i1.ParameterDescription(
              name: 'categoryId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'itemName': _i1.ParameterDescription(
              name: 'itemName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'unit': _i1.ParameterDescription(
              name: 'unit',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'minimumStock': _i1.ParameterDescription(
              name: 'minimumStock',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'initialStock': _i1.ParameterDescription(
              name: 'initialStock',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'canRestockDispenser': _i1.ParameterDescription(
              name: 'canRestockDispenser',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminInventoryEndpoints']
                          as _i4.AdminInventoryEndpoints)
                      .addInventoryItem(
                        session,
                        categoryId: params['categoryId'],
                        itemName: params['itemName'],
                        unit: params['unit'],
                        minimumStock: params['minimumStock'],
                        initialStock: params['initialStock'],
                        canRestockDispenser: params['canRestockDispenser'],
                      ),
        ),
        'updateInventoryStock': _i1.MethodConnector(
          name: 'updateInventoryStock',
          params: {
            'itemId': _i1.ParameterDescription(
              name: 'itemId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'quantity': _i1.ParameterDescription(
              name: 'quantity',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'type': _i1.ParameterDescription(
              name: 'type',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminInventoryEndpoints']
                          as _i4.AdminInventoryEndpoints)
                      .updateInventoryStock(
                        session,
                        itemId: params['itemId'],
                        quantity: params['quantity'],
                        type: params['type'],
                      ),
        ),
        'updateDispenserRestockFlag': _i1.MethodConnector(
          name: 'updateDispenserRestockFlag',
          params: {
            'itemId': _i1.ParameterDescription(
              name: 'itemId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'canRestock': _i1.ParameterDescription(
              name: 'canRestock',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminInventoryEndpoints']
                          as _i4.AdminInventoryEndpoints)
                      .updateDispenserRestockFlag(
                        session,
                        itemId: params['itemId'],
                        canRestock: params['canRestock'],
                      ),
        ),
        'listInventoryItems': _i1.MethodConnector(
          name: 'listInventoryItems',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminInventoryEndpoints']
                          as _i4.AdminInventoryEndpoints)
                      .listInventoryItems(session),
        ),
        'updateMinimumThreshold': _i1.MethodConnector(
          name: 'updateMinimumThreshold',
          params: {
            'itemId': _i1.ParameterDescription(
              name: 'itemId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'newThreshold': _i1.ParameterDescription(
              name: 'newThreshold',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminInventoryEndpoints']
                          as _i4.AdminInventoryEndpoints)
                      .updateMinimumThreshold(
                        session,
                        itemId: params['itemId'],
                        newThreshold: params['newThreshold'],
                      ),
        ),
        'getItemTransactions': _i1.MethodConnector(
          name: 'getItemTransactions',
          params: {
            'itemId': _i1.ParameterDescription(
              name: 'itemId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminInventoryEndpoints']
                          as _i4.AdminInventoryEndpoints)
                      .getItemTransactions(
                        session,
                        params['itemId'],
                      ),
        ),
        'getInventoryAuditLogs': _i1.MethodConnector(
          name: 'getInventoryAuditLogs',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminInventoryEndpoints']
                          as _i4.AdminInventoryEndpoints)
                      .getInventoryAuditLogs(
                        session,
                        params['limit'],
                        params['offset'],
                      ),
        ),
      },
    );
    connectors['adminReportEndpoints'] = _i1.EndpointConnector(
      name: 'adminReportEndpoints',
      endpoint: endpoints['adminReportEndpoints']!,
      methodConnectors: {
        'getAdminDashboardOverview': _i1.MethodConnector(
          name: 'getAdminDashboardOverview',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminReportEndpoints']
                          as _i5.AdminReportEndpoints)
                      .getAdminDashboardOverview(session),
        ),
        'getDashboardAnalytics': _i1.MethodConnector(
          name: 'getDashboardAnalytics',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminReportEndpoints']
                          as _i5.AdminReportEndpoints)
                      .getDashboardAnalytics(session),
        ),
        'getMedicineUsageByDateRange': _i1.MethodConnector(
          name: 'getMedicineUsageByDateRange',
          params: {
            'from': _i1.ParameterDescription(
              name: 'from',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'to': _i1.ParameterDescription(
              name: 'to',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminReportEndpoints']
                          as _i5.AdminReportEndpoints)
                      .getMedicineUsageByDateRange(
                        session,
                        params['from'],
                        params['to'],
                      ),
        ),
        'getMedicineStockUsageByDateRange': _i1.MethodConnector(
          name: 'getMedicineStockUsageByDateRange',
          params: {
            'from': _i1.ParameterDescription(
              name: 'from',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'toExclusive': _i1.ParameterDescription(
              name: 'toExclusive',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminReportEndpoints']
                          as _i5.AdminReportEndpoints)
                      .getMedicineStockUsageByDateRange(
                        session,
                        params['from'],
                        params['toExclusive'],
                      ),
        ),
        'getDispensedAvailableDates': _i1.MethodConnector(
          name: 'getDispensedAvailableDates',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminReportEndpoints']
                          as _i5.AdminReportEndpoints)
                      .getDispensedAvailableDates(session),
        ),
        'getLabTestTotalsByDateRange': _i1.MethodConnector(
          name: 'getLabTestTotalsByDateRange',
          params: {
            'from': _i1.ParameterDescription(
              name: 'from',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'toExclusive': _i1.ParameterDescription(
              name: 'toExclusive',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminReportEndpoints']
                          as _i5.AdminReportEndpoints)
                      .getLabTestTotalsByDateRange(
                        session,
                        params['from'],
                        params['toExclusive'],
                      ),
        ),
      },
    );
    connectors['fileUpload'] = _i1.EndpointConnector(
      name: 'fileUpload',
      endpoint: endpoints['fileUpload']!,
      methodConnectors: {
        'uploadFile': _i1.MethodConnector(
          name: 'uploadFile',
          params: {
            'bytes': _i1.ParameterDescription(
              name: 'bytes',
              type: _i1.getType<_i14.ByteData>(),
              nullable: false,
            ),
            'folder': _i1.ParameterDescription(
              name: 'folder',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'fileName': _i1.ParameterDescription(
              name: 'fileName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['fileUpload'] as _i6.FileUploadEndpoint)
                  .uploadFile(
                    session,
                    params['bytes'],
                    params['folder'],
                    params['fileName'],
                  ),
        ),
      },
    );
    connectors['notification'] = _i1.EndpointConnector(
      name: 'notification',
      endpoint: endpoints['notification']!,
      methodConnectors: {
        'createNotification': _i1.MethodConnector(
          name: 'createNotification',
          params: {
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i7.NotificationEndpoint)
                  .createNotification(
                    session,
                    title: params['title'],
                    message: params['message'],
                  ),
        ),
        'getMyNotifications': _i1.MethodConnector(
          name: 'getMyNotifications',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i7.NotificationEndpoint)
                  .getMyNotifications(
                    session,
                    limit: params['limit'],
                  ),
        ),
        'getMyNotificationCounts': _i1.MethodConnector(
          name: 'getMyNotificationCounts',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i7.NotificationEndpoint)
                  .getMyNotificationCounts(session),
        ),
        'getNotificationById': _i1.MethodConnector(
          name: 'getNotificationById',
          params: {
            'notificationId': _i1.ParameterDescription(
              name: 'notificationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i7.NotificationEndpoint)
                  .getNotificationById(
                    session,
                    notificationId: params['notificationId'],
                  ),
        ),
        'markAsRead': _i1.MethodConnector(
          name: 'markAsRead',
          params: {
            'notificationId': _i1.ParameterDescription(
              name: 'notificationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i7.NotificationEndpoint)
                  .markAsRead(
                    session,
                    notificationId: params['notificationId'],
                  ),
        ),
        'markAllAsRead': _i1.MethodConnector(
          name: 'markAllAsRead',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i7.NotificationEndpoint)
                  .markAllAsRead(session),
        ),
      },
    );
    connectors['password'] = _i1.EndpointConnector(
      name: 'password',
      endpoint: endpoints['password']!,
      methodConnectors: {
        'changePassword': _i1.MethodConnector(
          name: 'changePassword',
          params: {
            'currentPassword': _i1.ParameterDescription(
              name: 'currentPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['password'] as _i8.PasswordEndpoint)
                  .changePassword(
                    session,
                    currentPassword: params['currentPassword'],
                    newPassword: params['newPassword'],
                  ),
        ),
      },
    );
    connectors['dispenser'] = _i1.EndpointConnector(
      name: 'dispenser',
      endpoint: endpoints['dispenser']!,
      methodConnectors: {
        'getDispenserProfile': _i1.MethodConnector(
          name: 'getDispenserProfile',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .getDispenserProfile(session),
        ),
        'updateDispenserProfile': _i1.MethodConnector(
          name: 'updateDispenserProfile',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'qualification': _i1.ParameterDescription(
              name: 'qualification',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'designation': _i1.ParameterDescription(
              name: 'designation',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'profilePictureUrl': _i1.ParameterDescription(
              name: 'profilePictureUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .updateDispenserProfile(
                    session,
                    name: params['name'],
                    phone: params['phone'],
                    qualification: params['qualification'],
                    designation: params['designation'],
                    profilePictureUrl: params['profilePictureUrl'],
                  ),
        ),
        'listInventoryItems': _i1.MethodConnector(
          name: 'listInventoryItems',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .listInventoryItems(session),
        ),
        'restockItem': _i1.MethodConnector(
          name: 'restockItem',
          params: {
            'itemId': _i1.ParameterDescription(
              name: 'itemId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'quantity': _i1.ParameterDescription(
              name: 'quantity',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['dispenser'] as _i9.DispenserEndpoint).restockItem(
                    session,
                    itemId: params['itemId'],
                    quantity: params['quantity'],
                  ),
        ),
        'getDispenserHistory': _i1.MethodConnector(
          name: 'getDispenserHistory',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .getDispenserHistory(session),
        ),
        'getPendingPrescriptions': _i1.MethodConnector(
          name: 'getPendingPrescriptions',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .getPendingPrescriptions(session),
        ),
        'getPrescriptionDetail': _i1.MethodConnector(
          name: 'getPrescriptionDetail',
          params: {
            'prescriptionId': _i1.ParameterDescription(
              name: 'prescriptionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .getPrescriptionDetail(
                    session,
                    params['prescriptionId'],
                  ),
        ),
        'getStockByFirstWord': _i1.MethodConnector(
          name: 'getStockByFirstWord',
          params: {
            'medicineName': _i1.ParameterDescription(
              name: 'medicineName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .getStockByFirstWord(
                    session,
                    params['medicineName'],
                  ),
        ),
        'searchInventoryItems': _i1.MethodConnector(
          name: 'searchInventoryItems',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .searchInventoryItems(
                    session,
                    params['query'],
                  ),
        ),
        'dispensePrescription': _i1.MethodConnector(
          name: 'dispensePrescription',
          params: {
            'prescriptionId': _i1.ParameterDescription(
              name: 'prescriptionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'dispenserId': _i1.ParameterDescription(
              name: 'dispenserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'items': _i1.ParameterDescription(
              name: 'items',
              type: _i1.getType<List<_i15.DispenseItemRequest>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .dispensePrescription(
                    session,
                    prescriptionId: params['prescriptionId'],
                    dispenserId: params['dispenserId'],
                    items: params['items'],
                  ),
        ),
        'getDispenserDispenseHistory': _i1.MethodConnector(
          name: 'getDispenserDispenseHistory',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['dispenser'] as _i9.DispenserEndpoint)
                  .getDispenserDispenseHistory(
                    session,
                    limit: params['limit'],
                  ),
        ),
      },
    );
    connectors['doctor'] = _i1.EndpointConnector(
      name: 'doctor',
      endpoint: endpoints['doctor']!,
      methodConnectors: {
        'getDoctorHomeData': _i1.MethodConnector(
          name: 'getDoctorHomeData',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .getDoctorHomeData(session),
        ),
        'getDoctorInfo': _i1.MethodConnector(
          name: 'getDoctorInfo',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .getDoctorInfo(session),
        ),
        'getDoctorProfile': _i1.MethodConnector(
          name: 'getDoctorProfile',
          params: {
            'doctorId': _i1.ParameterDescription(
              name: 'doctorId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['doctor'] as _i10.DoctorEndpoint).getDoctorProfile(
                    session,
                    params['doctorId'],
                  ),
        ),
        'updateDoctorProfile': _i1.MethodConnector(
          name: 'updateDoctorProfile',
          params: {
            'doctorId': _i1.ParameterDescription(
              name: 'doctorId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'profilePictureUrl': _i1.ParameterDescription(
              name: 'profilePictureUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'designation': _i1.ParameterDescription(
              name: 'designation',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'qualification': _i1.ParameterDescription(
              name: 'qualification',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'signatureUrl': _i1.ParameterDescription(
              name: 'signatureUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .updateDoctorProfile(
                    session,
                    params['doctorId'],
                    params['name'],
                    params['email'],
                    params['phone'],
                    params['profilePictureUrl'],
                    params['designation'],
                    params['qualification'],
                    params['signatureUrl'],
                  ),
        ),
        'getPatientByPhone': _i1.MethodConnector(
          name: 'getPatientByPhone',
          params: {
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .getPatientByPhone(
                    session,
                    params['phone'],
                  ),
        ),
        'createPrescription': _i1.MethodConnector(
          name: 'createPrescription',
          params: {
            'prescription': _i1.ParameterDescription(
              name: 'prescription',
              type: _i1.getType<_i16.Prescription>(),
              nullable: false,
            ),
            'items': _i1.ParameterDescription(
              name: 'items',
              type: _i1.getType<List<_i17.PrescribedItem>>(),
              nullable: false,
            ),
            'patientPhone': _i1.ParameterDescription(
              name: 'patientPhone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .createPrescription(
                    session,
                    params['prescription'],
                    params['items'],
                    params['patientPhone'],
                  ),
        ),
        'getReportsForDoctor': _i1.MethodConnector(
          name: 'getReportsForDoctor',
          params: {
            'doctorId': _i1.ParameterDescription(
              name: 'doctorId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .getReportsForDoctor(
                    session,
                    params['doctorId'],
                  ),
        ),
        'markReportReviewed': _i1.MethodConnector(
          name: 'markReportReviewed',
          params: {
            'reportId': _i1.ParameterDescription(
              name: 'reportId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .markReportReviewed(
                    session,
                    params['reportId'],
                  ),
        ),
        'revisePrescription': _i1.MethodConnector(
          name: 'revisePrescription',
          params: {
            'originalPrescriptionId': _i1.ParameterDescription(
              name: 'originalPrescriptionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'newAdvice': _i1.ParameterDescription(
              name: 'newAdvice',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newItems': _i1.ParameterDescription(
              name: 'newItems',
              type: _i1.getType<List<_i17.PrescribedItem>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .revisePrescription(
                    session,
                    originalPrescriptionId: params['originalPrescriptionId'],
                    newAdvice: params['newAdvice'],
                    newItems: params['newItems'],
                  ),
        ),
        'getPatientPrescriptionList': _i1.MethodConnector(
          name: 'getPatientPrescriptionList',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .getPatientPrescriptionList(
                    session,
                    query: params['query'],
                    limit: params['limit'],
                    offset: params['offset'],
                  ),
        ),
        'getPrescriptionDetails': _i1.MethodConnector(
          name: 'getPrescriptionDetails',
          params: {
            'prescriptionId': _i1.ParameterDescription(
              name: 'prescriptionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['doctor'] as _i10.DoctorEndpoint)
                  .getPrescriptionDetails(
                    session,
                    prescriptionId: params['prescriptionId'],
                  ),
        ),
      },
    );
    connectors['lab'] = _i1.EndpointConnector(
      name: 'lab',
      endpoint: endpoints['lab']!,
      methodConnectors: {
        'getAllLabTests': _i1.MethodConnector(
          name: 'getAllLabTests',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i11.LabEndpoint).getAllLabTests(
                session,
              ),
        ),
        'createTestResult': _i1.MethodConnector(
          name: 'createTestResult',
          params: {
            'testId': _i1.ParameterDescription(
              name: 'testId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'patientName': _i1.ParameterDescription(
              name: 'patientName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'mobileNumber': _i1.ParameterDescription(
              name: 'mobileNumber',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'patientType': _i1.ParameterDescription(
              name: 'patientType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lab'] as _i11.LabEndpoint).createTestResult(
                    session,
                    testId: params['testId'],
                    patientName: params['patientName'],
                    mobileNumber: params['mobileNumber'],
                    patientType: params['patientType'],
                  ),
        ),
        'createLabTest': _i1.MethodConnector(
          name: 'createLabTest',
          params: {
            'test': _i1.ParameterDescription(
              name: 'test',
              type: _i1.getType<_i18.LabTests>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i11.LabEndpoint).createLabTest(
                session,
                params['test'],
              ),
        ),
        'updateLabTest': _i1.MethodConnector(
          name: 'updateLabTest',
          params: {
            'test': _i1.ParameterDescription(
              name: 'test',
              type: _i1.getType<_i18.LabTests>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i11.LabEndpoint).updateLabTest(
                session,
                params['test'],
              ),
        ),
        'sendDummySms': _i1.MethodConnector(
          name: 'sendDummySms',
          params: {
            'mobileNumber': _i1.ParameterDescription(
              name: 'mobileNumber',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i11.LabEndpoint).sendDummySms(
                session,
                mobileNumber: params['mobileNumber'],
                message: params['message'],
              ),
        ),
        'submitResult': _i1.MethodConnector(
          name: 'submitResult',
          params: {
            'resultId': _i1.ParameterDescription(
              name: 'resultId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i11.LabEndpoint).submitResult(
                session,
                resultId: params['resultId'],
              ),
        ),
        'submitResultWithUrl': _i1.MethodConnector(
          name: 'submitResultWithUrl',
          params: {
            'resultId': _i1.ParameterDescription(
              name: 'resultId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'attachmentUrl': _i1.ParameterDescription(
              name: 'attachmentUrl',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lab'] as _i11.LabEndpoint).submitResultWithUrl(
                    session,
                    resultId: params['resultId'],
                    attachmentUrl: params['attachmentUrl'],
                  ),
        ),
        'getAllTestResults': _i1.MethodConnector(
          name: 'getAllTestResults',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i11.LabEndpoint)
                  .getAllTestResults(session),
        ),
        'getStaffProfile': _i1.MethodConnector(
          name: 'getStaffProfile',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i11.LabEndpoint).getStaffProfile(
                session,
              ),
        ),
        'updateStaffProfile': _i1.MethodConnector(
          name: 'updateStaffProfile',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'designation': _i1.ParameterDescription(
              name: 'designation',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'qualification': _i1.ParameterDescription(
              name: 'qualification',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'profilePictureUrl': _i1.ParameterDescription(
              name: 'profilePictureUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lab'] as _i11.LabEndpoint).updateStaffProfile(
                    session,
                    name: params['name'],
                    phone: params['phone'],
                    email: params['email'],
                    designation: params['designation'],
                    qualification: params['qualification'],
                    profilePictureUrl: params['profilePictureUrl'],
                  ),
        ),
        'getLabHomeTwoDaySummary': _i1.MethodConnector(
          name: 'getLabHomeTwoDaySummary',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i11.LabEndpoint)
                  .getLabHomeTwoDaySummary(session),
        ),
        'getLast10TestHistory': _i1.MethodConnector(
          name: 'getLast10TestHistory',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i11.LabEndpoint)
                  .getLast10TestHistory(session),
        ),
      },
    );
    connectors['patient'] = _i1.EndpointConnector(
      name: 'patient',
      endpoint: endpoints['patient']!,
      methodConnectors: {
        'getPatientProfile': _i1.MethodConnector(
          name: 'getPatientProfile',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getPatientProfile(session),
        ),
        'listTests': _i1.MethodConnector(
          name: 'listTests',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .listTests(session),
        ),
        'getUserRole': _i1.MethodConnector(
          name: 'getUserRole',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getUserRole(session),
        ),
        'updatePatientProfile': _i1.MethodConnector(
          name: 'updatePatientProfile',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'bloodGroup': _i1.ParameterDescription(
              name: 'bloodGroup',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'dateOfBirth': _i1.ParameterDescription(
              name: 'dateOfBirth',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'gender': _i1.ParameterDescription(
              name: 'gender',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'profileImageUrl': _i1.ParameterDescription(
              name: 'profileImageUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .updatePatientProfile(
                    session,
                    params['name'],
                    params['phone'],
                    params['bloodGroup'],
                    params['dateOfBirth'],
                    params['gender'],
                    params['profileImageUrl'],
                  ),
        ),
        'getMyLabReports': _i1.MethodConnector(
          name: 'getMyLabReports',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getMyLabReports(session),
        ),
        'getMyPrescriptionList': _i1.MethodConnector(
          name: 'getMyPrescriptionList',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getMyPrescriptionList(session),
        ),
        'finalizeReportUpload': _i1.MethodConnector(
          name: 'finalizeReportUpload',
          params: {
            'prescriptionId': _i1.ParameterDescription(
              name: 'prescriptionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'reportType': _i1.ParameterDescription(
              name: 'reportType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'fileUrl': _i1.ParameterDescription(
              name: 'fileUrl',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .finalizeReportUpload(
                    session,
                    prescriptionId: params['prescriptionId'],
                    reportType: params['reportType'],
                    fileUrl: params['fileUrl'],
                  ),
        ),
        'getMyExternalReports': _i1.MethodConnector(
          name: 'getMyExternalReports',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getMyExternalReports(session),
        ),
        'getPrescriptionList': _i1.MethodConnector(
          name: 'getPrescriptionList',
          params: {
            'patientId': _i1.ParameterDescription(
              name: 'patientId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getPrescriptionList(
                    session,
                    params['patientId'],
                  ),
        ),
        'getPrescriptionsByPatientId': _i1.MethodConnector(
          name: 'getPrescriptionsByPatientId',
          params: {
            'patientId': _i1.ParameterDescription(
              name: 'patientId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getPrescriptionsByPatientId(
                    session,
                    params['patientId'],
                  ),
        ),
        'getPrescriptionDetail': _i1.MethodConnector(
          name: 'getPrescriptionDetail',
          params: {
            'prescriptionId': _i1.ParameterDescription(
              name: 'prescriptionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getPrescriptionDetail(
                    session,
                    params['prescriptionId'],
                  ),
        ),
        'getMedicalStaff': _i1.MethodConnector(
          name: 'getMedicalStaff',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getMedicalStaff(session),
        ),
        'getAmbulanceContacts': _i1.MethodConnector(
          name: 'getAmbulanceContacts',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getAmbulanceContacts(session),
        ),
        'getOndutyStaff': _i1.MethodConnector(
          name: 'getOndutyStaff',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i12.PatientEndpoint)
                  .getOndutyStaff(session),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i13.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
  }
}
