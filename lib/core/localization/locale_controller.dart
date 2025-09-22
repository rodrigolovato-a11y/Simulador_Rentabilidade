import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Controlador de locale simples, com singleton + ChangeNotifier.
/// Se o seu `main.dart` escuta este notifier e repassa `locale` ao MaterialApp,
/// a troca de idioma ocorre em runtime.
class LocaleController extends ChangeNotifier {
  LocaleController._internal();
  static final LocaleController instance = LocaleController._internal();

  Locale? _locale;
  Locale? get locale => _locale;

  /// Compatibilidade com chamadas antigas: retorna o singleton.
  static LocaleController of(BuildContext context) => instance;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}
