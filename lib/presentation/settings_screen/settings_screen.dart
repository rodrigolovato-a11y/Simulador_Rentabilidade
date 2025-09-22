import 'package:effatha_agro_simulator/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/localization/locale_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Estado
  bool _isLoading = true;

  // Preferências
  String _selectedAreaUnit = 'hectares'; // 'hectares' | 'acres' | 'm²'
  String _selectedLanguageTag = 'pt_BR'; // tag persistida ('pt_BR', 'en_US', ...)
  double _kgPerSackWeight = 60.0;        // peso padrão de 1 saca (kg)

  // ===== Helpers =====
  Locale _parseLocaleTag(String tag) {
    final parts = tag.split(RegExp(r'[-_]'));
    if (parts.isEmpty) return const Locale('en');
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

  String _toTag(Locale locale) {
    if ((locale.countryCode ?? '').isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  String _humanNameForLocale(Locale l) {
    // Nomes exibidos no seletor. Ajuste se desejar.
    final code = l.languageCode.toLowerCase();
    final cc = (l.countryCode ?? '').toUpperCase();
    switch (code) {
      case 'pt':
        return cc == 'BR' || cc.isEmpty ? 'Português (Brasil)' : 'Português';
      case 'en':
        return cc == 'US' || cc.isEmpty ? 'English (US)' : 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        // Fallback genérico: mostra o código
        return '${l.languageCode}${cc.isNotEmpty ? ' ($cc)' : ''}';
    }
  }

  // ===== Ciclo de vida =====
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedAreaUnit = prefs.getString('selected_area_unit') ?? 'hectares';
        _selectedLanguageTag = prefs.getString('selected_language') ?? 'pt_BR';
        _kgPerSackWeight = prefs.getDouble('kg_per_sack_weight') ?? 60.0;
        _isLoading = false;
      });

      // Se o idioma salvo não estiver mais na lista suportada, ajusta para o primeiro suportado
      final supported = AppLocalizations.supportedLocales;
      final tags = supported.map(_toTag).toSet();
      if (!tags.contains(_selectedLanguageTag) && supported.isNotEmpty) {
        final fallbackTag = _toTag(supported.first);
        setState(() => _selectedLanguageTag = fallbackTag);
        // Atualiza de imediato o app para o fallback
        await LocaleController.instance.setLocale(_parseLocaleTag(fallbackTag));
        final p = await SharedPreferences.getInstance();
        await p.setString('selected_language', fallbackTag);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _persistPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_area_unit', _selectedAreaUnit);
    await prefs.setString('selected_language', _selectedLanguageTag);
    await prefs.setDouble('kg_per_sack_weight', _kgPerSackWeight);
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supportedLocales = AppLocalizations.supportedLocales;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.applicationSettings),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Garante que o valor atual existe nas opções (evita crash do Dropdown)
    final currentTag = _selectedLanguageTag;
    final supportedTags = supportedLocales.map(_toTag).toList();
    final dropdownValue = supportedTags.contains(currentTag)
        ? currentTag
        : (supportedTags.isNotEmpty ? supportedTags.first : 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.applicationSettings),
        actions: [
          IconButton(
            onPressed: () async {
              await _persistPrefs();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.advancedSettings),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.save),
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Unidade de área =====
            Text(
              AppLocalizations.of(context)!.areaUnit,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            DropdownButtonFormField<String>(
              value: _selectedAreaUnit,
              onChanged: (value) {
                setState(() {
                  _selectedAreaUnit = value ?? 'hectares';
                });
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.areaUnit,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'hectares',
                  child: Text(AppLocalizations.of(context)!.hectares),
                ),
                DropdownMenuItem(
                  value: 'acres',
                  child: Text(AppLocalizations.of(context)!.acres),
                ),
                DropdownMenuItem(
                  value: 'm²',
                  child: Text(AppLocalizations.of(context)!.squareMeters),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // ===== Idioma =====
            Text(
              'Idioma',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            DropdownButtonFormField<String>(
              value: dropdownValue,
              onChanged: (value) async {
                final tag = value ?? dropdownValue;
                setState(() => _selectedLanguageTag = tag);

                // 1) Aplica imediatamente no app
                final locale = _parseLocaleTag(tag);
                await LocaleController.instance.setLocale(locale);

                // 2) Persiste
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selected_language', tag);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Idioma aplicado'),
                    duration: Duration(milliseconds: 900),
                  ),
                );
              },
              decoration: const InputDecoration(
                labelText: 'Idioma',
                border: OutlineInputBorder(),
              ),
              items: supportedLocales.map((loc) {
                final tag = _toTag(loc);
                return DropdownMenuItem(
                  value: tag,
                  child: Text(_humanNameForLocale(loc)),
                );
              }).toList(),
            ),

            SizedBox(height: 3.h),

            // ===== Peso da saca (kg) =====
            Text(
              'Peso por saca (kg)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              initialValue: _kgPerSackWeight.toStringAsFixed(1),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'kg',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                final parsed =
                    double.tryParse(v.replaceAll(',', '.'));
                if (parsed != null && parsed > 0) {
                  setState(() {
                    _kgPerSackWeight = parsed;
                  });
                }
              },
            ),

            SizedBox(height: 3.h),

            // ===== Ações =====
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await _persistPrefs();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preferências salvas'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login-screen',
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(AppLocalizations.of(context)!.logout),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
