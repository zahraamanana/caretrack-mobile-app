import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/patient.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../services/logger_service.dart';
import '../utils/app_colors.dart';
import '../utils/patient_sync_feedback.dart';
import '../widgets/language_selector_button.dart';
import '../widgets/patient_card.dart';
import 'admin_dashboard.dart';
import 'patient_details_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFloor;

  Future<void> _syncPatients() {
    return syncPatientsWithFeedback(
      context: context,
      patientProvider: context.read<PatientProvider>(),
    );
  }

  String _lastSyncText(AppLocalizations l10n, DateTime? lastPull) {
    return lastPatientsSyncText(l10n, lastPull);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final l10n = AppLocalizations.of(context);
    const primaryColor = AppColors.secondary;
    final query = _searchController.text.trim().toLowerCase();
    final patients = patientProvider.patients;
    final availableFloors =
        patients.map((patient) => patient.floor).toSet().toList()..sort();
    final List<Patient> visiblePatients = patients.where((patient) {
      final matchesFloor =
          _selectedFloor == null || patient.floor == _selectedFloor;
      final searchableText = [
        patient.name.toLowerCase(),
        patient.roomNumber.toLowerCase(),
        patient.department.toLowerCase(),
        patient.floor.toLowerCase(),
        l10n.departmentLabel(patient.department).toLowerCase(),
        l10n.floorLabel(patient.floor).toLowerCase(),
      ].join(' ');
      final matchesQuery = query.isEmpty || searchableText.contains(query);

      return matchesFloor && matchesQuery;
    }).toList();
    final alertCount = visiblePatients
        .where((patient) => patient.hasAlert)
        .length;
    final medRoundCount = visiblePatients
        .where((patient) => patient.hasMedicationRound)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.patients),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const LanguageSelectorButton(iconColor: Colors.white),
          IconButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.isArabic ? 'تسجيل الخروج' : 'Logout',
          ),
          IconButton(
            onPressed: () async {
              final patientProvider = context.read<PatientProvider>();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
              if (!mounted) return;
              await patientProvider.loadPatients(showLoading: false);
            },
            icon: const Icon(Icons.admin_panel_settings_outlined),
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
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (patientProvider.isLoading)
            const _DashboardLoadingState()
          else if (patientProvider.hasError)
            _DashboardErrorState(
              onRetry: () => context.read<PatientProvider>().loadPatients(),
            )
          else ...[
            _ShiftSummaryCard(
              patientCount: visiblePatients.length,
              medRoundCount: medRoundCount,
              alertCount: alertCount,
            ),
            const SizedBox(height: 12),
            _SyncStatusCard(
              pendingSyncCount: patientProvider.pendingSyncCount,
              summaryText: _lastSyncText(
                l10n,
                patientProvider.lastPatientsPullAt,
              ),
            ),
            const SizedBox(height: 16),
            _SearchBar(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _FloorFilterSection(
              selectedFloor: _selectedFloor,
              floors: availableFloors,
              onFloorSelected: (floor) {
                setState(() {
                  _selectedFloor = floor;
                });
              },
            ),
            const SizedBox(height: 16),
            const _QuickActionsSection(),
            const SizedBox(height: 20),
            Text(
              l10n.assignedPatients,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 37, 101, 146),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? (_selectedFloor == null
                        ? l10n.monitorRoomUpdates
                        : l10n.showingFloorPatients(_selectedFloor!))
                  : l10n.patientsFound(visiblePatients.length),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (visiblePatients.isEmpty)
              const _EmptySearchState()
            else
              ...visiblePatients.expand(
                (patient) => [
                  PatientCard(
                    firstLetter: patient.firstLetter,
                    name: patient.name,
                    roomNumber: patient.roomNumber,
                    department: patient.department,
                    floor: patient.floor,
                    status: patient.status,
                    note: patient.note,
                    noteArabic: patient.noteArabic,
                    detail: patient.detail,
                    detailArabic: patient.detailArabic,
                    onTap: () async {
                      final patientProvider = context.read<PatientProvider>();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PatientDetailsScreen(patient: patient),
                        ),
                      );
                      if (!mounted) return;
                      try {
                        await patientProvider.loadPatients(showLoading: false);
                      } catch (error, stackTrace) {
                        AppLogger.error(
                          'Failed to refresh patients after returning from details.',
                          error,
                          stackTrace,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: l10n.searchHint,
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
        fillColor: const Color(0xFFF5F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

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
            l10n.loadingPatients,
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

class _DashboardErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _DashboardErrorState({required this.onRetry});

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
            l10n.localPatientsLoadError,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 37, 101, 146),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
        ],
      ),
    );
  }
}

class _FloorFilterSection extends StatelessWidget {
  final String? selectedFloor;
  final List<String> floors;
  final ValueChanged<String?> onFloorSelected;

  const _FloorFilterSection({
    required this.selectedFloor,
    required this.floors,
    required this.onFloorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.assignedFloor,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 37, 101, 146),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FloorChip(
                label: l10n.allFloors,
                isSelected: selectedFloor == null,
                onTap: () => onFloorSelected(null),
              ),
              const SizedBox(width: 10),
              ...floors.expand(
                (floor) => [
                  _FloorChip(
                    label: l10n.floorLabel(floor),
                    isSelected: selectedFloor == floor,
                    onTap: () => onFloorSelected(floor),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FloorChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloorChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 110, 101, 168);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

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
            Icons.person_search_outlined,
            size: 34,
            color: Color.fromARGB(255, 110, 101, 168),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noPatientFound,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 37, 101, 146),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tryAnotherName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftSummaryCard extends StatelessWidget {
  final int patientCount;
  final int medRoundCount;
  final int alertCount;

  const _ShiftSummaryCard({
    required this.patientCount,
    required this.medRoundCount,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.morningShiftOverview,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 37, 101, 146),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.shiftSummary(patientCount, medRoundCount, alertCount),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: l10n.patientsLabel,
                  value: patientCount.toString().padLeft(2, '0'),
                  icon: Icons.people_alt_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  label: l10n.medRounds,
                  value: medRoundCount.toString().padLeft(2, '0'),
                  icon: Icons.medication_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  label: l10n.alerts,
                  value: alertCount.toString().padLeft(2, '0'),
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final int pendingSyncCount;
  final String summaryText;

  const _SyncStatusCard({
    required this.pendingSyncCount,
    required this.summaryText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPendingChanges = pendingSyncCount > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 110, 101, 168)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 37, 101, 146),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 37, 101, 146),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.assignment_turned_in_outlined,
                title: l10n.tasks,
                subtitle: l10n.reviewChecklist,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.schedule_outlined,
                title: l10n.rounds,
                subtitle: l10n.checkMedicationTimes,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
            backgroundColor: const Color(0xFFE8EEFF),
            child: Icon(icon, color: const Color.fromARGB(255, 110, 101, 168)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
