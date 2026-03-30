import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:backend_client/backend_client.dart';

import '../routing/route_refresh.dart';

class PatientAmbulanceStaff extends StatefulWidget {
  const PatientAmbulanceStaff({super.key});

  @override
  State<PatientAmbulanceStaff> createState() => _PatientAmbulanceStaffState();
}

class _PatientAmbulanceStaffState extends State<PatientAmbulanceStaff>
    with RouteRefreshMixin<PatientAmbulanceStaff> {
  final Color kPrimaryColor = const Color(0xFF00796B);

  late Future<List<StaffInfo>> _staff;
  late Future<List<AmbulanceContact>> _ambulances;

  @override
  void initState() {
    super.initState();
    _staff = client.patient.getMedicalStaff();
    _ambulances = client.patient.getAmbulanceContacts(); // fetch from backend
  }

  @override
  Future<void> refreshOnFocus() async {
    if (!mounted) return;
    setState(() {
      _staff = client.patient.getMedicalStaff();
      _ambulances = client.patient.getAmbulanceContacts();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber, String displayName) async {
    if (kIsWeb) {
      _showWebCallAlert(phoneNumber, displayName);
    } else {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch dialer for $phoneNumber")),
        );
      }
    }
  }

  void _showWebCallAlert(String phoneNumber, String displayName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.phone_disabled, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Text("Call Not Available"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cannot make calls from web browser.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              "Phone: $phoneNumber",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Please use this number on your mobile device.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          ElevatedButton(
            onPressed: () {
              _copyToClipboard(phoneNumber, displayName);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text(
              "Copy Number",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String phoneNumber, String displayName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied $phoneNumber to clipboard"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStaffTileFromModel(StaffInfo staff) {
    final bool hasNumber = staff.phone.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: kPrimaryColor.withOpacity(0.1),
          backgroundImage: staff.profilePictureUrl != null
              ? NetworkImage(staff.profilePictureUrl!)
              : null,
          child: staff.profilePictureUrl == null
              ? const Icon(Icons.person_outline, color: Colors.blueGrey)
              : null,
        ),
        title: Text(
          staff.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${staff.designation ?? 'Staff'}\nContact: ${staff.phone}",
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        isThreeLine: true,
        trailing: hasNumber
            ? IconButton(
                icon: Icon(
                  kIsWeb ? Icons.phone_disabled : Icons.call,
                  color: kPrimaryColor,
                ),
                onPressed: () {
                  if (kIsWeb) {
                    _showWebCallAlert(
                      staff.phone,
                      "${staff.name} - ${staff.designation ?? ''}",
                    );
                  } else {
                    _makePhoneCall(staff.phone, staff.name);
                  }
                },
              )
            : null,
      ),
    );
  }

  Widget _buildAmbulanceTile(AmbulanceContact contact) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          contact.contactTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Bangla: ${contact.phoneBn}\nEnglish: ${contact.phoneEn}",
          style: const TextStyle(fontSize: 14),
        ),
        trailing: IconButton(
          icon: Icon(
            kIsWeb ? Icons.phone_disabled : Icons.call,
            color: Colors.red.shade700,
          ),
          onPressed: () {
            final callNumber = contact.phoneEn.isNotEmpty
                ? contact.phoneEn
                : contact.phoneBn;
            if (kIsWeb) {
              _showWebCallAlert(callNumber, contact.contactTitle);
            } else {
              _makePhoneCall(callNumber, contact.contactTitle);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Ambulance & Staff Contact",
          style: TextStyle(color: Colors.blueAccent),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: refreshFromPull,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ambulance Section
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  "🚨 Emergency Ambulance Contact",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<AmbulanceContact>>(
                future: _ambulances,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Failed to load ambulance contacts",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final contacts = snapshot.data ?? [];
                  if (contacts.isEmpty) {
                    return const Center(
                      child: Text("No ambulance contacts available"),
                    );
                  }
                  return Column(
                    children: contacts.map(_buildAmbulanceTile).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Staff Section
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  "👨‍⚕️ Medical Staff",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<StaffInfo>>(
                future: _staff,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Failed to load medical staff",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final staffList = snapshot.data ?? [];
                  if (staffList.isEmpty) {
                    return const Center(child: Text("No staff available"));
                  }
                  return Column(
                    children: staffList.map(_buildStaffTileFromModel).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
