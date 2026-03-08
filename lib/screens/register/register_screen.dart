import 'package:app/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_preferences.dart';
import '../../services/notification_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _minINRController = TextEditingController();
  final _maxINRController = TextEditingController();
  final _warfarinDoseController = TextEditingController();
  String? _selectedGender;
  String? _selectedValveType;
  String? _selectedValvePosition;
  TimeOfDay? _selectedDoseTime;
  bool _isLoadingData = true;
  // Lock flags – true when the backend already has a value
  bool _valveTypeLocked = false;
  bool _valvePositionLocked = false;
  bool _inrLocked = false;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _isLoadingData = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$baseURL/api/patient/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _ageController.text = (data['age'] ?? '').toString();
          _weightController.text = (data['weight'] ?? '').toString();
          _selectedGender = data['gender'];
          _selectedValveType = data['valveType'];
          _selectedValvePosition = data['valvePosition'];
          _minINRController.text = (data['inrMin'] ?? '').toString();
          _maxINRController.text = (data['inrMax'] ?? '').toString();
          _valveTypeLocked = data['valveType'] != null;
          _valvePositionLocked = data['valvePosition'] != null;
          final inrMin = (data['inrMin'] as num?)?.toDouble() ?? 0.0;
          final inrMax = (data['inrMax'] as num?)?.toDouble() ?? 0.0;
          _inrLocked = inrMin != 0.0 && inrMax != 0.0;
          _warfarinDoseController.text = (data['warfarine'] ?? '').toString();
          // Parse warfarineTime e.g. "21:25:00"
          if (data['warfarineTime'] != null) {
            final parts = (data['warfarineTime'] as String).split(':');
            if (parts.length >= 2) {
              _selectedDoseTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 0,
                minute: int.tryParse(parts[1]) ?? 0,
              );
            }
          }
          _isLoadingData = false;
        });
      } else {
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _minINRController.dispose();
    _maxINRController.dispose();
    _warfarinDoseController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedDoseTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedDoseTime) {
      setState(() {
        _selectedDoseTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '12:30';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeForAPI(TimeOfDay? time) {
    if (time == null) return '12:30:00';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  bool _validateForm() {
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your full name');
      return false;
    }
    if (_ageController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your age');
      return false;
    }
    if (_weightController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your weight');
      return false;
    }
    if (_selectedGender == null) {
      _showErrorDialog('Please select your gender');
      return false;
    }
    if (_selectedValveType == null) {
      _showErrorDialog('Please select valve type');
      return false;
    }
    if (_selectedValvePosition == null) {
      _showErrorDialog('Please select valve position');
      return false;
    }
    if (_minINRController.text.trim().isEmpty) {
      _showErrorDialog('Please enter minimum INR');
      return false;
    }
    if (_maxINRController.text.trim().isEmpty) {
      _showErrorDialog('Please enter maximum INR');
      return false;
    }
    if (_warfarinDoseController.text.trim().isEmpty) {
      _showErrorDialog('Please enter warfarin dose');
      return false;
    }
    if (_selectedDoseTime == null) {
      _showErrorDialog('Please select warfarin dose time');
      return false;
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _updateAccount() async {
    if (!_validateForm()) return;

    _showLoadingDialog();

    try {
      // Get user ID from SharedPreferences
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('User ID not found. Please login again.');
        return;
      }

      // Prepare the payload
      final payload = {
        'fullName': _fullNameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'weight': double.parse(_weightController.text.trim()),
        'gender': _selectedGender,
        'valveType': _selectedValveType,
        'valvePosition': _selectedValvePosition,
        'inrMax': double.parse(_maxINRController.text.trim()),
        'inrMin': double.parse(_minINRController.text.trim()),
        'warfarine': double.parse(_warfarinDoseController.text.trim()),
        'warfarineTime': _formatTimeForAPI(_selectedDoseTime),
      };

      print('Updating patient data for userId: $userId');
      print('Payload: $payload');

      // Make the PUT request
      final response = await http.put(
        Uri.parse('$baseURL/api/patient/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Success - save warfarin dose time locally
        await UserPreferences.saveWarfarinDoseTime(
          _formatTimeForAPI(_selectedDoseTime),
        );

        // Schedule notifications (service already initialized in main.dart)
        final warfarinTimeForNotif = _formatTime(_selectedDoseTime);
        final notificationService = NotificationService();
        await notificationService.scheduleWarfarinReminders(
          warfarinTimeForNotif,
        );
        print('Notifications scheduled for: $warfarinTimeForNotif');

        // Navigate to dashboard
        if (!mounted) return;
        // Mark registration as done so future logins skip this screen
        await UserPreferences.setRegistrationCompleted();
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Show error message
        _showErrorDialog(
          'Failed to update account: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      print('Error updating account: $e');
      _showErrorDialog('An error occurred: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBF0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2B7EF8),
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Update Account',
          style: TextStyle(
            color: Color(0xFF1A3B5D),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Personal Information Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3B5D),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Full Name
                        const Text(
                          'Full Name *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3B5D),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your full name',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Age and Weight Row
                        Row(
                          children: [
                            // Age Field
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Age *',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A3B5D),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      controller: _ageController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Age',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 16,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Weight Field
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Weight (kg) *',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A3B5D),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      controller: _weightController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Weight',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 16,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Gender Dropdown
                        const Text(
                          'Gender *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3B5D),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              hint: const Text(
                                'Select gender',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 16,
                                ),
                              ),
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFF9CA3AF),
                              ),
                              items: ['Male', 'Female', 'Other'].map((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedGender = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Medical Information Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3B5D),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Valve Type Dropdown
                        Row(
                          children: [
                            const Text(
                              'Valve Type *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A3B5D),
                              ),
                            ),
                            if (_valveTypeLocked) ...const [
                              SizedBox(width: 8),
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: _valveTypeLocked
                                ? const Color(0xFFE9ECEF)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: _valveTypeLocked
                                ? Border.all(color: const Color(0xFFD1D5DB))
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedValveType,
                              hint: const Text(
                                'Select valve type',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 16,
                                ),
                              ),
                              isExpanded: true,
                              icon: Icon(
                                _valveTypeLocked
                                    ? Icons.lock_outline
                                    : Icons.keyboard_arrow_down,
                                color: const Color(0xFF9CA3AF),
                                size: 18,
                              ),
                              items: ['Mechanical'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      color: _valveTypeLocked
                                          ? const Color(0xFF6B7280)
                                          : const Color(0xFF1A3B5D),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: _valveTypeLocked
                                  ? null
                                  : (String? newValue) {
                                      setState(() {
                                        _selectedValveType = newValue;
                                      });
                                    },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Valve Position Dropdown
                        Row(
                          children: [
                            const Text(
                              'Valve Position *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A3B5D),
                              ),
                            ),
                            if (_valvePositionLocked) ...const [
                              SizedBox(width: 8),
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: _valvePositionLocked
                                ? const Color(0xFFE9ECEF)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: _valvePositionLocked
                                ? Border.all(color: const Color(0xFFD1D5DB))
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedValvePosition,
                              hint: const Text(
                                'Select valve position',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 16,
                                ),
                              ),
                              isExpanded: true,
                              icon: Icon(
                                _valvePositionLocked
                                    ? Icons.lock_outline
                                    : Icons.keyboard_arrow_down,
                                color: const Color(0xFF9CA3AF),
                                size: 18,
                              ),
                              items: ['Aortic', 'Mitral'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      color: _valvePositionLocked
                                          ? const Color(0xFF6B7280)
                                          : const Color(0xFF1A3B5D),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: _valvePositionLocked
                                  ? null
                                  : (String? newValue) {
                                      setState(() {
                                        _selectedValvePosition = newValue;
                                        // Auto-fill INR range based on valve position
                                        if (newValue == 'Aortic') {
                                          _minINRController.text = '2.0';
                                          _maxINRController.text = '3.0';
                                        } else if (newValue == 'Mitral') {
                                          _minINRController.text = '2.5';
                                          _maxINRController.text = '3.5';
                                        }
                                      });
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Warfarin Information Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Warfarin Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3B5D),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Target INR Range
                        Row(
                          children: [
                            const Text(
                              'Target INR Range *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A3B5D),
                              ),
                            ),
                            if (_inrLocked) ...const [
                              SizedBox(width: 8),
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            // Min INR
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _inrLocked
                                      ? const Color(0xFFE9ECEF)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: _inrLocked
                                      ? Border.all(
                                          color: const Color(0xFFD1D5DB),
                                        )
                                      : null,
                                ),
                                child: TextField(
                                  controller: _minINRController,
                                  readOnly: _inrLocked,
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: TextStyle(
                                    color: _inrLocked
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF1A3B5D),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Min (e.g., 2.0)',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Max INR
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _inrLocked
                                      ? const Color(0xFFE9ECEF)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: _inrLocked
                                      ? Border.all(
                                          color: const Color(0xFFD1D5DB),
                                        )
                                      : null,
                                ),
                                child: TextField(
                                  controller: _maxINRController,
                                  readOnly: _inrLocked,
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: TextStyle(
                                    color: _inrLocked
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF1A3B5D),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Max (e.g., 3.0)',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Prescribed Warfarin Dose
                        const Text(
                          'Prescribed Warfarin Dose (mg) *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3B5D),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _warfarinDoseController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'e.g., 5.0',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Warfarin Dose Time
                        const Text(
                          'Warfarin Dose Time *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3B5D),
                          ),
                        ),

                        const SizedBox(height: 8),

                        InkWell(
                          onTap: () => _selectTime(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _formatTime(_selectedDoseTime),
                                  style: TextStyle(
                                    color: _selectedDoseTime == null
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF1A3B5D),
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF9CA3AF),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _updateAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B7EF8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Update Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isLoadingData)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF2B7EF8)),
              ),
            ),
        ],
      ),
    );
  }
}
