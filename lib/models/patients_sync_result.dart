enum PatientsSyncStatus {
  synced,
  pendingLocalChanges,
  notConfigured,
}

class PatientsSyncResult {
  final PatientsSyncStatus status;
  final int pendingChanges;
  final DateTime? syncedAt;

  const PatientsSyncResult._({
    required this.status,
    required this.pendingChanges,
    this.syncedAt,
  });

  const PatientsSyncResult.synced({
    required DateTime syncedAt,
  }) : this._(
         status: PatientsSyncStatus.synced,
         pendingChanges: 0,
         syncedAt: syncedAt,
       );

  const PatientsSyncResult.pendingLocalChanges({
    required int pendingChanges,
    DateTime? syncedAt,
  }) : this._(
         status: PatientsSyncStatus.pendingLocalChanges,
         pendingChanges: pendingChanges,
         syncedAt: syncedAt,
       );

  const PatientsSyncResult.notConfigured({
    required int pendingChanges,
    DateTime? syncedAt,
  }) : this._(
         status: PatientsSyncStatus.notConfigured,
         pendingChanges: pendingChanges,
         syncedAt: syncedAt,
       );

  bool get didSync => status == PatientsSyncStatus.synced;
}
