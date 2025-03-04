import 'dart:io';
import 'package:brain_dev_business/models/notification/notification_model.dart';
import 'package:brain_dev_tools/config/api/api_constant.dart';
import 'package:brain_dev_tools/Repository/http_repo/http_client_repository.dart';
import 'package:brain_dev_tools/tools/tools_log.dart';
import 'package:brain_dev_tools/tools/validation/type_safe_conversion.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class NotificationHelper {

  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');//'notification_icon');
    var iOSInitialize = const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        // onDidReceiveLocalNotification: (id, title, body, payload) {
        //   logCat("NotificationHelper.::.initialize: id: $id / $title / $body / $payload");
        // }
    );
    var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  }

  Future<void> showNotification( { required /*RemoteMessage*/ message, required FlutterLocalNotificationsPlugin fln, bool data=false}) async {
    try{
      MessageNotification notify = MessageNotification();
      if(data) {
        notify = MessageNotification.fromJson(message.data);
      }else{
        notify = MessageNotification.parseNotification(message.notification);
      }
      logCat('title: ${notify.title} / body:${notify.body} / image:${notify.image} / payload:${notify.payload}');

      if(notify.image!='' && notify.image.isNotEmpty) {
        try{
          await showBigPictureNotificationHiddenLargeIcon(title: notify.title, body: notify.body, payload: notify.payload, imagePath: notify.image, flutterLocalNotificationsPlugin: fln);
        }catch(e) {
          await showBigTextNotification(title: notify.title, body: notify.body, payload: notify.payload, flutterLocalNotificationsPlugin: fln);
        }
      }else {
        await showBigTextNotification(title: notify.title, body: notify.body, payload: notify.payload, flutterLocalNotificationsPlugin: fln);
      }
    }catch(ex, trace){
      logError(ex, trace: trace, position: 'showNotification');
    }
  }
  Future<void> showTextNotification({ String? title, String? body, String? payload, required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'CCG_delivery', 'CCG_delivery name', playSound: true,
      importance: Importance.max, priority: Priority.max, sound: RawResourceAndroidNotificationSound('notification'),
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: payload);
  }
  Future<void> showBigTextNotification({String? title, required String body, String? payload, required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin}) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body, htmlFormatBigText: true,
      contentTitle: title, htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'CCG_delivery channel id', 'CCG_delivery name', importance: Importance.max,
      styleInformation: bigTextStyleInformation, priority: Priority.max, playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    //var darwinNotificationDetails = const DarwinNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: payload);
  }
  Future<void> showBigPictureNotificationHiddenLargeIcon({String? title, String? body, String? payload, required String imagePath, required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin}) async {
    final String largeIconPath = await downloadAndSaveFile(url: imagePath, fileName: 'largeIcon');
    final String bigPicturePath = await downloadAndSaveFile(url: imagePath, fileName: 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: title, htmlFormatContentTitle: true,
      summaryText: body, htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'CCG_delivery', 'CCG_delivery name',
      largeIcon: FilePathAndroidBitmap(largeIconPath), priority: Priority.max, playSound: true,
      styleInformation: bigPictureStyleInformation, importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: payload);
  }
  Future<String> downloadAndSaveFile({ required String url, required String fileName}) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    var response = await HttpClientRepository().getData(url,fName: 'downloadAndSaveFile');
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  //region [ OLD TO DELETE ]
  static Future<void> showNotification2( { required /*RemoteMessage*/ message, required FlutterLocalNotificationsPlugin fln, bool data=false}) async {
    String? title;
    String? body;
    String? orderID;
    String? image;
    if(data) {
      var info = MessageNotification.fromJson(message.data);
      title = info.title;//message.data['title'];
      body = info.body;//message.data['body'];
      orderID = info.title;//message.data['order_id'];
      image = info.image;
      // image = (message.data['image'] != null && message.data['image'].isNotEmpty)
      //     ? message.data['image'].startsWith('http') ? message.data['image']
      //     : '${ApiConstant.urlWebServer}/storage/app/public/notification/${message.data['image']}' : null;
    }else {
      title = message.notification?.title;
      body = message.notification?.body;
      orderID = message.notification?.titleLocKey;
      if(GetPlatform.isAndroid) {
        String imageUrl = TypeSafeConversion.nullSafeString( message.notification?.android?.imageUrl );
        image = (imageUrl.isNotEmpty)
            ? imageUrl.startsWith('http') ? imageUrl
            : '${ApiConstantDev.urlWebServer}/storage/app/public/notification/$imageUrl' : null;
      }else if(GetPlatform.isIOS) {
        String imageUrl = TypeSafeConversion.nullSafeString( message.notification?.apple?.imageUrl );
        image = (imageUrl.isNotEmpty)
            ? imageUrl.startsWith('http') ? imageUrl
            : '${ApiConstantDev.urlWebServer}/storage/app/public/notification/$imageUrl' : null;
      }
    }

    if(image != null && image.isNotEmpty) {
      try{
        await showBigPictureNotificationHiddenLargeIcon2(title??'', body??'', orderID??'', image, fln);
      }catch(e) {
        await showBigTextNotification2(title??'', body??'', orderID??'', fln);
      }
    }else {
      await showBigTextNotification2(title??'', body??'', orderID??'', fln);
    }
  }
  static Future<void> showTextNotification2(String title, String body, String orderID, FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'CCG_delivery', 'CCG_delivery name', playSound: true,
      importance: Importance.max, priority: Priority.max, sound: RawResourceAndroidNotificationSound('notification'),
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: orderID);
  }
  static Future<void> showBigTextNotification2(String title, String body, String orderID, FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body, htmlFormatBigText: true,
      contentTitle: title, htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'CCG_delivery channel id', 'CCG_delivery name', importance: Importance.max,
      styleInformation: bigTextStyleInformation, priority: Priority.max, playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: orderID);
  }
  static Future<void> showBigPictureNotificationHiddenLargeIcon2(String title, String body, String orderID, String image, FlutterLocalNotificationsPlugin fln) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: title, htmlFormatContentTitle: true,
      summaryText: body, htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'CCG_delivery', 'CCG_delivery name',
      largeIcon: FilePathAndroidBitmap(largeIconPath), priority: Priority.max, playSound: true,
      styleInformation: bigPictureStyleInformation, importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: orderID);
  }
  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
  //endregion
}

Future<dynamic> myBackgroundMessageHandler(/*RemoteMessage*/ message) async {
  logCat("myBackgroundMessageHandler: ${message.notification?.title}/${message.notification?.body}/${message.notification?.titleLocKey}");
  var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');//'notification_icon');
  var iOSInitialize = const DarwinInitializationSettings(
                        requestAlertPermission: true,
                        requestBadgePermission: true,
                        requestSoundPermission: true,
                        // onDidReceiveLocalNotification: (id, title, body, payload) {
                        //   logCat("01.-DarwinInitializationSettings .::. myBackgroundMessageHandler : id: $id / $title / $body / $payload");
                        // }
  );

  var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  NotificationHelper().showNotification(message: message, fln: flutterLocalNotificationsPlugin, data: true);
}