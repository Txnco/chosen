
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
  final _ageController = TextEditingController();
  final _healthIssuesController = TextEditingController();
  final _badHabitsController = TextEditingController();
  final _morningRoutineController = TextEditingController();
  final _eveningRoutineController = TextEditingController();

  // Selection values
  String _trainingEnvironment = '';
  String _workShift = '';
  TimeOfDay? _wakeUpTime;
  TimeOfDay? _sleepTime;

  @override
  void initState() {
    super.initState();
    _loadDraftData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _healthIssuesController.dispose();
    _badHabitsController.dispose();
    _morningRoutineController.dispose();
    _eveningRoutineController.dispose();
    _pageController.dispose();
    super.dispose();
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
          _ageController.text = questionnaireData['age']?.toString() ?? '';
          _healthIssuesController.text = questionnaireData['healthIssues'] ?? '';
          _badHabitsController.text = questionnaireData['badHabits'] ?? '';
          _morningRoutineController.text = questionnaireData['morningRoutine'] ?? '';
          _eveningRoutineController.text = questionnaireData['eveningRoutine'] ?? '';
          
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
          _ageController.text = draftData['age']?.toString() ?? '';
          _healthIssuesController.text = draftData['healthIssues'] ?? '';
          _badHabitsController.text = draftData['badHabits'] ?? '';
          _morningRoutineController.text = draftData['morningRoutine'] ?? '';
          _eveningRoutineController.text = draftData['eveningRoutine'] ?? '';
          
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
      'age': int.tryParse(_ageController.text),
      'healthIssues': _healthIssuesController.text,
      'badHabits': _badHabitsController.text,
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

  void _nextStep() {
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

  Future<void> _submitQuestionnaire() async {
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
        weight: double.tryParse(_weightController.text) ?? 0.0,
        height: double.tryParse(_heightController.text) ?? 0.0,
        age: int.tryParse(_ageController.text) ?? 0,
        healthIssues: _healthIssuesController.text,
        badHabits: _badHabitsController.text,
        trainingEnvironment: _trainingEnvironment,
        workShift: _workShift,
        wakeUpTime: _wakeUpTime ?? const TimeOfDay(hour: 7, minute: 0), // Default to 7:00 AM
        sleepTime: _sleepTime ?? const TimeOfDay(hour: 23, minute: 0),
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
              content: Text('Failed to save questionnaire. Please try again.'),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // Save draft before leaving
            _saveDraftData();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Health Questionnaire',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () async {
                // Save and continue later
                await _saveDraftData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Progress saved! You can continue later.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              },
              child: const Text(
                'Save & Exit',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
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
                _buildAgeStep(),
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
  required String? selectedValue, // Changed to nullable
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

  Widget _buildAgeStep() {
    return _buildStepContainer(
      title: 'Koliko imaš godina?',
      subtitle: 'Ovo nam pomaže da personalizujemo tvoj plan treninga',
      child: _buildNumberInput(
        controller: _ageController,
        suffix: 'years',
        hint: 'Unesi svoje godine',
        isInteger: true,
      ),
    );
  }

  Widget _buildHealthIssuesStep() {
    return _buildStepContainer(
      title: 'Imate li zdravstvenih problema?',
      subtitle: 'Ovo nam pomaže da razumijemo tvoje zdravstveno stanje',
      child: _buildTextAreaInput(
        controller: _healthIssuesController,
        hint: 'npr., dijabetes, visoki krvni tlak, povrede...',
      ),
    );
  }

  Widget _buildBadHabitsStep() {
    return _buildStepContainer(
      title: 'Imaš li kakvih navika za poboljšanje?',
      subtitle: 'Koje navike želiš promjeniti ili poboljšati?',
      child: _buildTextAreaInput(
        controller: _badHabitsController,
        hint: 'npr., pušenje, prekomjereno vrijeme provedeno ispred ekrana, neredovito jedenje...',
      ),
    );
  }

  Widget _buildTrainingEnvironmentStep() {
    // Define enum-like values and their display text
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
        options: trainingOptions.keys.toList(), // ['home', 'gym', 'outdoor', 'both']
        displayTexts: trainingOptions.values.toList(), // ['Kod kuće', 'Teretana', 'Na otvorenom', 'Oboje']
        selectedValue: _trainingEnvironment,
        onChanged: (value) => setState(() => _trainingEnvironment = value),
      ),
    );
  }

  Widget _buildWorkShiftStep() {
    // Define enum-like values and their display text
    final Map<String, String> workShiftOptions = {
      'morning': 'Morning Shift',
      'afternoon': 'Afternoon Shift', 
      'night': 'Night Shift',
      'split': 'Split Shift',
      'flexible': 'Flexible',
    };

    return _buildStepContainer(
      title: 'What\'s your work schedule?',
      subtitle: 'This helps us plan your workout timing',
      child: _buildSelectionOptions(
        options: workShiftOptions.keys.toList(), // ['day_shift', 'night_shift', 'flexible', 'part_time']
        displayTexts: workShiftOptions.values.toList(), // ['Day Shift', 'Night Shift', 'Flexible', 'Part-time']
        selectedValue: _workShift,
        onChanged: (value) => setState(() => _workShift = value),
      ),
    );
  }

  Widget _buildWakeUpTimeStep() {
    return _buildStepContainer(
      title: 'When do you wake up?',
      subtitle: 'This helps us schedule your morning routine',
      child: _buildTimePicker(
        selectedTime: _wakeUpTime,
        onTimeSelected: (time) => setState(() => _wakeUpTime = time),
        hint: 'Select your wake-up time',
      ),
    );
  }

  Widget _buildSleepTimeStep() {
    return _buildStepContainer(
      title: 'When do you sleep?',
      subtitle: 'This helps us plan your evening routine',
      child: _buildTimePicker(
        selectedTime: _sleepTime,
        onTimeSelected: (time) => setState(() => _sleepTime = time),
        hint: 'Select your bedtime',
      ),
    );
  }

  Widget _buildRoutinesStep() {
    return _buildStepContainer(
      title: 'Tell us about your routines',
      subtitle: 'What does your typical morning and evening look like?',
      child: Column(
        children: [
          _buildTextAreaInput(
            controller: _morningRoutineController,
            hint: 'Describe your morning routine...',
            label: 'Morning Routine',
          ),
          const SizedBox(height: 24),
          _buildTextAreaInput(
            controller: _eveningRoutineController,
            hint: 'Describe your evening routine...',
            label: 'Evening Routine',
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
          onChanged: (_) => _saveDraftData(), // Auto-save on text change
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
    required TextEditingController controller,
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
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

 

  Widget _buildTimePicker({
    required TimeOfDay? selectedTime,
    required Function(TimeOfDay) onTimeSelected,
    required String hint,
  }) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
        );
        if (time != null) {
          onTimeSelected(time);
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
                ? selectedTime.format(context)
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

  Widget _buildNavigationButtons() {
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
                  'Previous',
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
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Complete' : 'Next',
                style: const TextStyle(
                  color: Colors.white,
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
