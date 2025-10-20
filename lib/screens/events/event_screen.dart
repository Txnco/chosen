// lib/screens/events/event_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:chosen/controllers/events_controller.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/models/events.dart';
import 'package:chosen/models/user.dart';
import 'package:intl/intl.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final _userController = UserController();
  CalendarFormat _calendarFormat = CalendarFormat.month;
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
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);
      
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
        _selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadEvents();
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Želite li obrisati događaj "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kalendar',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadEvents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [
                _buildCalendar(),
                const Divider(height: 1),
                Expanded(child: _buildEventList()),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: _onPageChanged,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nema događaja za ovaj dan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: isRepeating ? Colors.purple : Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isRepeating)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.repeat,
                                  size: 12,
                                  color: Colors.purple[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getRepeatLabel(event.repeatType),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          event.allDay
                              ? 'Cijeli dan'
                              : '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteEvent(event),
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.black),
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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.black),
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
    return Dialog(
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Naslov',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  decoration: InputDecoration(
                    labelText: 'Opis (opcionalno)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Cijeli dan'),
                  value: _allDay,
                  onChanged: (value) => setState(() => _allDay = value),
                  activeColor: Colors.black,
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            DateFormat('dd.MM.yyyy').format(_startTime),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              DateFormat('HH:mm').format(_startTime),
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            DateFormat('dd.MM.yyyy').format(_endTime),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              DateFormat('HH:mm').format(_endTime),
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
                  decoration: InputDecoration(
                    labelText: 'Ponavljanje',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                              colorScheme: const ColorScheme.light(primary: Colors.black),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _repeatUntil != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _repeatUntil = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _repeatUntil != null
                            ? DateFormat('dd.MM.yyyy').format(_repeatUntil!)
                            : 'Odaberi datum',
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
                      child: const Text(
                        'Odustani',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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