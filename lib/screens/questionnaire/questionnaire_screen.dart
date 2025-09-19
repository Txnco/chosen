import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chosen/models/questionnaire.dart';
import 'package:chosen/managers/questionnaire_manager.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 10;

  // Form controllers
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _morningRoutineController = TextEditingController();
  final _eveningRoutineController = TextEditingController();

  // Selection values
  String _trainingEnvironment = '';
  String _workShift = '';
  TimeOfDay? _wakeUpTime;
  TimeOfDay? _sleepTime;
  DateTime? _birthday;
  String _healthIssues = '';
  String _badHabits = '';

  @override
  void initState() {
    super.initState();
    _loadDraftData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _morningRoutineController.dispose();
    _eveningRoutineController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Calculate age from birthday
  int? get _calculatedAge {
    if (_birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - _birthday!.year;
    if (now.month < _birthday!.month || 
        (now.month == _birthday!.month && now.day < _birthday!.day)) {
      age--;
    }
    return age;
  }

  // Load draft data if available
  Future<void> _loadDraftData() async {
    try {
      // First, try to get questionnaire progress from API
      final progress = await QuestionnaireManager.getQuestionnaireProgress();
      
      if (progress != null) {
        final questionnaireData = progress['questionnaire_data'] as Map<String, dynamic>;
        final currentStep = progress['current_step'] as int;
        final isComplete = progress['is_complete'] as bool;
        
        if (isComplete) {
          // Questionnaire is complete, redirect to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
          return;
        }
        
        // Load data from API
        setState(() {
          _currentStep = currentStep;
          
          // Load text fields
          _weightController.text = questionnaireData['weight']?.toString() ?? '';
          _heightController.text = questionnaireData['height']?.toString() ?? '';
          _healthIssues = questionnaireData['healthIssues'] ?? '';
          _badHabits = questionnaireData['badHabits'] ?? '';
          _morningRoutineController.text = questionnaireData['morningRoutine'] ?? '';
          _eveningRoutineController.text = questionnaireData['eveningRoutine'] ?? '';
          
          // Load birthday directly from API
          if (questionnaireData['birthday'] != null) {
            _birthday = DateTime.parse(questionnaireData['birthday']);
          }
          
          // Load selection values
          _trainingEnvironment = questionnaireData['trainingEnvironment'] ?? '';
          _workShift = questionnaireData['workShift'] ?? '';
          
          // Load times
          if (questionnaireData['wakeUpTime'] != null) {
            final parts = questionnaireData['wakeUpTime'].split(':');
            _wakeUpTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          
          if (questionnaireData['sleepTime'] != null) {
            final parts = questionnaireData['sleepTime'].split(':');
            _sleepTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        });
        
        // Navigate to the current step
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.animateToPage(
            _currentStep,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
        
        return;
      }
      
      // Fallback to draft data if no API data exists
      final draftData = await QuestionnaireManager.getDraftQuestionnaire();
      final currentStep = await QuestionnaireManager.getCurrentStep();
      
      if (draftData != null) {
        setState(() {
          _currentStep = currentStep;
          
          // Load text fields
          _weightController.text = draftData['weight']?.toString() ?? '';
          _heightController.text = draftData['height']?.toString() ?? '';
          _healthIssues = draftData['healthIssues'] ?? '';
          _badHabits = draftData['badHabits'] ?? '';
          _morningRoutineController.text = draftData['morningRoutine'] ?? '';
          _eveningRoutineController.text = draftData['eveningRoutine'] ?? '';
          
          // Load birthday
          if (draftData['birthday'] != null) {
            _birthday = DateTime.parse(draftData['birthday']);
          }
          
          // Load selection values
          _trainingEnvironment = draftData['trainingEnvironment'] ?? '';
          _workShift = draftData['workShift'] ?? '';
          
          // Load times
          if (draftData['wakeUpTime'] != null) {
            final parts = draftData['wakeUpTime'].split(':');
            _wakeUpTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          
          if (draftData['sleepTime'] != null) {
            final parts = draftData['sleepTime'].split(':');
            _sleepTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        });
        
        // Navigate to the current step
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.animateToPage(
            _currentStep,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    } catch (e) {
      // Continue with empty form if both API and local data fail
    }
  }

  // Auto-save draft data
  Future<void> _saveDraftData() async {
    final data = {
      'weight': double.tryParse(_weightController.text),
      'height': double.tryParse(_heightController.text),
      'birthday': _birthday?.toIso8601String(), // Save birthday directly
      'healthIssues': _healthIssues,
      'badHabits': _badHabits,
      'trainingEnvironment': _trainingEnvironment,
      'workShift': _workShift,
      'wakeUpTime': _wakeUpTime != null 
      ? '${_wakeUpTime!.hour.toString().padLeft(2, '0')}:${_wakeUpTime!.minute.toString().padLeft(2, '0')}'
      : null,
      'sleepTime': _sleepTime != null
      ? '${_sleepTime!.hour.toString().padLeft(2, '0')}:${_sleepTime!.minute.toString().padLeft(2, '0')}'
      : null,
      'morningRoutine': _morningRoutineController.text,
      'eveningRoutine': _eveningRoutineController.text,
    };
    
    await QuestionnaireManager.saveDraftQuestionnaire(data, _currentStep);
  }

  // Validate current step
  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0: // Weight
        return _weightController.text.isNotEmpty && 
               double.tryParse(_weightController.text) != null &&
               double.parse(_weightController.text) > 0;
      case 1: // Height
        return _heightController.text.isNotEmpty && 
               double.tryParse(_heightController.text) != null &&
               double.parse(_heightController.text) > 0;
      case 2: // Birthday
        return _birthday != null;
      case 3: // Health Issues
        return _healthIssues.isNotEmpty;
      case 4: // Bad Habits
        return _badHabits.isNotEmpty;
      case 5: // Training Environment
        return _trainingEnvironment.isNotEmpty;
      case 6: // Work Shift
        return _workShift.isNotEmpty;
      case 7: // Wake Up Time
        return _wakeUpTime != null;
      case 8: // Sleep Time
        return _sleepTime != null;
      case 9: // Routines
        return _morningRoutineController.text.isNotEmpty && 
               _eveningRoutineController.text.isNotEmpty;
      default:
        return false;
    }
  }

  // Validate all steps and return first invalid step
  int? _getFirstInvalidStep() {
    for (int i = 0; i < _totalSteps; i++) {
      final currentStepBackup = _currentStep;
      _currentStep = i;
      if (!_isCurrentStepValid()) {
        _currentStep = currentStepBackup;
        return i;
      }
      _currentStep = currentStepBackup;
    }
    return null;
  }

  void _nextStep() {
    if (!_isCurrentStepValid()) {
      _showValidationError();
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Auto-save after each step
      _saveDraftData();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showValidationError() {
    String message = '';
    switch (_currentStep) {
      case 0:
        message = 'Please enter a valid weight';
        break;
      case 1:
        message = 'Please enter a valid height';
        break;
      case 2:
        message = 'Please select your birthday';
        break;
      case 3:
        message = 'Please describe any health issues (or enter "None" if none)';
        break;
      case 4:
        message = 'Please describe habits to improve (or enter "None" if none)';
        break;
      case 5:
        message = 'Please select your preferred training environment';
        break;
      case 6:
        message = 'Please select your work shift';
        break;
      case 7:
        message = 'Please select your wake-up time';
        break;
      case 8:
        message = 'Please select your sleep time';
        break;
      case 9:
        message = 'Please describe both your morning and evening routines';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitQuestionnaire() async {
    // Validate all steps first
    final invalidStep = _getFirstInvalidStep();
    if (invalidStep != null) {
      // Navigate to first invalid step
      setState(() {
        _currentStep = invalidStep;
      });
      _pageController.animateToPage(
        invalidStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _showValidationError();
      return;
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 16),
              Text('Saving questionnaire...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Create the questionnaire object
      final questionnaire = Questionnaire(
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        birthday: _birthday!, // Send birthday instead of age
        healthIssues: _healthIssues,
        badHabits: _badHabits,
        trainingEnvironment: _trainingEnvironment,
        workShift: _workShift,
        wakeUpTime: _wakeUpTime!,
        sleepTime: _sleepTime!,
        morningRoutine: _morningRoutineController.text,
        eveningRoutine: _eveningRoutineController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Complete questionnaire (save to backend and mark as completed)
      final success = await QuestionnaireManager.completeQuestionnaire(questionnaire);
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Questionnaire completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigate to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save questionnaire. Please try again.'  ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation - questionnaire must be completed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete the questionnaire to continue'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          title: const Text(
            'Health Questionnaire',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWeightStep(),
                  _buildHeightStep(),
                  _buildBirthdayStep(),
                  _buildHealthIssuesStep(),
                  _buildBadHabitsStep(),
                  _buildTrainingEnvironmentStep(),
                  _buildWorkShiftStep(),
                  _buildWakeUpTimeStep(),
                  _buildSleepTimeStep(),
                  _buildRoutinesStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionOptions({
    required List<String> options,
    List<String>? displayTexts,
    required String? selectedValue,
    required Function(String) onChanged,
  }) {
    final texts = displayTexts ?? options;
    
    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final displayText = texts[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onChanged(option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedValue == option ? Colors.black : Colors.grey[300]!,
                  width: selectedValue == option ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: selectedValue == option ? Colors.black.withOpacity(0.05) : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    selectedValue == option ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selectedValue == option ? Colors.black : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selectedValue == option ? FontWeight.w600 : FontWeight.w400,
                      color: selectedValue == option ? Colors.black : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildWeightStep() {
    return _buildStepContainer(
      title: 'Kolika je tvoja trenutna težina?',
      subtitle: 'Ovo nam pomaže da izračunamo tvoje dnevne kalorijske potrebe',
      child: _buildNumberInput(
        controller: _weightController,
        suffix: 'kg',
        hint: 'Unesi svoju težinu',
      ),
    );
  }

  Widget _buildHeightStep() {
    return _buildStepContainer(
      title: 'Kolika je tvoja trenutna visina?',
      subtitle: 'Ovo nam pomaže da izračunamo tvoj BMI',
      child: _buildNumberInput(
        controller: _heightController,
        suffix: 'cm',
        hint: 'Unesi svoju visinu',
      ),
    );
  }

  Widget _buildBirthdayStep() {
    return _buildStepContainer(
      title: 'Kada si rođen/rođena?',
      subtitle: 'Ovo nam pomaže da personalizujemo tvoj plan treninga',
      child: _buildDatePicker(
        selectedDate: _birthday,
        onDateSelected: (date) => setState(() => _birthday = date),
        hint: 'Odaberi datum rođenja',
      ),
    );
  }

  Widget _buildHealthIssuesStep() {
    return _buildStepContainer(
      title: 'Imate li zdravstvenih problema?',
      subtitle: 'Ovo nam pomaže da razumijemo tvoje zdravstveno stanje',
      child: _buildTextAreaInput(
        value: _healthIssues,
        onChanged: (value) => setState(() => _healthIssues = value),
        hint: 'npr., dijabetes, visoki krvni tlak, povrede... ili "Nema" ako nema',
      ),
    );
  }

  Widget _buildBadHabitsStep() {
    return _buildStepContainer(
      title: 'Imaš li kakvih navika za poboljšanje?',
      subtitle: 'Koje navike želiš promjeniti ili poboljšati?',
      child: _buildTextAreaInput(
        value: _badHabits,
        onChanged: (value) => setState(() => _badHabits = value),
        hint: 'npr., pušenje, prekomjerno vrijeme provedeno ispred ekrana, neredovito jedenje... ili "Nema" ako nema',
      ),
    );
  }

  Widget _buildTrainingEnvironmentStep() {
    final Map<String, String> trainingOptions = {
      'home': 'Kod kuće',
      'gym': 'Teretana',
      'outdoor': 'Na otvorenom',
      'both': 'Oboje',
    };

    return _buildStepContainer(
      title: 'Gdje preferiraš trenirati?',
      subtitle: 'Ovo nam pomaže da preporučimo odgovarajuće treninge',
      child: _buildSelectionOptions(
        options: trainingOptions.keys.toList(),
        displayTexts: trainingOptions.values.toList(),
        selectedValue: _trainingEnvironment,
        onChanged: (value) => setState(() => _trainingEnvironment = value),
      ),
    );
  }

  Widget _buildWorkShiftStep() {
    final Map<String, String> workShiftOptions = {
      'morning': 'Jutarnja smjena',
      'afternoon': 'Popodnevna smjena', 
      'night': 'Noćna smjena',
      'split': 'Podjeljena smjena',
      'flexible': 'Fleksibilno',
    };

    return _buildStepContainer(
      title: 'Kakav je tvoj radni raspored?',
      subtitle: 'Ovo nam pomaže da planiramo vrijeme za treninge',
      child: _buildSelectionOptions(
        options: workShiftOptions.keys.toList(),
        displayTexts: workShiftOptions.values.toList(),
        selectedValue: _workShift,
        onChanged: (value) => setState(() => _workShift = value),
      ),
    );
  }

  Widget _buildWakeUpTimeStep() {
    return _buildStepContainer(
      title: 'Kada se budiš?',
      subtitle: 'Ovo nam pomaže da planiramo tvoju jutarnju rutinu',
      child: _buildTimePicker(
        selectedTime: _wakeUpTime,
        onTimeSelected: (time) => setState(() => _wakeUpTime = time),
        hint: 'Odaberi vrijeme buđenja',
      ),
    );
  }

  Widget _buildSleepTimeStep() {
    return _buildStepContainer(
      title: 'Kada ideš spavati?',
      subtitle: 'Ovo nam pomaže da planiramo tvoju večernju rutinu',
      child: _buildTimePicker(
        selectedTime: _sleepTime,
        onTimeSelected: (time) => setState(() => _sleepTime = time),
        hint: 'Odaberi vrijeme spavanja',
      ),
    );
  }

  Widget _buildRoutinesStep() {
    return _buildStepContainer(
      title: 'Opišite vaše rutine',
      subtitle: 'Kako izgleda tipičan dan - jutro i večer?',
      child: Column(
        children: [
          _buildTextAreaInput(
            value: _morningRoutineController.text,
            onChanged: (value) => _morningRoutineController.text = value,
            hint: 'Opišite jutarnju rutinu...',
            label: 'Jutarnja rutina',
          ),
          const SizedBox(height: 24),
          _buildTextAreaInput(
            value: _eveningRoutineController.text,
            onChanged: (value) => _eveningRoutineController.text = value,
            hint: 'Opišite večernju rutinu...',
            label: 'Večernja rutina',
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String suffix,
    required String hint,
    bool isInteger = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
        inputFormatters: isInteger 
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        onChanged: (_) => _saveDraftData(),
        decoration: InputDecoration(
          hintText: hint,
          suffixText: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixStyle: TextStyle(color: Colors.grey[600]),
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextAreaInput({
    required String value,
    required Function(String) onChanged,
    required String hint,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            onChanged: onChanged,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 16),
            controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    required String hint,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
        );
        if (date != null) {
          onDateSelected(date);
          _saveDraftData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              selectedDate != null 
                ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                : hint,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: selectedDate != null ? Colors.black : Colors.grey[500],
              ),
            ),
            if (selectedDate != null) ...[
              const Spacer(),
              Text(
                '${_calculatedAge} godina',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method for 24-hour time picker
  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
  }

  Widget _buildTimePicker({
    required TimeOfDay? selectedTime,
    required Function(TimeOfDay) onTimeSelected,
    required String hint,
  }) {
    return InkWell(
      onTap: () async {
        final now = TimeOfDay.now();
        final picked = await _pickTime(context, selectedTime ?? now);
        if (picked != null) {
          onTimeSelected(picked);
          _saveDraftData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              selectedTime != null 
                ? _format24Hour(selectedTime) // Use 24-hour format display
                : hint,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: selectedTime != null ? Colors.black : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format time in 24-hour format
  String _format24Hour(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildNavigationButtons() {
    final isValid = _isCurrentStepValid();
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text(
                  'Nazad',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1 
                ? _submitQuestionnaire 
                : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Always black
                disabledBackgroundColor: Colors.grey[400], // Gray when disabled
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Završi' : 'Sljedeće',
                style: TextStyle(
                  color: isValid ? Colors.white : Colors.grey[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}