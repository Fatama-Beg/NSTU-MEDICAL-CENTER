import 'package:dishari/src/auth/change_password.dart';
import 'package:flutter/material.dart';
import 'package:dishari/src/notifications/notifications.dart';
// Admin imports
import 'package:dishari/src/admin/admin_profile.dart';
import 'package:dishari/src/admin/history_screen.dart';
import 'package:dishari/src/admin/inventory_management.dart';
import 'package:dishari/src/admin/reports_analytics.dart';
import 'package:dishari/src/admin/staff_rostering.dart';
import 'package:dishari/src/admin/user_management.dart';
import 'package:dishari/src/admin/admin_dashboard.dart';
import 'package:dishari/src/admin/admin_ambulance.dart';
import 'package:dishari/src/admin/admin_route_guard.dart';

// Doctor imports
import 'package:dishari/src/doctor/patient_records.dart';
import 'package:dishari/src/doctor/doctor_dashboard.dart';
import 'package:dishari/src/doctor/prescription_page.dart';
import 'package:dishari/src/doctor/doctor_profile.dart';
import 'package:dishari/src/doctor/doctor_route_guard.dart';

// Lab imports
import 'package:dishari/src/lab_test/lab_tester_home.dart';
import 'package:dishari/src/lab_test/lab_route_guard.dart';

// Dispenser imports
import 'package:dishari/src/dispenser/dispenser_dashboard.dart';
import 'package:dishari/src/dispenser/dispenser_profile.dart';
import 'package:dishari/src/dispenser/dispenser_route_guard.dart';

// Patient imports
import 'package:dishari/src/patient/patient_dashboard.dart';
import 'package:dishari/src/patient/patient_profile.dart';
import 'package:dishari/src/patient/patient_prescriptions.dart';
import 'package:dishari/src/patient/patient_report.dart';
import 'package:dishari/src/patient/patient_report_upload.dart';
import 'package:dishari/src/patient/patient_lab_test_availability.dart';
import 'package:dishari/src/patient/patient_ambulance_staff.dart';
import 'package:dishari/src/patient/patient_signup.dart';
import 'package:dishari/src/patient/patient_route_guard.dart';
import 'package:dishari/src/routing/authenticated_route_guard.dart';

// Login
import 'package:dishari/src/auth/universal_login.dart';
// Forgot password
import 'package:dishari/src/auth/forget_password.dart';
// Import from your existing backend_client package
import 'package:backend_client/backend_client.dart';
import 'package:dishari/src/routing/route_refresh.dart';

void main() {
  // Initialize Serverpod client before running app
  WidgetsFlutterBinding.ensureInitialized();
  initServerpodClient();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NSTU Medical Center',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Raleway',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      navigatorObservers: [appRouteObserver],
      routes: {
        // Main routes
        '/': (context) => const HomePage(),

        // Admin routes (grouped under /admin)
        '/admin': (context) => const AdminRouteGuard(child: AdminDashboard()),
        '/admin-dashboard': (context) =>
            const AdminRouteGuard(child: AdminDashboard()),
        '/admin/profile': (context) =>
            const AdminRouteGuard(child: AdminProfile()),
        '/admin/users': (context) =>
            const AdminRouteGuard(child: UserManagement()),
        '/admin/inventory': (context) =>
            const AdminRouteGuard(child: InventoryManagement()),
        '/admin/reports': (context) =>
            const AdminRouteGuard(child: ReportsAnalytics()),
        '/admin/history': (context) =>
            const AdminRouteGuard(child: HistoryScreen()),
        '/admin/roster': (context) =>
            const AdminRouteGuard(child: StaffRostering()),
        '/admin/ambulance': (context) =>
            const AdminRouteGuard(child: AdminAmbulance()),

        // Doctor routes (grouped under /doctor)
        '/doctor-dashboard': (context) =>
            const DoctorRouteGuard(child: DoctorDashboard()),
        '/doctor/profile': (context) =>
            const DoctorRouteGuard(child: ProfilePage()),
        '/doctor/patients': (context) =>
            const DoctorRouteGuard(child: PatientRecordsPage()),
        '/doctor/prescriptions': (context) =>
            const DoctorRouteGuard(child: PrescriptionPage()),

        // Dispenser routes (grouped under /dispenser)
        '/dispenser-dashboard': (context) =>
            const DispenserRouteGuard(child: DispenserDashboard()),
        '/dispenser/profile': (context) =>
            const DispenserRouteGuard(child: DispenserProfile()),

        // Lab tester routes (grouped under /lab)
        '/lab-dashboard': (context) =>
            const LabRouteGuard(child: LabTesterHome()),
        // Patient routes (grouped under /patient)
        '/patient': (context) => const PatientRouteGuard(
          child: PatientDashboard(name: '', email: ''),
        ),
        '/patient-dashboard': (context) => const PatientRouteGuard(
          child: PatientDashboard(name: '', email: ''),
        ),
        '/patient/profile': (context) =>
            const PatientRouteGuard(child: PatientProfilePage()),
        '/patient/prescriptions': (context) =>
            const PatientRouteGuard(child: PatientPrescriptions()),
        '/patient/reports': (context) =>
            const PatientRouteGuard(child: PatientReports()),
        '/patient/upload': (context) =>
            const PatientRouteGuard(child: PatientReportUpload()),
        '/patient/lab': (context) =>
            const PatientRouteGuard(child: PatientLabTestAvailability()),
        '/patient/ambulance': (context) =>
            const PatientRouteGuard(child: PatientAmbulanceStaff()),

        // Signup ,forgot password and change password
        '/signup': (context) => const PatientSignupPage(),
        '/patient-signup': (context) =>
            const PatientSignupPage(), // alias for links coming from login
        '/forgotpassword': (context) => const ForgetPassword(),
        '/change-password': (context) => const ChangePasswordPage(),

        //notifications
        '/notifications': (context) =>
            const AuthenticatedRouteGuard(child: Notifications()),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(child: Text("Page not found: ${settings.name}")),
        ),
      ),
    );
  }
}
