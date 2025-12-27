
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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDZkzVl4-4eTe8M2QkOuWQoM94ltY-wPXU',
    appId: '1:1091899305600:web:b45ccbfc5d60b44544c065',
    messagingSenderId: '1091899305600',
    projectId: 'moneyrota-5529d',
    authDomain: 'moneyrota-5529d.firebaseapp.com',
    storageBucket: 'moneyrota-5529d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhhueheI4DLhBbV_ILd_l6Hs72yMw7h78',
    appId: '1:1091899305600:android:693d034b3a69cc7144c065',
    messagingSenderId: '1091899305600',
    projectId: 'moneyrota-5529d',
    storageBucket: 'moneyrota-5529d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3p1ElBrnMst7D4SNyivx689hGKwkfC5E',
    appId: '1:1091899305600:ios:5427d7db10557ec844c065',
    messagingSenderId: '1091899305600',
    projectId: 'moneyrota-5529d',
    storageBucket: 'moneyrota-5529d.firebasestorage.app',
    iosBundleId: 'com.example.moneyRota',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC3p1ElBrnMst7D4SNyivx689hGKwkfC5E',
    appId: '1:1091899305600:ios:5427d7db10557ec844c065',
    messagingSenderId: '1091899305600',
    projectId: 'moneyrota-5529d',
    storageBucket: 'moneyrota-5529d.firebasestorage.app',
    iosBundleId: 'com.example.moneyRota',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDZkzVl4-4eTe8M2QkOuWQoM94ltY-wPXU',
    appId: '1:1091899305600:web:c1c84079cebc84b244c065',
    messagingSenderId: '1091899305600',
    projectId: 'moneyrota-5529d',
    authDomain: 'moneyrota-5529d.firebaseapp.com',
    storageBucket: 'moneyrota-5529d.firebasestorage.app',
  );
}
