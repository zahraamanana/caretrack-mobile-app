import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../models/patients_sync_result.dart';
import '../providers/patient_provider.dart';
import '../services/logger_service.dart';

Future<void> syncPatientsWithFeedback({
  required BuildContext context,
  required PatientProvider patientProvider,
}) async {
  if (patientProvider.isSyncing) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.syncingPatients),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );

  try {
    final result = await patientProvider.syncPatients();
    if (!context.mounted) {
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(syncPatientsMessage(result, l10n)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (error, stackTrace) {
    AppLogger.error('Patient sync failed from dashboard UI.', error, stackTrace);
    if (!context.mounted) {
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.syncUsingLocalData),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

String syncPatientsMessage(
  PatientsSyncResult result,
  AppLocalizations l10n,
) {
  switch (result.status) {
    case PatientsSyncStatus.synced:
      return l10n.syncCompletedMessage;
    case PatientsSyncStatus.pendingLocalChanges:
      return l10n.syncBlockedByPendingChanges(result.pendingChanges);
    case PatientsSyncStatus.notConfigured:
      return l10n.syncNotConfiguredMessage;
  }
}

String lastPatientsSyncText(
  AppLocalizations l10n,
  DateTime? lastPull,
) {
  if (lastPull == null) {
    return l10n.lastSyncNever;
  }

  final hour = lastPull.hour == 0
      ? 12
      : (lastPull.hour > 12 ? lastPull.hour - 12 : lastPull.hour);
  final minute = lastPull.minute.toString().padLeft(2, '0');
  final period = lastPull.hour >= 12 ? 'PM' : 'AM';
  final formatted = '${lastPull.day}/${lastPull.month} - $hour:$minute $period';
  return l10n.lastSyncLabel(formatted);
}
