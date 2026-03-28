import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../services/app_language_service.dart';

class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({
    super.key,
    this.iconColor,
    this.backgroundColor,
  });

  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final languageService = AppLanguageService.instance;
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final currentCode = languageService.locale.languageCode;

        return PopupMenuButton<String>(
          tooltip: l10n.language,
          initialValue: currentCode,
          onSelected: languageService.setLanguage,
          color: backgroundColor,
          icon: Icon(Icons.language, color: iconColor),
          itemBuilder: (context) => [
            CheckedPopupMenuItem<String>(
              value: 'en',
              checked: currentCode == 'en',
              child: Text(l10n.english),
            ),
            CheckedPopupMenuItem<String>(
              value: 'ar',
              checked: currentCode == 'ar',
              child: Text(l10n.arabic),
            ),
          ],
        );
      },
    );
  }
}
