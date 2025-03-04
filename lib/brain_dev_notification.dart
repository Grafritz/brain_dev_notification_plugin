import 'package:brain_dev_notification/config/dependencies_tools.dart';
import 'package:brain_dev_notification/controllers/notification_controller.dart';
import 'package:get/get.dart';

import 'brain_dev_notification_platform_interface.dart';

initBrainDevLocalNotification() async {
  initBrainDevLocalNotificationDependencies();
  await Get.find<NotificationController>().init();
  await Get.find<NotificationController>().configureLocalTimeZone();
}

class BrainDevNotification {
  Future<String?> getPlatformVersion() {
    return BrainDevNotificationPlatform.instance.getPlatformVersion();
  }
}
