import 'package:flutter/widgets.dart';

/// Lightweight, dependency-free localization.
///
/// Kept as plain Dart maps (instead of ARB + codegen) so the project compiles
/// out of the box. Add a language by adding a map below and listing its locale
/// in [Strings.supported].
class Strings {
  Strings(this.locale);
  final Locale locale;

  static const supported = [
    Locale('en'),
    Locale('it'),
    Locale('es'),
  ];

  static Strings of(BuildContext context) =>
      Localizations.of<Strings>(context, Strings) ?? Strings(const Locale('en'));

  static const _data = <String, Map<String, String>>{
    'en': {
      'play': 'PLAY',
      'tapToStart': 'Tap to start',
      'score': 'Score',
      'best': 'Best',
      'gameOver': 'GAME OVER',
      'newRecord': 'NEW RECORD!',
      'retry': 'RETRY',
      'continueAd': 'CONTINUE (Ad)',
      'home': 'HOME',
      'leaderboard': 'Leaderboard',
      'settings': 'Settings',
      'global': 'All-time',
      'daily': 'Today',
      'rank': 'Rank',
      'player': 'Player',
      'volume': 'Volume',
      'music': 'Music',
      'sfx': 'Sound effects',
      'language': 'Language',
      'haptics': 'Vibration',
      'account': 'Account',
      'signIn': 'Sign in',
      'signOut': 'Sign out',
      'guest': 'Guest',
      'email': 'Email',
      'password': 'Password',
      'continueGuest': 'Play as guest',
      'continueGoogle': 'Continue with Google',
      'continueApple': 'Continue with Apple',
      'continueEmail': 'Continue with Email',
      'nickname': 'Nickname',
      'save': 'Save',
      'tutorial':
          'Hit the falling colors on their column. For mixed colors press BOTH matching buttons together!',
      'comboHint': 'Yellow = Red + Green   Cyan = Green + Blue   Magenta = Red + Blue',
      'loading': 'Loading…',
    },
    'it': {
      'play': 'GIOCA',
      'tapToStart': 'Tocca per iniziare',
      'score': 'Punti',
      'best': 'Record',
      'gameOver': 'GAME OVER',
      'newRecord': 'NUOVO RECORD!',
      'retry': 'RIPROVA',
      'continueAd': 'CONTINUA (Pub)',
      'home': 'HOME',
      'leaderboard': 'Classifica',
      'settings': 'Impostazioni',
      'global': 'Di sempre',
      'daily': 'Oggi',
      'rank': 'Pos.',
      'player': 'Giocatore',
      'volume': 'Volume',
      'music': 'Musica',
      'sfx': 'Effetti sonori',
      'language': 'Lingua',
      'haptics': 'Vibrazione',
      'account': 'Account',
      'signIn': 'Accedi',
      'signOut': 'Esci',
      'guest': 'Ospite',
      'email': 'Email',
      'password': 'Password',
      'continueGuest': 'Gioca come ospite',
      'continueGoogle': 'Continua con Google',
      'continueApple': 'Continua con Apple',
      'continueEmail': 'Continua con Email',
      'nickname': 'Nickname',
      'save': 'Salva',
      'tutorial':
          'Colpisci i colori che scendono sulla loro colonna. Per i colori misti premi INSIEME i due tasti corrispondenti!',
      'comboHint': 'Giallo = Rosso + Verde   Ciano = Verde + Blu   Magenta = Rosso + Blu',
      'loading': 'Caricamento…',
    },
    'es': {
      'play': 'JUGAR',
      'tapToStart': 'Toca para empezar',
      'score': 'Puntos',
      'best': 'Récord',
      'gameOver': 'FIN',
      'newRecord': '¡NUEVO RÉCORD!',
      'retry': 'REINTENTAR',
      'continueAd': 'CONTINUAR (Anuncio)',
      'home': 'INICIO',
      'leaderboard': 'Clasificación',
      'settings': 'Ajustes',
      'global': 'Histórico',
      'daily': 'Hoy',
      'rank': 'Pos.',
      'player': 'Jugador',
      'volume': 'Volumen',
      'music': 'Música',
      'sfx': 'Efectos',
      'language': 'Idioma',
      'haptics': 'Vibración',
      'account': 'Cuenta',
      'signIn': 'Entrar',
      'signOut': 'Salir',
      'guest': 'Invitado',
      'email': 'Email',
      'password': 'Contraseña',
      'continueGuest': 'Jugar como invitado',
      'continueGoogle': 'Continuar con Google',
      'continueApple': 'Continuar con Apple',
      'continueEmail': 'Continuar con Email',
      'nickname': 'Apodo',
      'save': 'Guardar',
      'tutorial':
          '¡Pulsa los colores que caen en su columna. Para colores mixtos pulsa los DOS botones a la vez!',
      'comboHint': 'Amarillo = Rojo + Verde   Cian = Verde + Azul   Magenta = Rojo + Azul',
      'loading': 'Cargando…',
    },
  };

  String t(String key) {
    final lang = _data.containsKey(locale.languageCode) ? locale.languageCode : 'en';
    return _data[lang]![key] ?? _data['en']![key] ?? key;
  }
}

class StringsDelegate extends LocalizationsDelegate<Strings> {
  const StringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      Strings.supported.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<Strings> load(Locale locale) async => Strings(locale);

  @override
  bool shouldReload(StringsDelegate old) => false;
}
