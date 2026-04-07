import 'package:caretrack/utils/app_colors.dart';
import 'package:caretrack/utils/patient_status_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('patientStatusColor maps patient states to the expected colors', () {
    expect(patientStatusColor('Critical'), AppColors.error);
    expect(patientStatusColor('Observation'), AppColors.warning);
    expect(patientStatusColor('Stable'), AppColors.success);
  });
}
