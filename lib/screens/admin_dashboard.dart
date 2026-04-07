import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/nurse.dart';
import '../models/patient.dart';
import '../providers/nurse_provider.dart';
import '../providers/patient_provider.dart';
import '../services/logger_service.dart';
import '../services/patient_translation_service.dart';
import '../utils/app_colors.dart';
import '../utils/patient_sync_feedback.dart';
import '../widgets/language_selector_button.dart';
import 'nurse_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _patientSearchController =
      TextEditingController();
  final TextEditingController _nurseSearchController = TextEditingController();
  String _patientQuery = '';
  String _nurseQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData(showPatientLoading: false);
    });
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _nurseSearchController.dispose();
    super.dispose();
  }

  void _onPatientSearchChanged(String value) {
    final normalizedValue = value.trim().toLowerCase();
    if (_patientQuery == normalizedValue) {
      return;
    }
    setState(() {
      _patientQuery = normalizedValue;
    });
  }

  void _onNurseSearchChanged(String value) {
    final normalizedValue = value.trim().toLowerCase();
    if (_nurseQuery == normalizedValue) {
      return;
    }
    setState(() {
      _nurseQuery = normalizedValue;
    });
  }

  Future<void> _loadDashboardData({bool showPatientLoading = true}) async {
    final patientProvider = context.read<PatientProvider>();
    final nurseProvider = context.read<NurseProvider>();

    await Future.wait([
      patientProvider.loadPatients(showLoading: showPatientLoading),
      nurseProvider.loadNurses(showLoading: showPatientLoading),
    ]);
  }

  Future<void> _syncPatients() {
    return syncPatientsWithFeedback(
      context: context,
      patientProvider: context.read<PatientProvider>(),
    );
  }

  Future<void> _openPatientSheet({Patient? patient}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddPatientSheet(patient: patient),
    );

    if (saved == true) {
      await _loadDashboardData(showPatientLoading: false);
    }
  }

  Future<void> _openAddPatientSheet() async {
    await _openPatientSheet();
  }

  Future<void> _openNurseManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NurseManagementScreen()),
    );

    if (!mounted) return;
    await _loadDashboardData(showPatientLoading: false);
  }

  Future<void> _openEditPatientSheet(Patient patient) async {
    await _openPatientSheet(patient: patient);
  }

  Future<void> _deletePatient(Patient patient) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final patientProvider = context.read<PatientProvider>();

    try {
      await patientProvider.deletePatient(patient);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete patient ${patient.roomNumber} from admin dashboard.',
        error,
        stackTrace,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.patientDeleteFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.deletedPatientMessage(patient.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDeletePatient(Patient patient) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deletePatient),
          content: Text(l10n.deletePatientConfirmation(patient.name)),
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

    if (shouldDelete == true) {
      await _deletePatient(patient);
    }
  }

  Iterable<String> _queryVariants(String query) sync* {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return;

    final translator = PatientTranslationService.instance;
    final variants = <String>{
      normalized,
      translator.toArabic(normalized).toLowerCase(),
      translator.toEnglish(normalized).toLowerCase(),
    };

    for (final variant in variants) {
      if (variant.trim().isNotEmpty) {
        yield variant.trim();
      }
    }
  }

  String _patientSearchableText(Patient patient, AppLocalizations l10n) {
    final translator = PatientTranslationService.instance;
    return [
      patient.name,
      translator.toArabic(patient.name),
      translator.toEnglish(patient.name),
      patient.roomNumber,
      patient.doctorName,
      translator.toArabic(patient.doctorName),
      translator.toEnglish(patient.doctorName),
      patient.department,
      translator.toArabic(patient.department),
      translator.toEnglish(patient.department),
      patient.floor,
      l10n.departmentLabel(patient.department),
      l10n.floorLabel(patient.floor),
    ].join(' ').toLowerCase();
  }

  String _nurseSearchableText(Nurse nurse, AppLocalizations l10n) {
    final translator = PatientTranslationService.instance;
    return [
      nurse.name,
      translator.toArabic(nurse.name),
      translator.toEnglish(nurse.name),
      nurse.department,
      translator.toArabic(nurse.department),
      translator.toEnglish(nurse.department),
      nurse.floor,
      nurse.shiftStart,
      nurse.shiftEnd,
      l10n.departmentLabel(nurse.department),
      l10n.floorLabel(nurse.floor),
    ].join(' ').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final nurseProvider = context.watch<NurseProvider>();
    final l10n = AppLocalizations.of(context);
    const primaryColor = AppColors.secondary;
    const accentColor = AppColors.primary;
    final patients = patientProvider.patients;
    final nurseAssignments = nurseProvider.nurses;
    final totalAlerts = patients.where((patient) => patient.hasAlert).length;
    final totalDepartments = patients.map((patient) => patient.department).toSet().length;
    final totalFloors = patients.map((patient) => patient.floor).toSet().length;
    final under20Count = patients.where((patient) => patient.age < 20).length;
    final departmentStats = _buildDepartmentStats(patients);
    final floorStats = _buildFloorStats(patients, nurseAssignments);
    final patientQueryVariants = _queryVariants(_patientQuery).toList();
    final nurseQueryVariants = _queryVariants(_nurseQuery).toList();
    final filteredPatients = patients.where((patient) {
      if (patientQueryVariants.isEmpty) return true;
      final searchable = _patientSearchableText(patient, l10n);
      return patientQueryVariants.any(searchable.contains);
    }).toList();
    final filteredNurses = nurseAssignments.where((nurse) {
      if (nurseQueryVariants.isEmpty) return true;
      final searchable = _nurseSearchableText(nurse, l10n);
      return nurseQueryVariants.any(searchable.contains);
    }).toList();
    final topDepartmentLabel = departmentStats.isEmpty
        ? l10n.noDepartment
        : l10n.departmentLabel(departmentStats.first.department);
    final isLoading = patientProvider.isLoading || nurseProvider.isLoading;
    final hasError = patientProvider.hasError || nurseProvider.hasError;

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
        title: Text(l10n.adminDashboard),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openAddPatientSheet,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          IconButton(
            onPressed: patientProvider.isSyncing ? null : _syncPatients,
            icon: patientProvider.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync_rounded),
          ),
          const LanguageSelectorButton(iconColor: Colors.white),
          if (l10n.isArabic)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_forward_rounded),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.quickOverview,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.adminOverviewDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSyncStatusCard(
            pendingSyncCount: patientProvider.pendingSyncCount,
            summaryText: lastPatientsSyncText(
              l10n,
              patientProvider.lastPatientsPullAt,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const _AdminLoadingState()
          else if (hasError)
            _AdminErrorState(onRetry: () => _loadDashboardData())
          else ...[
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.18,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AdminSummaryCard(
                  label: l10n.nurses,
                  value: nurseAssignments.length.toString().padLeft(2, '0'),
                  icon: Icons.badge_outlined,
                ),
                _AdminSummaryCard(
                  label: l10n.patients,
                  value: patients.length.toString().padLeft(2, '0'),
                  icon: Icons.people_alt_outlined,
                ),
                _AdminSummaryCard(
                  label: l10n.departments,
                  value: totalDepartments.toString().padLeft(2, '0'),
                  icon: Icons.apartment_outlined,
                ),
                _AdminSummaryCard(
                  label: l10n.alerts,
                  value: totalAlerts.toString().padLeft(2, '0'),
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.patientsUnderAgeCount(under20Count),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.pediatricsFloorNote,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: l10n.departmentOverview,
              child: Column(
                children: departmentStats
                    .map(
                      (stat) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AdminInfoTile(
                          title: l10n.departmentLabel(stat.department),
                          subtitle: l10n.departmentStatSummary(
                            stat.patientCount,
                            stat.alertCount,
                          ),
                          trailing: Text(
                            '${((stat.patientCount / (patients.isEmpty ? 1 : patients.length)) * 100).round()}%',
                            style: const TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: l10n.floorCoverage,
              child: Column(
                children: floorStats
                    .map(
                      (stat) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AdminInfoTile(
                          title: l10n.floorCoverageTitle(stat.floor),
                          subtitle: l10n.floorCoverageSummary(
                            stat.patientCount,
                            stat.nurseCount,
                          ),
                          trailing: Text(
                            '${stat.departmentCount}',
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: l10n.nurseList,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openNurseManagement,
                      icon: const Icon(Icons.groups_2_outlined),
                      label: Text(l10n.nurseManagement),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AdminSearchField(
                    controller: _nurseSearchController,
                    hintText: l10n.nurseSearchHint,
                    onChanged: _onNurseSearchChanged,
                  ),
                  const SizedBox(height: 10),
                  if (filteredNurses.isEmpty)
                    Text(
                      _nurseQuery.isEmpty
                          ? l10n.noNursesYet
                          : l10n.noMatchingNurses,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    )
                  else
                    ...filteredNurses.map(
                      (nurse) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AdminInfoTile(
                          title: nurse.name,
                          subtitle: l10n.nurseShiftLabel(
                            nurse.shiftStart,
                            nurse.shiftEnd,
                          ),
                          trailing: Text(
                            l10n.floorLabel(nurse.floor),
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: l10n.patientList,
              child: Column(
                children: [
                  _AdminSearchField(
                    controller: _patientSearchController,
                    hintText: l10n.adminPatientSearchHint,
                    onChanged: _onPatientSearchChanged,
                  ),
                  const SizedBox(height: 8),
                  if (filteredPatients.isEmpty)
                    Text(
                      _patientQuery.isEmpty
                          ? l10n.noPatientFound
                          : l10n.noMatchingPatients,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    )
                  else
                    ...filteredPatients.map(
                      (patient) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AdminPatientTile(
                          patient: patient,
                          onEdit: () => _openEditPatientSheet(patient),
                          onDelete: () => _confirmDeletePatient(patient),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: l10n.adminInsights,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InsightLine(
                    text: l10n.floorsCoverageInsight(
                      nurseAssignments.length,
                      totalFloors,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InsightLine(
                    text: l10n.activeAlertsInsight(totalAlerts),
                  ),
                  const SizedBox(height: 8),
                  _InsightLine(
                    text: l10n.topDepartmentInsight(topDepartmentLabel),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_DepartmentStat> _buildDepartmentStats(List<Patient> patients) {
    final grouped = <String, List<Patient>>{};
    for (final patient in patients) {
      grouped.putIfAbsent(patient.department, () => []).add(patient);
    }

    final stats = grouped.entries.map((entry) {
      final alertCount = entry.value.where((patient) => patient.hasAlert).length;
      return _DepartmentStat(
        department: entry.key,
        patientCount: entry.value.length,
        alertCount: alertCount,
      );
    }).toList();

    stats.sort((a, b) => b.patientCount.compareTo(a.patientCount));
    return stats;
  }

  List<_FloorStat> _buildFloorStats(
    List<Patient> patients,
    List<Nurse> assignments,
  ) {
    final grouped = <String, List<Patient>>{};
    for (final patient in patients) {
      grouped.putIfAbsent(patient.floor, () => []).add(patient);
    }

    final stats = grouped.entries.map((entry) {
      final nurseCount = assignments
          .where((assignment) => assignment.floor == entry.key)
          .length;
      final departmentCount = entry.value
          .map((patient) => patient.department)
          .toSet()
          .length;

      return _FloorStat(
        floor: entry.key,
        patientCount: entry.value.length,
        nurseCount: nurseCount,
        departmentCount: departmentCount,
      );
    }).toList();

    stats.sort((a, b) => a.floor.compareTo(b.floor));
    return stats;
  }
}

class _AdminLoadingState extends StatelessWidget {
  const _AdminLoadingState();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color.fromARGB(255, 110, 101, 168),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loadingAdminDashboard,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 37, 101, 146),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _AdminErrorState({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 34,
            color: Color.fromARGB(255, 110, 101, 168),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.adminDashboardLoadError,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 37, 101, 146),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}

class _AdminSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AdminSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

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
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 110, 101, 168),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 37, 101, 146),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSyncStatusCard extends StatelessWidget {
  final int pendingSyncCount;
  final String summaryText;

  const _AdminSyncStatusCard({
    required this.pendingSyncCount,
    required this.summaryText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPendingChanges = pendingSyncCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPendingChanges ? Icons.sync_problem_rounded : Icons.cloud_done_rounded,
              color: const Color.fromARGB(255, 110, 101, 168),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPendingChanges
                      ? l10n.pendingSyncChanges(pendingSyncCount)
                      : l10n.syncUsingLocalData,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 37, 101, 146),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summaryText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _AdminSectionCard({
    required this.title,
    required this.child,
  });

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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 37, 101, 146),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _AdminSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context).isArabic;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AdminInfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _AdminInfoTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _AdminPatientTile extends StatelessWidget {
  final Patient patient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminPatientTile({
    required this.patient,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8EEFF),
            child: Text(
              patient.firstLetter,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 110, 101, 168),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.roomLabel(patient.roomNumber)} • ${l10n.departmentFloorLabel(patient.department, patient.floor)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.doctorLabel(patient.doctorName),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                color: const Color.fromARGB(255, 110, 101, 168),
                tooltip: l10n.edit,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red,
                tooltip: l10n.delete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  final String text;

  const _InsightLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(
            Icons.circle,
            size: 8,
            color: Color.fromARGB(255, 110, 101, 168),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _DepartmentStat {
  final String department;
  final int patientCount;
  final int alertCount;

  const _DepartmentStat({
    required this.department,
    required this.patientCount,
    required this.alertCount,
  });
}

class _FloorStat {
  final String floor;
  final int patientCount;
  final int nurseCount;
  final int departmentCount;

  const _FloorStat({
    required this.floor,
    required this.patientCount,
    required this.nurseCount,
    required this.departmentCount,
  });
}

class _AddPatientSheet extends StatefulWidget {
  final Patient? patient;

  const _AddPatientSheet({this.patient});

  @override
  State<_AddPatientSheet> createState() => _AddPatientSheetState();
}

class _AddPatientSheetState extends State<_AddPatientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _roomController = TextEditingController();
  final _doctorController = TextEditingController();
  final _diagnosisEnController = TextEditingController();
  final _noteEnController = TextEditingController();
  String _selectedDepartment = 'Medical';
  String _selectedFloor = '1';
  String _selectedStatus = 'Stable';
  bool _isSaving = false;
  String? _saveError;

  static const List<String> _departments = [
    'Medical',
    'Surgery',
    'Pediatrics',
    'ICU',
  ];

  static const List<String> _floors = ['1', '2'];
  static const List<String> _statuses = ['Stable', 'Observation', 'Critical'];

  TextEditingController get _diagnosisController => _diagnosisEnController;
  TextEditingController get _noteController => _noteEnController;
  bool _didPrefill = false;
  bool get _isEditing => widget.patient != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill || widget.patient == null) return;

    final patient = widget.patient!;
    final isArabic = AppLocalizations.of(context).isArabic;
    _nameController.text = patient.name;
    _ageController.text = patient.age.toString();
    _roomController.text = patient.roomNumber;
    _doctorController.text = patient.doctorName;
    _selectedDepartment = patient.department;
    _selectedFloor = patient.floor;
    _selectedStatus = patient.status;
    _diagnosisController.text = isArabic
        ? (patient.diagnosisArabic ?? patient.diagnosis)
        : patient.diagnosis;
    _noteController.text = isArabic
        ? (patient.noteArabic ?? patient.note)
        : patient.note;
    _didPrefill = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _roomController.dispose();
    _doctorController.dispose();
    _diagnosisEnController.dispose();
    _noteEnController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    final l10n = AppLocalizations.of(context);
    final patientProvider = context.read<PatientProvider>();
    final navigator = Navigator.of(context);
    if (!_formKey.currentState!.validate()) return;
    final isArabic = AppLocalizations.of(context).isArabic;
    final translator = PatientTranslationService.instance;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final room = _roomController.text.trim();
    final doctorName = _doctorController.text.trim();
    final diagnosisInput = _diagnosisController.text.trim();
    final noteInput = _noteController.text.trim();
    final existingPatient = widget.patient;
    late final String diagnosis;
    late final String diagnosisArabic;
    late final String note;
    late final String noteArabic;
    final firstLetter = name.isEmpty
        ? 'P'
        : name.substring(0, 1).toUpperCase();

    final roomAlreadyTaken = patientProvider.patients.any((patient) {
      if (_isEditing && patient.roomNumber == existingPatient?.roomNumber) {
        return false;
      }
      return patient.roomNumber.trim() == room;
    });

    if (roomAlreadyTaken) {
      setState(() {
        _isSaving = false;
        _saveError = l10n.roomAlreadyExists;
      });
      return;
    }

    if (isArabic) {
      diagnosisArabic = diagnosisInput;
      diagnosis = translator.toEnglish(diagnosisArabic);
      noteArabic = noteInput.isEmpty ? 'التقييم التالي قيد الانتظار' : noteInput;
      note = translator.toEnglish(noteArabic);
    } else {
      diagnosis = diagnosisInput;
      diagnosisArabic = translator.toArabic(diagnosis);
      note = noteInput.isEmpty ? 'Next assessment pending' : noteInput;
      noteArabic = translator.toArabic(note);
    }

    final detail = diagnosis.isEmpty
        ? 'New patient added from the admin dashboard.'
        : 'Follow up on $diagnosis and update the chart during this shift.';
    final detailArabic = diagnosisArabic.isEmpty
        ? 'تمت إضافة مريض جديد من لوحة الإدارة.'
        : 'تابعي حالة $diagnosisArabic وحدثي السجل خلال هذه المناوبة.';
    const medicationInfo = 'Medication plan will be added by the nurse team.';
    const medicationInfoArabic = 'سيتم إضافة الخطة الدوائية من فريق التمريض.';

    final patient = Patient(
      firstLetter: firstLetter,
      name: name,
      age: age,
      roomNumber: room,
      doctorName: doctorName,
      department: _selectedDepartment,
      floor: _selectedFloor,
      diagnosis: diagnosis,
      diagnosisArabic: diagnosisArabic,
      status: _selectedStatus,
      note: note,
      noteArabic: noteArabic,
      detail: detail,
      detailArabic: detailArabic,
      medicationInfo: existingPatient?.medicationInfo ?? medicationInfo,
      medicationInfoArabic:
          existingPatient?.medicationInfoArabic ?? medicationInfoArabic,
      medicationTasks: existingPatient?.medicationTasks ?? const [],
      vitalSigns:
          existingPatient?.vitalSigns ?? 'BP --/--, HR --, Temp --, SpO2 --',
      hasAlert: _selectedStatus == 'Critical',
      hasMedicationRound:
          existingPatient?.medicationTasks.isNotEmpty ??
          existingPatient?.hasMedicationRound ??
          false,
    );

    try {
      if (_isEditing) {
        await patientProvider.updatePatient(
          patient,
          previousRoomNumber: existingPatient!.roomNumber,
        );
      } else {
        await patientProvider.addPatient(patient);
      }
    } on StateError {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = l10n.roomAlreadyExists;
      });
      return;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save patient from admin dashboard form.',
        error,
        stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = l10n.patientSaveFailed;
      });
      return;
    }

    if (!mounted) return;
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const primaryColor = AppColors.secondary;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing
                    ? l10n.editPatient
                    : l10n.addNewPatient,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 37, 101, 146),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEditing
                    ? l10n.editPatientDescription
                    : l10n.addPatientDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _AdminTextField(
                controller: _nameController,
                label: l10n.patientName,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.enterPatientName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AdminTextField(
                      controller: _ageController,
                      label: l10n.age,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final age = int.tryParse((value ?? '').trim());
                        if (age == null || age <= 0) {
                          return l10n.invalidAge;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminTextField(
                      controller: _roomController,
                      label: l10n.roomNumber,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return l10n.enterRoom;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AdminTextField(
                controller: _doctorController,
                label: l10n.doctorName,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.enterDoctorName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _AdminDropdownField(
                value: _selectedDepartment,
                label: l10n.department,
                items: _departments,
                itemLabelBuilder: (l10n, item) => l10n.departmentLabel(item),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedDepartment = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AdminDropdownField(
                      value: _selectedFloor,
                      label: l10n.floor,
                      items: _floors,
                      itemLabelBuilder: (l10n, item) => l10n.floorLabel(item),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedFloor = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminDropdownField(
                      value: _selectedStatus,
                      label: l10n.status,
                      items: _statuses,
                      itemLabelBuilder: (l10n, item) => l10n.statusLabel(item),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AdminTextField(
                controller: _diagnosisController,
                label: l10n.diagnosis,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.enterDiagnosis;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _AdminTextField(
                controller: _noteController,
                label: l10n.nursingNote,
                maxLines: 2,
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _saveError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _savePatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.saving,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        _isEditing
                            ? l10n.saveChanges
                            : l10n.savePatient,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _AdminTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 18,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FB),
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

class _AdminDropdownField extends StatelessWidget {
  final String value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(AppLocalizations l10n, String item)? itemLabelBuilder;

  const _AdminDropdownField({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items
              .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                  child: Text(itemLabelBuilder?.call(l10n, item) ?? item),
                ),
              )
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F7FB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
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
