import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/nurse_provider.dart';
import 'providers/patient_provider.dart';
import 'repositories/patient_repository.dart';
import 'repositories/nurse_repository.dart';
import 'services/app_language_service.dart';
import 'services/local_database_service.dart';
import 'services/notification_service.dart';
import 'utils/app_colors.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguageService.instance.loadSavedLanguage();
  await LocalDatabaseService.instance.initialize();
  await PatientRepository.instance.seedPatientsIfNeeded();
  await NurseRepository.instance.seedNursesIfNeeded();
  await NotificationService.instance.initialize();
  runApp(const CareTrackApp());
}

class CareTrackApp extends StatelessWidget {
  const CareTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientProvider()..loadPatients(),
        ),
        ChangeNotifierProvider(
          create: (_) => NurseProvider()..loadNurses(),
        ),
      ],
      child: AnimatedBuilder(
        animation: AppLanguageService.instance,
        builder: (context, _) {
          final languageService = AppLanguageService.instance;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'CareTrack',
            locale: languageService.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            theme: ThemeData(
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: AppColors.background,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
