import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'brain_dev_notification_platform_interface.dart';

/// An implementation of [BrainDevNotificationPlatform] that uses method channels.
class MethodChannelBrainDevNotification extends BrainDevNotificationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('brain_dev_notification');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
