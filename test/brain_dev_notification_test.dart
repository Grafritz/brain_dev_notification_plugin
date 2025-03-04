import 'package:flutter_test/flutter_test.dart';
import 'package:brain_dev_notification/brain_dev_notification.dart';
import 'package:brain_dev_notification/brain_dev_notification_platform_interface.dart';
import 'package:brain_dev_notification/brain_dev_notification_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBrainDevNotificationPlatform
    with MockPlatformInterfaceMixin
    implements BrainDevNotificationPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BrainDevNotificationPlatform initialPlatform = BrainDevNotificationPlatform.instance;

  test('$MethodChannelBrainDevNotification is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBrainDevNotification>());
  });

  test('getPlatformVersion', () async {
    BrainDevNotification brainDevNotificationPlugin = BrainDevNotification();
    MockBrainDevNotificationPlatform fakePlatform = MockBrainDevNotificationPlatform();
    BrainDevNotificationPlatform.instance = fakePlatform;

    expect(await brainDevNotificationPlugin.getPlatformVersion(), '42');
  });
}
