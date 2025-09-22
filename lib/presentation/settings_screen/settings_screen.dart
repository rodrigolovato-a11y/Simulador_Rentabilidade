import 'package:effatha_agro_simulator/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
  String _selectedLanguage = 'pt_BR';    // 'pt_BR' | 'en_US' | 'es_ES' | 'fr_FR' | 'de_DE'
  double _kgPerSackWeight = 60.0;        // peso padrão de 1 saca (kg)

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
        _selectedAreaUnit =
            prefs.getString('selected_area_unit') ?? 'hectares';
        _selectedLanguage = LocaleController.instance.locale.toLanguageTag().replaceAll('-', '_');
        _kgPerSackWeight =
            prefs.getDouble('kg_per_sack_weight') ?? 60.0;
        _isLoading = false;
      });
    } catch (e) {
      // Em caso de erro, usa defaults e libera UI
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_area_unit', _selectedAreaUnit);
    await LocaleController.instance.setLocale(_parseLocaleTag(_selectedLanguage));
    await prefs.setString('app_locale', _selectedLanguage.replaceAll('_','-'));  // compatibility
    await prefs.setDouble('kg_per_sack_weight', _kgPerSackWeight);
  }

  void _handleLogout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login-screen', (_) => false);
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.applicationSettings),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.applicationSettings),
        actions: [
          IconButton(
            onPressed: () async {
              await _savePrefs();
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
              value: _selectedLanguage,
              onChanged: (value) async {
                final code = (value ?? 'pt_BR');
                setState(() {
                  _selectedLanguage = code;
                });
                // Aplica a troca de idioma imediatamente
                await LocaleController.instance.setLocale(_parseLocaleTag(code));
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('app_locale', code.replaceAll('_','-'));
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.language,
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pt_BR', child: Text('Português (Brasil)')),
                DropdownMenuItem(value: 'en_US', child: Text('English (US)')),
                DropdownMenuItem(value: 'es_ES', child: Text('Español')),
                DropdownMenuItem(value: 'fr_FR', child: Text('Français')),
                DropdownMenuItem(value: 'de_DE', child: Text('Deutsch')),
              ],
            )
    ,

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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'kg',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
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
                    await _savePrefs();
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
                  onPressed: _handleLogout,
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
