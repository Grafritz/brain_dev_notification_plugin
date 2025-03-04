import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'brain_dev_notification_method_channel.dart';

abstract class BrainDevNotificationPlatform extends PlatformInterface {
  /// Constructs a BrainDevNotificationPlatform.
  BrainDevNotificationPlatform() : super(token: _token);

  static final Object _token = Object();

  static BrainDevNotificationPlatform _instance = MethodChannelBrainDevNotification();

  /// The default instance of [BrainDevNotificationPlatform] to use.
  ///
  /// Defaults to [MethodChannelBrainDevNotification].
  static BrainDevNotificationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BrainDevNotificationPlatform] when
  /// they register themselves.
  static set instance(BrainDevNotificationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
