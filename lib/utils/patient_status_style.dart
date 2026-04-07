import 'package:flutter/material.dart';

import 'app_colors.dart';

Color patientStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'critical':
      return AppColors.error;
    case 'observation':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}
