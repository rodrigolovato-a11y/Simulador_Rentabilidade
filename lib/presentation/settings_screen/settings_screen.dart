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
  // ===== Helpers =====
  Locale _parseLocaleTag(String tag) {
    final parts = tag.split(RegExp(r'[-_]'));
    if (parts.isEmpty) return const Locale('en');
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  // ===== Estado =====
  bool _isLoading = true;

  // Preferências
  String _selectedAreaUnit = 'hectares'; // 'hectares' | 'acres' | 'm²'
  String _selectedLanguage = 'pt_BR';    // 'pt_BR' | 'en_US'
  double _kgPerSackWeight = 60.0;        // peso padrão de 1 saca (kg)

  // ===== Ciclo de vida =====
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await _prefs;
      setState(() {
        _selectedAreaUnit =
            prefs.getString('selected_area_unit') ?? 'hectares';
        _selectedLanguage =
            prefs.getString('selected_language') ?? 'pt_BR';
        _kgPerSackWeight =
            prefs.getDouble('kg_per_sack_weight') ?? 60.0;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ===== Persistência (unitária) =====
  Future<void> _saveAreaUnit(String unit) async {
    final prefs = await _prefs;
    await prefs.setString('selected_area_unit', unit);
  }

  Future<void> _saveLanguage(String tag) async {
    final prefs = await _prefs;
    await prefs.setString('selected_language', tag);
  }

  Future<void> _saveKgPerSack(double kg) async {
    final prefs = await _prefs;
    await prefs.setDouble('kg_per_sack_weight', kg);
  }

  // ===== Ações =====
  void _handleLogout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login-screen', (_) => false);
  }

  Future<void> _onLanguageChanged(String? value) async {
    final newTag = value ?? 'pt_BR';
    setState(() => _selectedLanguage = newTag);

    // 1) persiste
    await _saveLanguage(newTag);

    // 2) aplica imediatamente no app
    final locale = _parseLocaleTag(newTag);
    // Se seu LocaleController expõe outro método, ajuste aqui.
    LocaleController.of(context).setLocale(locale);

    // 3) feedback
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.saved),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _onAreaUnitChanged(String? value) async {
    final newUnit = value ?? 'hectares';
    setState(() => _selectedAreaUnit = newUnit);
    await _saveAreaUnit(newUnit);
  }

  Future<void> _onSaveAll() async {
    await _saveAreaUnit(_selectedAreaUnit);
    await _saveLanguage(_selectedLanguage);
    await _saveKgPerSack(_kgPerSackWeight);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.saved),
        duration: const Duration(milliseconds: 900),
      ),
    );
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
            onPressed: _onSaveAll,
            icon: const Icon(Icons.save),
            tooltip: AppLocalizations.of(context)!.save,
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
              onChanged: _onAreaUnitChanged,
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
              value: _selectedLanguage,
              onChanged: _onLanguageChanged,
              decoration: const InputDecoration(
                labelText: 'Idioma',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pt_BR', child: Text('Português (Brasil)')),
                DropdownMenuItem(value: 'en_US', child: Text('English (US)')),
              ],
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'kg',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) async {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed != null && parsed > 0) {
                  setState(() => _kgPerSackWeight = parsed);
                  // salva “on the fly”
                  await _saveKgPerSack(parsed);
                }
              },
            ),

            SizedBox(height: 3.h),

            // ===== Ações =====
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _onSaveAll,
                  icon: const Icon(Icons.save),
                  label: Text(AppLocalizations.of(context)!.save),
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
