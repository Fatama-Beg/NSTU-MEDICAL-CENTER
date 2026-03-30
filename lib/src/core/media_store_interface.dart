// Conditional import
export 'media_store_launcher.dart'
    if (dart.library.html) 'media_store_launcher_stub.dart';
