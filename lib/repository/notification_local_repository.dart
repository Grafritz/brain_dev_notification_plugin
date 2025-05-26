import 'dart:io';

import 'package:brain_dev_business/models/notification/payload_model.dart';
import 'package:brain_dev_business/models/notification/response/channel_model.dart';
import 'package:brain_dev_business/models/notification/response/message_notification_model.dart';
import 'package:brain_dev_business/services/sender_notification_local_service.dart';
import 'package:brain_dev_notification/controllers/notification_controller.dart';
import 'package:brain_dev_tools/tools/tools_log.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
// import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationLocalRepository implements SenderNotificationLocalService
{
  //final ApiClient apiClient;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationLocalRepository({
    required this.flutterLocalNotificationsPlugin
  });

  @override
  Future<void> showNotification( { required /*RemoteMessage*/ message }) async {
    try{
      MessageNotificationModel notify = MessageNotificationModel();
      if( message.data.isNotEmpty ){
        notify = MessageNotificationModel.fromJsonData(message.data);
      }else{
        notify = MessageNotificationModel.parseNotification(message.notification);
      }
      logCat('NotificationRepository::showNotification title: ${notify.title} / body:${notify.body} / image:${notify.imagePath} / payload:${notify.payload}');
      logCat('NotificationRepository::showNotification channelId: ${notify.channel.id} / channelName:${notify.channel.name} / channelDescription:${notify.channel.description}');

      if(notify.imagePath!='' && notify.imagePath.isNotEmpty) {
        try{
          await showBigPictureNotificationHiddenLargeIcon(mNotif: notify );
        }catch(e) {
          await showBigTextNotification(mNotif: notify );
        }
      }else {
        await showBigTextNotification(mNotif: notify );
      }
    }catch(ex, trace){
      logError(ex, trace: trace, position: 'showNotification');
    }
  }

  @override
  Future<void> showBigTextNotification({ required MessageNotificationModel mNotif }) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      mNotif.body, htmlFormatBigText: true,
      contentTitle: mNotif.title, htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      mNotif.channel.id,
      mNotif.channel.name,
      channelDescription: mNotif.channel.description,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      styleInformation: bigTextStyleInformation,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    //var darwinNotificationDetails = const DarwinNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, );
    await flutterLocalNotificationsPlugin.show(mNotif.id, mNotif.title, mNotif.body, platformChannelSpecifics, payload: mNotif.payload.jsonEncodeString);
  }

  @override
  Future<void> showBigPictureNotificationHiddenLargeIcon({ required MessageNotificationModel mNotif }) async {
    final String largeIconPath = await downloadAndSaveFile(url: mNotif.imagePath, fileName: 'largeIcon');
    final String bigPicturePath = await downloadAndSaveFile(url: mNotif.imagePath, fileName: 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: mNotif.title, htmlFormatContentTitle: true,
      summaryText: mNotif.body, htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      mNotif.channel.id,
      mNotif.channel.name,
      channelDescription: mNotif.channel.description,
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      priority: Priority.max, playSound: true,
      importance: Importance.max,
      styleInformation: bigPictureStyleInformation,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(mNotif.id, mNotif.title, mNotif.body, platformChannelSpecifics, payload: mNotif.payload.jsonEncodeString);
  }

  @override
  Future<void> showTextNotification({ required MessageNotificationModel mNotif }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      mNotif.channel.id,
      mNotif.channel.name,
      channelDescription: mNotif.channel.description,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(mNotif.id, mNotif.title, mNotif.body, platformChannelSpecifics, payload: mNotif.payload.jsonEncodeString);
  }

  int id=1;
  @override
  Future<void> showNotificationDemo() async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails('your channel id', 'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
        id++, 'plain title', 'plain body', notificationDetails,
        payload: 'item x');
  }
  /*Future<String> downloadAndSaveFile2({ required String url, required String fileName}) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    var response = await apiClient.getData(url,fName: 'downloadAndSaveFile');
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }*/
  static Future<String> downloadAndSaveFile({ required String url, required String fileName}) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<Response?> getNotificationList() async {
    return null;//await apiClient.getData(ApiConstant.urlApiNotification,fName: 'getNotificationList');
  }

  @override
  Future myBackgroundMessageHandler(message) async {
    await myBackgroundMessageHandler(/*RemoteMessage*/ message);
  }

  //region [  ]
  @override
  Future<void> cancelNotification({required int id }) async {
    try {
      await flutterLocalNotificationsPlugin.cancel( id );
    }catch(ex, trace){
      logError(ex, trace: trace, position: 'cancelNotification()');
    }
  }

  @override
  Future<void> cancelAllNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    }catch(ex, trace){
      logError(ex, trace: trace, position: 'cancelAllNotification()');
    }
  }

  @override
  Future<void> activateNotification({required String time, required PayLoadModel payLoad, ChannelModel? channel }) async
  {
    try{
      ChannelModel chan = channel??ChannelModel();
      await flutterLocalNotificationsPlugin.zonedSchedule(
          payLoad.notificationId,
          payLoad.titre,//'msg_do_not_forget_to_read_bible_plan'.tr,// (${'label_stay_on_track'.tr})',
          payLoad.description,// ${payLoad.description.toLowerCase()}',

          payload: payLoad.jsonEncodeString,
          scheduledDateTime(timeReminder: time),
          NotificationDetails(
              android: AndroidNotificationDetails(
                chan.id,
                chan.name,
                channelDescription: chan.description,
                // actions: <AndroidNotificationAction>[
                //   AndroidNotificationAction('id_1', 'Action 1'),
                //   AndroidNotificationAction('id_2', 'Action 2'),
                //   AndroidNotificationAction('id_3', 'Action 3'),
                // ],
              ),
              iOS: DarwinNotificationDetails()
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time
      );
    }catch(ex, trace){
      logError(ex, trace: trace, position: 'activateNotification');
    }
  }

  //region [ Local Notification ]
  TimeOfDay strToTimeOfDay(String tod) {
    final format = DateFormat.jm(); //"6:00 AM"
    return TimeOfDay.fromDateTime(format.parse(tod));
  }
  tz.TZDateTime scheduledDateTime({ required String timeReminder }) {
    TimeOfDay timeOfDay = strToTimeOfDay( timeReminder );
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    //var now = DateTime.now();
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
  //endregion

  @override
  Future<void> repeatNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
        'repeating channel id',
        'repeating channel name',
        channelDescription: 'repeating description');
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails,);

    logCat('001.-repeatNotification() : $id');
    String titre='TITRE';
    String description='description';
    await flutterLocalNotificationsPlugin.periodicallyShow(
      id++,
      '${'msg_do_not_forget_to_read_bible_plan'.tr} (${'label_stay_on_track'.tr})',
      ' [ $titre ] ${description.toLowerCase()}',
      payload: '{"action":"PDL", "codeLecture":"TEST123"}',
      RepeatInterval.everyMinute,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    logCat('002.-repeatNotification() : $id');
  }
  //endregion

}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse details)
{
  logCat( 'NotificationRepository:: IN onDidReceiveBackgroundNotificationResponse' );
  logCat( details );
  Get.find<NotificationController>().getNavigatorPushNamed(notificationResponse: details);
}

Future myBackgroundMessageHandler(/*RemoteMessage*/ message) async {
  logCat("NotificationRepository:: myBackgroundMessageHandler: ${message.notification?.title}/${message.notification?.body}/${message.notification?.titleLocKey}");
  var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');//'notification_icon');
  var iOSInitialize = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: (id, title, body, payload) {
      //   logCat("01.-NotificationRepository:: DarwinInitializationSettings .::. myBackgroundMessageHandler : id: $id / $title / $body / $payload");
      // }
      );
  var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  // Get.find<NotificationController>().showNotification(message: message);
  NotificationLocalRepository(flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin).showNotification(message: message);
}