// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD2AsPn2ovZpTUaA4BbJPfsYgd96wlwoq4',
    appId: '1:629365692507:android:65cfbcb1a1795fd82e077e',
    messagingSenderId: '629365692507',
    projectId: 'bus-tracking-system-e41ba',
    databaseURL: 'https://bus-tracking-system-e41ba-default-rtdb.firebaseio.com',
    storageBucket: 'bus-tracking-system-e41ba.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDr4YQ3EMpri23hU6nfHFJJVLLY7t-Hhvs',
    appId: '1:629365692507:ios:9c502eadd6821beb2e077e',
    messagingSenderId: '629365692507',
    projectId: 'bus-tracking-system-e41ba',
    databaseURL: 'https://bus-tracking-system-e41ba-default-rtdb.firebaseio.com',
    storageBucket: 'bus-tracking-system-e41ba.firebasestorage.app',
    iosClientId: '629365692507-ltsattquen7b9g79piqtbfoftiolasls.apps.googleusercontent.com',
    iosBundleId: 'com.example.schoolBusTrackingApp',
  );

}