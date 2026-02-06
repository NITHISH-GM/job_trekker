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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMXlvlz2KChaI-pLSUQkM41W_uX3BSQLQ',
    appId: '1:262880009344:web:8a2fadef67f9b633b55a65',
    messagingSenderId: '262880009344',
    projectId: 'job-trekker-36752',
    authDomain: 'job-trekker-36752.firebaseapp.com',
    storageBucket: 'job-trekker-36752.firebasestorage.app',
    measurementId: 'G-Q0BY9GRMXE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMXlvlz2KChaI-pLSUQkM41W_uX3BSQLQ',
    appId: '1:262880009344:android:257536940f900f53b55a65', // Get this from Firebase Console > Android App
    messagingSenderId: '262880009344',
    projectId: 'job-trekker-36752',
    storageBucket: 'job-trekker-36752.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDMXlvlz2KChaI-pLSUQkM41W_uX3BSQLQ',
    appId: '1:262880009344:ios:PASTE_YOUR_IOS_APP_ID_HERE', // Get this from Firebase Console > iOS App
    messagingSenderId: '262880009344',
    projectId: 'job-trekker-36752',
    storageBucket: 'job-trekker-36752.firebasestorage.app',
    iosBundleId: 'com.example.job_trekker',
  );
}
