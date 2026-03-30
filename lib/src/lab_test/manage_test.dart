import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart'; // Ensure this matches your package name

import '../routing/route_refresh.dart';

class ManageTest extends StatefulWidget {
  const ManageTest({super.key});

  @override
  State<ManageTest> createState() => ManageTestState();
}

class ManageTestState extends State<ManageTest>
    with RouteRefreshMixin<ManageTest> {
  List<LabTests> _tests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Lifecycle error erate ektu deri kore call kora (Safe initialization)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData();
    });
  }

  @override
  Future<void> refreshOnFocus() async {
    await fetchData();
  }

  /// Create logic call
  Future<void> _handleCreate(LabTests test) async {
    try {
      bool success = await client.lab.createLabTest(test);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("New Test Created!")));
        }
        fetchData();
      }
    } catch (e) {
      debugPrint("Create Error: $e");
    }
  }

  /// Backend theke data load kora
  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await client.lab.getAllLabTests();
      setState(() {
        _tests = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load data: $e")));
      }
      setState(() => _isLoading = false);
    }
  }

  /// Update logic call (For Switch or Dialog Save)
  Future<void> _handleUpdate(LabTests test) async {
    try {
      // Backend pattern onujayi update call
      bool success = await client.lab.updateLabTest(test);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Action Successful")));
        }
        fetchData(); // List refresh kora
      } else {
        throw Exception("Update failed on server");
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Update Failed!")));
      }
      fetchData(); // Rollback UI by re-fetching
    }
  }

  void openTestDialog({LabTests? test}) {
    final isEdit = test != null;

    // Controllers with existing data if editing
    final nameCtrl = TextEditingController(text: test?.testName);
    final descCtrl = TextEditingController(text: test?.description);
    final studentFeeCtrl = TextEditingController(
      text: test?.studentFee.toString(),
    );
    final teacherFeeCtrl = TextEditingController(
      text: test?.teacherFee.toString(),
    );
    final outsideFeeCtrl = TextEditingController(
      text: test?.outsideFee.toString(),
    );

    bool available = test?.available ?? true;

    // Keep initial values for change detection (editable fields only)
    final String initialStudentFee = studentFeeCtrl.text;
    final String initialTeacherFee = teacherFeeCtrl.text;
    final String initialOutsideFee = outsideFeeCtrl.text;
    final bool initialAvailable = available;

    // Persisting error state for the dialog (must live outside the inner builder)
    String? nameError;
    String? descError;
    String? studentFeeError;
    String? teacherFeeError;
    String? outsideFeeError;

    // Validator that updates the error variables and triggers a UI update via provided setter
    bool validateAll(StateSetter setDialogState) {
      var ok = true;
      nameError = null;
      descError = null;
      studentFeeError = null;
      teacherFeeError = null;
      outsideFeeError = null;

      // Name & description are required (for create they must be provided; for edit they are readOnly but exist)
      if (!isEdit && nameCtrl.text.trim().isEmpty) {
        nameError = 'Test name is required';
        ok = false;
      }
      if (!isEdit && descCtrl.text.trim().isEmpty) {
        descError = 'Description is required';
        ok = false;
      }

      // Validate editable numeric fields
      if (studentFeeCtrl.text.trim().isEmpty) {
        studentFeeError = 'Student fee is required';
        ok = false;
      } else if (double.tryParse(studentFeeCtrl.text.trim()) == null) {
        studentFeeError = 'Enter a valid number';
        ok = false;
      }
      if (teacherFeeCtrl.text.trim().isEmpty) {
        teacherFeeError = 'Teacher fee is required';
        ok = false;
      } else if (double.tryParse(teacherFeeCtrl.text.trim()) == null) {
        teacherFeeError = 'Enter a valid number';
        ok = false;
      }
      if (outsideFeeCtrl.text.trim().isEmpty) {
        outsideFeeError = 'Outside fee is required';
        ok = false;
      } else if (double.tryParse(outsideFeeCtrl.text.trim()) == null) {
        outsideFeeError = 'Enter a valid number';
        ok = false;
      }

      setDialogState(() {});
      return ok;
    }

    // Check if any editable field changed compared to initial values
    bool hasChanges() {
      if (!isEdit) return true; // for create path we allow saving when valid
      if (studentFeeCtrl.text.trim() != initialStudentFee.trim()) return true;
      if (teacherFeeCtrl.text.trim() != initialTeacherFee.trim()) return true;
      if (outsideFeeCtrl.text.trim() != initialOutsideFee.trim()) return true;
      if (available != initialAvailable) return true;
      return false;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? "Update Lab Test" : "Add New Test"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name (read-only on edit)
                  TextField(
                    controller: nameCtrl,
                    readOnly: isEdit,
                    decoration: InputDecoration(
                      labelText: 'Test Name',
                      prefixIcon: const Icon(Icons.science, size: 20),
                      border: const OutlineInputBorder(),
                      errorText: nameError,
                    ),
                    onChanged: (_) => setDialogState(() => nameError = null),
                  ),
                  const SizedBox(height: 12),

                  // Description (read-only on edit)
                  TextField(
                    controller: descCtrl,
                    readOnly: isEdit,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description, size: 20),
                      border: const OutlineInputBorder(),
                      errorText: descError,
                    ),
                    onChanged: (_) => setDialogState(() => descError = null),
                  ),
                  const SizedBox(height: 12),

                  // Student Fee
                  TextField(
                    controller: studentFeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Student Fee (taka)',
                      prefixIcon: const Icon(Icons.person, size: 20),
                      border: const OutlineInputBorder(),
                      errorText: studentFeeError,
                    ),
                    onChanged: (_) => setDialogState(() {
                      studentFeeError = null;
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Teacher Fee
                  TextField(
                    controller: teacherFeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Teacher Fee (taka)',
                      prefixIcon: const Icon(Icons.school, size: 20),
                      border: const OutlineInputBorder(),
                      errorText: teacherFeeError,
                    ),
                    onChanged: (_) => setDialogState(() {
                      teacherFeeError = null;
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Outside Fee
                  TextField(
                    controller: outsideFeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Outside Fee (taka)',
                      prefixIcon: const Icon(Icons.public, size: 20),
                      border: const OutlineInputBorder(),
                      errorText: outsideFeeError,
                    ),
                    onChanged: (_) => setDialogState(() {
                      outsideFeeError = null;
                    }),
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Is Available?"),
                    value: available,
                    onChanged: (v) => setDialogState(() => available = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              // Save button: disabled in edit mode if no editable fields changed
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: (isEdit && !hasChanges())
                    ? null
                    : () {
                        // Validate fields and show inline errors if needed
                        final ok = validateAll(setDialogState);
                        if (!ok) return; // errors already displayed

                        final updatedTest = LabTests(
                          testName: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          studentFee: double.parse(studentFeeCtrl.text.trim()),
                          teacherFee: double.parse(teacherFeeCtrl.text.trim()),
                          outsideFee: double.parse(outsideFeeCtrl.text.trim()),
                          available: available,
                        );

                        if (isEdit) {
                          updatedTest.id = test.id;
                          _handleUpdate(updatedTest);
                        } else {
                          _handleCreate(updatedTest); // ✅ INSERT DATABASE
                        }

                        Navigator.pop(ctx);
                      },
                child: const Text(
                  "Save Changes",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Common Input Field Helper

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _tests.isEmpty
        ? const Center(child: Text("No Lab Tests Found"))
        : RefreshIndicator(
            onRefresh: fetchData,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _tests.length,
              itemBuilder: (context, index) {
                final t = _tests[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        "${index + 1}", // Serial Number (1, 2, 3...)
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      t.testName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "Student: ${t.studentFee} taka | Teacher: ${t.teacherFee} taka",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: t.available,
                          activeThumbColor: Colors.green,
                          activeTrackColor: Colors.greenAccent.withAlpha(
                            (0.3 * 255).round(),
                          ),
                          onChanged: (v) {
                            t.available = v;
                            _handleUpdate(t);
                          },
                        ),
                        const VerticalDivider(),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => openTestDialog(test: t),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }
}
