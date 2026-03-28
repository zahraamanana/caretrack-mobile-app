import 'dart:async';

import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/patient.dart';
import '../repositories/patient_repository.dart';
import '../services/app_language_service.dart';
import '../services/notification_service.dart';
import '../services/patient_storage_service.dart';
import '../widgets/language_selector_button.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailsScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late Patient _patient;
  late List<bool> _taskCompletion;
  late final TextEditingController _bpController;
  late final TextEditingController _hrController;
  late final TextEditingController _tempController;
  late final TextEditingController _spo2Controller;
  late final TextEditingController _newTaskTitleController;
  late final TextEditingController _newTaskDueTimeController;
  final GlobalKey<FormState> _addTaskFormKey = GlobalKey<FormState>();
  late String _savedVitalSigns;
  String? _lastSavedAt;
  bool _isAddingTask = false;
  bool _isSavingTask = false;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _taskCompletion = List<bool>.filled(
      _patient.medicationTasks.length,
      false,
    );

    final vitalMap = _parseVitalSigns(_patient.vitalSigns);
    _bpController = TextEditingController(text: vitalMap['BP'] ?? '');
    _hrController = TextEditingController(text: vitalMap['HR'] ?? '');
    _tempController = TextEditingController(text: vitalMap['Temp'] ?? '');
    _spo2Controller = TextEditingController(text: vitalMap['SpO2'] ?? '');
    _newTaskTitleController = TextEditingController();
    _newTaskDueTimeController = TextEditingController();
    _savedVitalSigns = _patient.vitalSigns;
    _loadSavedTasks();
    _loadSavedVitalSigns();
  }

  @override
  void dispose() {
    _bpController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    _newTaskTitleController.dispose();
    _newTaskDueTimeController.dispose();
    super.dispose();
  }

  Map<String, String> _parseVitalSigns(String value) {
    final result = <String, String>{};
    for (final part in value.split(',')) {
      final trimmed = part.trim();
      if (trimmed.startsWith('BP ')) {
        result['BP'] = trimmed.replaceFirst('BP ', '');
      } else if (trimmed.startsWith('HR ')) {
        result['HR'] = trimmed.replaceFirst('HR ', '');
      } else if (trimmed.startsWith('Temp ')) {
        result['Temp'] = trimmed.replaceFirst('Temp ', '');
      } else if (trimmed.startsWith('SpO2 ')) {
        result['SpO2'] = trimmed.replaceFirst('SpO2 ', '');
      }
    }
    return result;
  }

  Future<void> _loadSavedVitalSigns() async {
    final l10n = AppLocalizations(
      AppLanguageService.instance.locale.languageCode,
    );
    final storedValue = await PatientStorageService.instance.loadVitalSigns(
      _patient.roomNumber,
    );

    if (storedValue == null || !mounted) return;

    final vitalMap = _parseVitalSigns(storedValue);
    setState(() {
      _savedVitalSigns = storedValue;
      _bpController.text = vitalMap['BP'] ?? '';
      _hrController.text = vitalMap['HR'] ?? '';
      _tempController.text = vitalMap['Temp'] ?? '';
      _spo2Controller.text = vitalMap['SpO2'] ?? '';
      _lastSavedAt = l10n.previouslySaved;
    });
  }

  Future<void> _loadSavedTasks() async {
    final storedValues = await PatientStorageService.instance.loadTaskCompletion(
      roomNumber: _patient.roomNumber,
      taskCount: _taskCompletion.length,
    );

    if (!mounted) return;

    setState(() {
      for (var i = 0; i < _taskCompletion.length; i++) {
        _taskCompletion[i] = storedValues[i];
      }
    });
  }

  Future<void> _saveTasks() async {
    await PatientStorageService.instance.saveTaskCompletion(
      roomNumber: _patient.roomNumber,
      values: _taskCompletion,
    );
  }

  Future<void> _saveVitalSigns() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final updatedValue =
        'BP ${_bpController.text.trim()}, '
        'HR ${_hrController.text.trim()}, '
        'Temp ${_tempController.text.trim()}, '
        'SpO2 ${_spo2Controller.text.trim()}';
    await PatientStorageService.instance.saveVitalSigns(
      roomNumber: _patient.roomNumber,
      value: updatedValue,
    );

    if (!mounted) return;

    setState(() {
      _savedVitalSigns = updatedValue;
      final now = TimeOfDay.now();
      _lastSavedAt =
          l10n.savedAt('${now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod}:${now.minute.toString().padLeft(2, "0")} ${now.period == DayPeriod.am ? "AM" : "PM"}');
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.vitalSaved),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddTaskSheet() {
    FocusScope.of(context).unfocus();
    _newTaskTitleController.clear();
    _newTaskDueTimeController.clear();
    setState(() {
      _isAddingTask = true;
      _isSavingTask = false;
    });
  }

  void _cancelAddTask() {
    FocusScope.of(context).unfocus();
    _newTaskTitleController.clear();
    _newTaskDueTimeController.clear();
    setState(() {
      _isAddingTask = false;
      _isSavingTask = false;
    });
  }

  Future<void> _submitAddTask() async {
    final l10n = AppLocalizations.of(context);
    if (!_addTaskFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSavingTask = true;
    });

    try {
      await _addMedicationTask(
        title: _newTaskTitleController.text.trim(),
        dueTime: _newTaskDueTimeController.text.trim(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSavingTask = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.taskSaveFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    _newTaskTitleController.clear();
    _newTaskDueTimeController.clear();
    setState(() {
      _isAddingTask = false;
      _isSavingTask = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.taskAdded),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addMedicationTask({
    required String title,
    required String dueTime,
  }) async {
    final previousPatient = _patient;
    final previousCompletion = List<bool>.from(_taskCompletion);
    final updatedTasks = List<MedicationTask>.from(_patient.medicationTasks)
      ..add(MedicationTask(title: title, dueTime: dueTime));
    final updatedCompletion = List<bool>.from(_taskCompletion)..add(false);
    final updatedPatient = _patient.copyWith(
      medicationTasks: updatedTasks,
      hasMedicationRound: true,
    );

    if (mounted) {
      setState(() {
        _patient = updatedPatient;
        _taskCompletion = updatedCompletion;
      });
    }

    try {
      await PatientRepository.instance.updatePatient(updatedPatient);
      await PatientStorageService.instance.saveTaskCompletion(
        roomNumber: updatedPatient.roomNumber,
        values: updatedCompletion,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _patient = previousPatient;
          _taskCompletion = previousCompletion;
        });
      }
      rethrow;
    }
  }

  Future<void> _confirmDeleteMedicationTask(int index) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteTask),
          content: Text(l10n.deleteTaskConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _deleteMedicationTask(index);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.taskSaveFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.taskDeleted),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteMedicationTask(int index) async {
    final previousPatient = _patient;
    final previousCompletion = List<bool>.from(_taskCompletion);
    final previousTaskCount = _patient.medicationTasks.length;
    final updatedTasks = List<MedicationTask>.from(_patient.medicationTasks)
      ..removeAt(index);
    final updatedCompletion = List<bool>.from(_taskCompletion)
      ..removeAt(index);
    final updatedPatient = _patient.copyWith(
      medicationTasks: updatedTasks,
      hasMedicationRound: updatedTasks.isNotEmpty,
    );

    if (mounted) {
      setState(() {
        _patient = updatedPatient;
        _taskCompletion = updatedCompletion;
      });
    }

    try {
      await PatientRepository.instance.updatePatient(updatedPatient);
      await PatientStorageService.instance.saveTaskCompletion(
        roomNumber: updatedPatient.roomNumber,
        values: updatedCompletion,
      );

      unawaited(
        NotificationService.instance.cancelPatientReminders(
          roomNumber: updatedPatient.roomNumber,
          taskCount: previousTaskCount,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _patient = previousPatient;
          _taskCompletion = previousCompletion;
        });
      }
      rethrow;
    }
  }

  Future<void> _sendMedicationReminderForTask(int index) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final scheduledFor = await NotificationService.instance
        .scheduleMedicationReminder(
      id: _patient.roomNumber.hashCode + index,
      patientName: _patient.name,
      taskTitle: _patient.medicationTasks[index].title,
      dueTime: _patient.medicationTasks[index].dueTime,
    );

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.reminderScheduled(_formatScheduledTime(scheduledFor))),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendTestMedicationNotification(int index) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    await NotificationService.instance.showMedicationReminder(
      id: (_patient.roomNumber.hashCode + index) * 100,
      patientName: _patient.name,
      taskTitle: _patient.medicationTasks[index].title,
      dueTime: _patient.medicationTasks[index].dueTime,
    );

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.testNotificationSent(
            l10n.patientText(_patient.medicationTasks[index].title),
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cancelMedicationReminderForTask(int index) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    await NotificationService.instance.cancelMedicationReminder(
      _patient.roomNumber.hashCode + index,
    );

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.reminderCancelled),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatScheduledTime(DateTime dateTime) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final isToday =
        now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        tomorrow.year == dateTime.year &&
        tomorrow.month == dateTime.month &&
        tomorrow.day == dateTime.day;

    final time = TimeOfDay.fromDateTime(dateTime);
    final formattedTime =
        '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, "0")} ${time.period == DayPeriod.am ? "AM" : "PM"}';

    if (isToday) return l10n.scheduledToday(formattedTime);
    if (isTomorrow) return l10n.scheduledTomorrow(formattedTime);
    return l10n.scheduledOnDate(dateTime, formattedTime);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const primaryColor = Color.fromARGB(255, 110, 101, 168);
    const accentColor = Color.fromARGB(255, 37, 101, 146);
    final completedTasks = _taskCompletion.where((task) => task).length;
    final hasMedicationTasks = _patient.medicationTasks.isNotEmpty;
    final firstPendingIndex = _taskCompletion.indexWhere((task) => !task);
    final reminderTaskIndex = hasMedicationTasks
        ? (firstPendingIndex == -1 ? 0 : firstPendingIndex)
        : -1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: l10n.isArabic
            ? null
            : IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
        title: Text(l10n.patientDetails),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const LanguageSelectorButton(iconColor: Colors.white),
          if (l10n.isArabic)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_forward_rounded),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFFE8EEFF),
                    child: Text(
                      _patient.firstLetter,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _patient.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(label: l10n.ageLabel(_patient.age)),
                      _InfoChip(
                        label: l10n.roomLabel(_patient.roomNumber),
                      ),
                      _InfoChip(
                        label: l10n.departmentFloorLabel(
                          _patient.department,
                          _patient.floor,
                        ),
                      ),
                      _InfoChip(
                        label: l10n.doctorLabel(_patient.doctorName),
                      ),
                      _StatusChip(
                        status: l10n.statusLabel(_patient.status),
                        statusColor: _patient.statusColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_patient.hasAlert) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.activeAlert,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _SectionCard(
              title: l10n.diagnosis,
              child: Text(
                l10n.localizedPatientValue(
                  englishValue: _patient.diagnosis,
                  arabicValue: _patient.diagnosisArabic,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: l10n.nursingNote,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localizedPatientValue(
                      englishValue: _patient.note,
                      arabicValue: _patient.noteArabic,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.localizedPatientValue(
                      englishValue: _patient.detail,
                      arabicValue: _patient.detailArabic,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: l10n.medicationTasks,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localizedPatientValue(
                      englishValue: _patient.medicationInfo,
                      arabicValue: _patient.medicationInfoArabic,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openAddTaskSheet,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_task_outlined),
                      label: Text(l10n.addMedicationTask),
                    ),
                  ),
                  if (_isAddingTask) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Form(
                        key: _addTaskFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.addMedicationTaskDescription,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _newTaskTitleController,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return l10n.enterTaskTitle;
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: l10n.taskTitle,
                                filled: true,
                                fillColor: const Color(0xFFF5F7FB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _newTaskDueTimeController,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submitAddTask(),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return l10n.enterDueTime;
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: l10n.dueTime,
                                hintText: l10n.exampleTime,
                                filled: true,
                                fillColor: const Color(0xFFF5F7FB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSavingTask
                                        ? null
                                        : _cancelAddTask,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(l10n.cancel),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSavingTask
                                        ? null
                                        : _submitAddTask,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _isSavingTask
                                          ? l10n.saving
                                          : l10n.saveTask,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    l10n.tasksCompleted(
                      completedTasks,
                      _patient.medicationTasks.length,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!hasMedicationTasks)
                    Text(
                      l10n.noMedicationTasks,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _sendTestMedicationNotification(
                                reminderTaskIndex,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: const BorderSide(color: primaryColor),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.bolt_outlined),
                              label: Text(l10n.sendTest),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _sendMedicationReminderForTask(
                                    reminderTaskIndex,
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.notifications_active_outlined,
                              ),
                              label: Text(l10n.schedule),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _cancelMedicationReminderForTask(reminderTaskIndex),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.notifications_off_outlined),
                          label: Text(l10n.cancelReminder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_patient.medicationTasks.length, (
                      index,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _taskCompletion[index],
                                activeColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _taskCompletion[index] = value ?? false;
                                  });
                                  _saveTasks();
                                },
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l10n.patientText(
                                              _patient.medicationTasks[index]
                                                  .title,
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                              decoration: _taskCompletion[index]
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _confirmDeleteMedicationTask(
                                                index,
                                              ),
                                          splashRadius: 18,
                                          tooltip: l10n.deleteTaskTooltip,
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.red.withValues(
                                              alpha: 0.80,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _TaskMetaChip(
                                          label: l10n.dueTimeLabel(
                                            _patient.medicationTasks[index]
                                                .dueTime,
                                          ),
                                          textColor: primaryColor,
                                          backgroundColor: const Color(
                                            0xFFE8EEFF,
                                          ),
                                        ),
                                        _TaskMetaChip(
                                          label: _taskCompletion[index]
                                              ? l10n.completed
                                              : l10n.pending,
                                          textColor: _taskCompletion[index]
                                              ? Colors.green
                                              : Colors.orange,
                                          backgroundColor:
                                              _taskCompletion[index]
                                              ? Colors.green.withValues(
                                                  alpha: 0.10,
                                                )
                                              : Colors.orange.withValues(
                                                  alpha: 0.12,
                                                ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: l10n.vitalSigns,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.currentSavedValues,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.vitalSignsValue(_savedVitalSigns),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  if (_lastSavedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _lastSavedAt!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _VitalField(
                          label: l10n.bloodPressure,
                          controller: _bpController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VitalField(
                          label: l10n.heartRate,
                          controller: _hrController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _VitalField(
                          label: l10n.temperature,
                          controller: _tempController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VitalField(
                          label: l10n.spo2,
                          controller: _spo2Controller,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveVitalSigns,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.saveVitalSigns,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 37, 101, 146),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 110, 101, 168),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color statusColor;

  const _StatusChip({required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(fontWeight: FontWeight.w600, color: statusColor),
      ),
    );
  }
}

class _VitalField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _VitalField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(
              color: Colors.black26,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskMetaChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _TaskMetaChip({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
