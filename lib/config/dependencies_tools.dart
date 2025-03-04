
import 'package:brain_dev_business/services/sender_notification_local_service.dart';
import 'package:brain_dev_notification/controllers/notification_controller.dart';
import 'package:brain_dev_notification/repository/notification_local_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

initBrainDevLocalNotificationDependencies() async
{
  //TODO: Very important to implement the dependencies  [ brain_dev_tools ] before
  //TODO: Very important to implement the dependencies  [ brain_dev_business ] before

  //region [ Flutter Local Notifications Plugin ]
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
  DarwinInitializationSettings initializationIos = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    // onDidReceiveLocalNotification: (id, title, body, payload) {
    //   logCat("DarwinInitializationSettings .::. onDidReceiveLocalNotification: id: $id / $title / $body / $payload");
    // },
  );
  //endregion

  Get.lazyPut(() => flutterLocalNotificationsPlugin);
  Get.lazyPut(() => initializationSettingsAndroid);
  Get.lazyPut(() => initializationIos);
 //endregion

  //region [ Inject Service No ]
  // final SenderNotificationLocalService senderNotificationLocalService = NotificationLocalRepository(flutterLocalNotificationsPlugin: Get.find());
  // Get.lazyPut(() => senderNotificationLocalService);
  //endregion

  //region Repository
  Get.lazyPut<SenderNotificationLocalService>(() => NotificationLocalRepository(
      flutterLocalNotificationsPlugin: Get.find()
  ), fenix: true);
  //endregion

  //region Controller
  Get.lazyPut(
          () => NotificationController(
          apiClient: Get.find(),
          senderNotificationLocalService: Get.find(),
          //notificationRepo: Get.find(),
          // userRepository: Get.find(),
          // firebaseMessaging: Get.find(),
          flutterLocalNotificationsPlugin: Get.find(),
          initializationSettingsAndroid: Get.find(),
          initializationIos: Get.find(),
          mySharedPref: Get.find()
      ),
      fenix: true);
  //Get.put<UserService>(FirebaseUserService(userController: Get.find<UserController>()));
  //endregion
}
