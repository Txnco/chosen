// lib/screens/events/event_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:chosen/controllers/events_controller.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/models/events.dart';
import 'package:chosen/models/user.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chosen/providers/theme_provider.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final _userController = UserController();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  bool _isLoading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadUser();
    _loadEvents();
  }

  Future<void> _loadUser() async {
    final user = await _userController.getStoredUser();
    setState(() {
      _user = user;
    });
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final startOfMonth = DateTime(_selectedDay!.year, _selectedDay!.month, 1);
      final endOfMonth = DateTime(_selectedDay!.year, _selectedDay!.month + 1, 0, 23, 59, 59);
      
      final events = await EventsController.getEvents(
        startDate: startOfMonth,
        endDate: endOfMonth,
        includeRepeating: true,
      );

      final Map<DateTime, List<Event>> eventMap = {};
      
      for (var event in events) {
        final dateKey = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        
        if (eventMap[dateKey] == null) {
          eventMap[dateKey] = [];
        }
        eventMap[dateKey]!.add(event);
      }

      setState(() {
        _events = eventMap;
        _selectedEvents = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju događaja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  void _previousDate() {
    setState(() {
      _selectedDay = _selectedDay!.subtract(const Duration(days: 1));
      _selectedEvents = _getEventsForDay(_selectedDay!);
    });
    // Reload events if we move to a different month
    if (_selectedDay!.month != _focusedDay.month) {
      _focusedDay = _selectedDay!;
      _loadEvents();
    }
  }

void _nextDate() {
  // Remove the restriction on future dates
  setState(() {
    _selectedDay = _selectedDay!.add(const Duration(days: 1));
    _selectedEvents = _getEventsForDay(_selectedDay!);
  });
  
  // Reload events if we move to a different month
  if (_selectedDay!.month != _focusedDay.month) {
    _focusedDay = _selectedDay!;
    _loadEvents();
  }
}

 void _selectDate() async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
      (themeProvider.themeMode == ThemeMode.system &&
          MediaQuery.of(context).platformBrightness == Brightness.dark);
  
  final picked = await showDatePicker(
    context: context,
    initialDate: _selectedDay!,
    firstDate: DateTime(2020),
    lastDate: DateTime(2030), // Changed from DateTime.now() to allow future dates
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: isDarkMode ? Colors.white : Colors.black,
            onPrimary: isDarkMode ? Colors.black : Colors.white,
            surface: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            onSurface: isDarkMode ? Colors.white : Colors.black,
          ),
          dialogBackgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        ),
        child: child!,
      );
    },
  );
  
  if (picked != null && picked != _selectedDay) {
    setState(() {
      _selectedDay = picked;
      _selectedEvents = _getEventsForDay(_selectedDay!);
    });
    // Reload events if we move to a different month
    if (_selectedDay!.month != _focusedDay.month) {
      _focusedDay = _selectedDay!;
      _loadEvents();
    }
  }
}

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Danas';
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'Jučer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showAddEventDialog() async {
    if (_user == null) return;
    
    await showDialog(
      context: context,
      builder: (context) => _EventDialog(
        selectedDate: _selectedDay ?? _focusedDay,
        userId: _user!.id,
        onSave: (event) async {
          try {
            await EventsController.createEvent(event);
            _loadEvents();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Događaj uspješno dodan!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Greška: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showEditEventDialog(Event event) async {
    if (_user == null) return;
    
    await showDialog(
      context: context,
      builder: (context) => _EventDialog(
        selectedDate: event.startTime,
        userId: _user!.id,
        event: event,
        onSave: (updatedEvent) async {
          try {
            await EventsController.updateEvent(event.id!, updatedEvent.toJson());
            _loadEvents();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Događaj uspješno ažuriran!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Greška: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Potvrda brisanja',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Želite li obrisati događaj "${event.title}"?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Odustani',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirm == true && event.id != null) {
      try {
        await EventsController.deleteEvent(event.id!);
        _loadEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Događaj obrisan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška pri brisanju: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kalendar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildEventList()),
                ],
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    // Remove the restriction on the forward button
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF2A2A2A) 
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousDate,
            icon: const Icon(Icons.chevron_left, size: 24),
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDate(_selectedDay!),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today, 
                    color: Theme.of(context).textTheme.bodySmall?.color, 
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _nextDate, // Always enabled now
            icon: const Icon(Icons.chevron_right, size: 24),
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    if (_selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nema događaja za ovaj dan',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        final event = _selectedEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    final timeFormat = DateFormat('HH:mm');
    final isRepeating = event.repeatType != 'none';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showEditEventDialog(event),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 70,
                decoration: BoxDecoration(
                  color: isRepeating
                      ? (isDark ? Colors.purple[300] : Colors.purple)
                      : (isDark ? Colors.blue[300] : Colors.blue),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        if (isRepeating)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.purple[900]?.withOpacity(0.3)
                                  : Colors.purple[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.repeat,
                                  size: 13,
                                  color: isDark
                                      ? Colors.purple[300]
                                      : Colors.purple[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getRepeatLabel(event.repeatType),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.purple[300]
                                        : Colors.purple[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time, 
                          size: 15, 
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.allDay
                              ? 'Cijeli dan'
                              : '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        event.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteEvent(event),
                iconSize: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRepeatLabel(String repeatType) {
    switch (repeatType) {
      case 'daily':
        return 'Dnevno';
      case 'weekly':
        return 'Tjedno';
      case 'monthly':
        return 'Mjesečno';
      case 'yearly':
        return 'Godišnje';
      default:
        return '';
    }
  }
}

class _EventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final int userId;
  final Event? event;
  final Function(Event) onSave;

  const _EventDialog({
    required this.selectedDate,
    required this.userId,
    this.event,
    required this.onSave,
  });

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startTime;
  late DateTime _endTime;
  late bool _allDay;
  late String _repeatType;
  DateTime? _repeatUntil;

  @override
  void initState() {
    super.initState();
    
    if (widget.event != null) {
      _titleController = TextEditingController(text: widget.event!.title);
      _descriptionController = TextEditingController(text: widget.event!.description);
      _startTime = widget.event!.startTime;
      _endTime = widget.event!.endTime;
      _allDay = widget.event!.allDay;
      _repeatType = widget.event!.repeatType;
      _repeatUntil = widget.event!.repeatUntil;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        9,
        0,
      );
      _endTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        10,
        0,
      );
      _allDay = false;
      _repeatType = 'none';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDarkMode ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _startTime.hour,
            _startTime.minute,
          );
        } else {
          _endTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _endTime.hour,
            _endTime.minute,
          );
        }
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: isDarkMode ? Colors.white : Colors.black,
              ),
              dialogBackgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = DateTime(
            _startTime.year,
            _startTime.month,
            _startTime.day,
            picked.hour,
            picked.minute,
          );
        } else {
          _endTime = DateTime(
            _endTime.year,
            _endTime.month,
            _endTime.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      if (_endTime.isBefore(_startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vrijeme završetka mora biti nakon početka'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final event = Event(
        id: widget.event?.id,
        userId: widget.userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        allDay: _allDay,
        repeatType: _repeatType,
        repeatUntil: _repeatUntil,
      );

      widget.onSave(event);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event == null ? 'Novi događaj' : 'Uredi događaj',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Naslov',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite naslov';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Opis (opcionalno)',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(
                    'Cijeli dan', 
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  value: _allDay,
                  onChanged: (value) => setState(() => _allDay = value),
                  activeColor: Theme.of(context).colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Datum početka',
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          child: Text(
                            DateFormat('dd.MM.yyyy').format(_startTime),
                            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ),
                      ),
                    ),
                    if (!_allDay) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Vrijeme',
                              labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                            child: Text(
                              DateFormat('HH:mm').format(_startTime),
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Datum završetka',
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          child: Text(
                            DateFormat('dd.MM.yyyy').format(_endTime),
                            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ),
                      ),
                    ),
                    if (!_allDay) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Vrijeme',
                              labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                            child: Text(
                              DateFormat('HH:mm').format(_endTime),
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _repeatType,
                  dropdownColor: Theme.of(context).cardColor,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Ponavljanje',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('Ne ponavlja se')),
                    DropdownMenuItem(value: 'daily', child: Text('Dnevno')),
                    DropdownMenuItem(value: 'weekly', child: Text('Tjedno')),
                    DropdownMenuItem(value: 'monthly', child: Text('Mjesečno')),
                    DropdownMenuItem(value: 'yearly', child: Text('Godišnje')),
                  ],
                  onChanged: (value) {
                    setState(() => _repeatType = value!);
                  },
                ),
                if (_repeatType != 'none') ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _repeatUntil ?? _startTime.add(const Duration(days: 30)),
                        firstDate: _startTime,
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: isDarkMode ? Colors.white : Colors.black,
                              ),
                              dialogBackgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _repeatUntil = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Ponavljaj do (opcionalno)',
                        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        suffixIcon: _repeatUntil != null
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear, 
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                onPressed: () => setState(() => _repeatUntil = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _repeatUntil != null
                            ? DateFormat('dd.MM.yyyy').format(_repeatUntil!)
                            : 'Odaberi datum',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Odustani',
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      child: const Text('Spremi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}