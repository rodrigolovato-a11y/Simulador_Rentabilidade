import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controlador simples de Locale com singleton + ChangeNotifier.
/// - `loadSavedLocale()` carrega o idioma salvo em SharedPreferences.
/// - `setLocale()` atualiza o locale e notifica ouvintes (MaterialApp é rebuilt).
class LocaleController extends ChangeNotifier {
  LocaleController._internal();
  static final LocaleController instance = LocaleController._internal();

  Locale? _locale;
  Locale? get locale => _locale;

  /// Compatibilidade com chamadas antigas: retorna o singleton.
  static LocaleController of(BuildContext context) => instance;

  /// Converte tags como "pt_BR" ou "en_US" em Locale.
  Locale _parseLocaleTag(String tag) {
    final parts = tag.split(RegExp(r'[-_]'));
    if (parts.isEmpty) return const Locale('en');
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

  /// Carrega o locale salvo (chave: 'selected_language') e aplica.
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tag = prefs.getString('selected_language');
      if (tag != null && tag.isNotEmpty) {
        _locale = _parseLocaleTag(tag);
        notifyListeners();
      }
    } catch (_) {
      // Silencia: se falhar, continua com locale nulo (segue sistema).
    }
  }

  /// Define o locale em runtime e salva a escolha.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final tag = locale.countryCode != null && locale.countryCode!.isNotEmpty
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      await prefs.setString('selected_language', tag);
    } catch (_) {
      // se falhar o save, a troca ainda acontece na sessão atual.
    }
  }
}
