import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';

class LanguageCornerButton extends StatelessWidget {
  const LanguageCornerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final isThai = localeService.locale.languageCode == 'th';

    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8),
          child: Material(
            color: Colors.white.withOpacity(0.9),
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await localeService.setLanguageCode(isThai ? 'en' : 'th');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isThai ? '🇹🇭' : '🇺🇸', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(isThai ? 'TH' : 'EN', style: TextStyle(color: Colors.brown.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}






