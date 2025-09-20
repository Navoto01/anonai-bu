// lib/firebase_options.dart

// Figyelem: Ezt a fájlt manuálisan hoztuk létre, mert a flutterfire CLI hibát dobott.
// A benne lévő adatok a Firebase projekted beállításaiból származnak.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      // Ha iOS-re is fejlesztesz, itt kell majd megadnod az iOS specifikus opciókat.
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for an iOS app.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for a macOS app.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for a Windows app.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // A WEB platform adatai a megadott `firebaseConfig` alapján
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDQdLqs-V99dbHYcZVgpNlEPgsaVEByX6E',
    appId: '1:1066766744610:web:98f03bb06d354de1695e7b',
    messagingSenderId: '1066766744610',
    projectId: 'voidnet-anonlab',
    authDomain: 'voidnet-anonlab.firebaseapp.com',
    databaseURL: 'https://voidnet-anonlab-default-rtdb.firebaseio.com',
    storageBucket: 'voidnet-anonlab.appspot.com',
    measurementId: 'G-37HG5B7PRE',
  );

  // Az ANDROID platform adatai.
  // Az `appId`-t neked kell beírnod, miután regisztráltad az appot a Firebase Console-on.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQdLqs-V99dbHYcZVgpNlEPgsaVEByX6E',
    appId: '1:1066766744610:android:2963fd40ccc9d770695e7b',
    messagingSenderId: '1066766744610',
    projectId: 'voidnet-anonlab',
    databaseURL: 'https://voidnet-anonlab-default-rtdb.firebaseio.com',
    storageBucket: 'voidnet-anonlab.appspot.com',
  );
}