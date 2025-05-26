import 'dart:convert';

import 'package:brain_dev_business/controllers/business_controller.dart';
import 'package:brain_dev_business/models/notification/payload_model.dart';
import 'package:brain_dev_business/models/notification/response/channel_model.dart';
import 'package:brain_dev_business/models/users_model.dart';
import 'package:brain_dev_business/services/sender_notification_local_service.dart';
import 'package:brain_dev_notification/repository/notification_local_repository.dart';
// import 'package:brain_dev_notification/repository/notification_repository.dart';
import 'package:brain_dev_tools/config/api/api_client.dart';
import 'package:brain_dev_tools/dao/my_shared_preferences.dart';
import 'package:brain_dev_tools/tools/check_platform.dart';
import 'package:brain_dev_tools/tools/constant.dart';
import 'package:brain_dev_tools/tools/tools_log.dart';
import 'package:brain_dev_tools/tools/validation/type_safe_conversion.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

class NotificationController extends GetxController implements GetxService {

  //region [  ]
  ApiClient apiClient;
  //final NotificationLocalRepository notificationRepo;
  final SenderNotificationLocalService senderNotificationLocalService;
  MySharedPref mySharedPref;
  //endregion

  //region [  ]
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin; //= FlutterLocalNotificationsPlugin();
  final AndroidInitializationSettings initializationSettingsAndroid; //= const AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationIos; /*= DarwinInitializationSettings(
    requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true,
    onDidReceiveLocalNotification: (id, title, body, payload) {

    },
  );*/
  //endregion
  /// For local_notification id
  //int _count = 0;
  bool _started = false;
  UserModel userConnected = Get.find<BusinessController>().userConnected;
  //UserRepository userRepository;

  NotificationController({
    required this.apiClient,
    required this.mySharedPref,
    required this.senderNotificationLocalService,
    //required this.notificationRepo,
    //required this.userRepository,
    //required this.firebaseMessaging,
    required this.flutterLocalNotificationsPlugin,
    required this.initializationSettingsAndroid,
    required this.initializationIos }){
    if (!_started) {
      initNotification();
      //initFirebaseMessaging();
      //updateToken();
      _started = true;
    }
  }

  init(){
    if (!_started) {
      initLocalNotification();
      //initFirebaseMessaging();
      _started = true;
    }
  }
  Future<void> configureLocalTimeZone() async {
    if (CheckPlatform().isWeb || CheckPlatform().isLinux) {
      return;
    }
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

//region [ Firebase ]
  //region [ FIREBASE TOKEN ]
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;
  Future<void> requestPermissions() async {
    if (CheckPlatform().isApple) {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    if (CheckPlatform().isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      bool? granted = await androidImplementation?.requestNotificationsPermission();
      _notificationsEnabled =  TypeSafeConversion.nullSafeBool( granted );
    }
  }
  void iOSPermission() {
    requestPermissions();
  }
  //endregion
//endregion

//region [ LocalNotification ]
  Future checkDidNotificationLaunchApp() async {
    try {
      // Récupérer la charge utile de la notification si l'application est lancée à partir d'un clic sur une notification
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        //initialRoute = notificationAppLaunchDetails!.payload;

        logCat('NotificationController: IN onDidReceiveNotificationResponse');
        getNavigatorPushNamed(notificationResponse: notificationAppLaunchDetails?.notificationResponse);
      }
    } catch (ex, trace) {
      logError(ex, trace: trace, position: 'catch::checkDidNotificationLaunchApp');
    }
  }
  Future initLocalNotification() async
  {
    logCat('NotificationController: ON initLocalNotification()');

    AndroidInitializationSettings initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings initializationIos = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      //onDidReceiveLocalNotification: onDidReceiveLocalNotificationIos,
      // notificationCategories:[
      //   DarwinNotificationCategory(
      //     'demoCategory',
      //     actions: <DarwinNotificationAction>[
      //       DarwinNotificationAction.text('identifier', 'title', buttonTitle: '', )
      //       //DarwinNotificationAction('id_1', 'Action 1'),
      //
      //       // DarwinNotificationAction(
      //       //   'id_2',
      //       //   'Action 2',
      //       //   options: <DarwinNotificationActionOption>{
      //       //     DarwinNotificationActionOption.destructive,
      //       //   },
      //       // ),
      //
      //       // DarwinNotificationAction(
      //       //   'id_3',
      //       //   'Action 3',
      //       //   options: <DarwinNotificationActionOption>{
      //       //     DarwinNotificationActionOption.foreground,
      //       //   },
      //       // ),
      //     ],
      //     // options: <DarwinNotificationCategoryOption>{
      //     //   DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      //     // },
      //   )
      // ]
    );
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationIos,
      macOS: initializationIos,);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission;
    //NotificationHelper(flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin);
  }
  Future initOnDidReceiveBackgroundNotificationResponse() async {
    logCat('NotificationController: ON initOnDidReceiveBackgroundNotificationResponse()');

    AndroidInitializationSettings initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings initializationIos = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      //onDidReceiveLocalNotification: onDidReceiveLocalNotificationIos,
      // notificationCategories:[
      //   DarwinNotificationCategory(
      //     'demoCategory',
      //     actions: <DarwinNotificationAction>[
      //       DarwinNotificationAction.text('identifier', 'title', buttonTitle: '', )
      //     ],
      //     // options: <DarwinNotificationCategoryOption>{
      //     //   DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      //     // },
      //   )
      // ]
    );
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationIos,
      macOS: initializationIos,);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    //NotificationHelper(flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin);
  }
  void onDidReceiveNotificationResponse(NotificationResponse details) {
    logCat( 'NotificationController: IN onDidReceiveNotificationResponse' );
    logCat( details );
    getNavigatorPushNamed(notificationResponse: details);
  }
//endregion

//region [ Firebase ]

  Future initNotification() async {
    logCat('ON initNotification()');
    InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationIos);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        logCat( 'IN onDidReceiveNotificationResponse' );
        logCat( details.toString() );
    },);
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    //NotificationHelper(flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin);
  }
  /// This method will be called on tap of the notification which came when app was in foreground
  ///
  /// Firebase messaging does not push notification in notification panel when app is in foreground.
  /// To send the notification when app is in foreground we will use flutter_local_notification
  /// to send notification which will behave similar to firebase notification
  Future<void> onMessage(/*RemoteMessage*/ message) async {
    logCat('IN onMessage');
    senderNotificationLocalService.showNotification(message: message);//, data:true);
  }

  /// This method will be called on tap of the notification which came when app was closed
  Future<void>? onLaunch(/*RemoteMessage*/ message) {
    logCat('onLaunch: $message');
    try {
      if (checkPlatform.isIOS) {
        message = modifyNotificationJson(message.data);
      }
    } catch (e) {
      logCat(e);
    }
    performActionOnNotification(message);
    return null;
  }

  handleNotification( data, bool push) {
    var messageJson = json.decode(data['message']);
    logCat('decoded message: $messageJson');
    //var message = m.Message.fromJson(messageJson);
    // Provider.of<ConversationProvider>(context, listen: false).addMessageToConversation(message.conversationId, message);
  }

  /// This method will modify the message format of iOS Notification Data
  /*RemoteMessage*/ modifyNotificationJson(message) {
    message['data'] = Map.from(message ?? {});
    message['notification'] = message['aps']['alert'];
    logCat(message);
    return message;
  }

  /// We want to perform same action of the click of the notification. So this common method will be called on
  /// tap of any notification (onLaunch / onMessage / onResume)
  void performActionOnNotification(message) {
    //NotificationsBloc.instance.newNotification(message);
    logCat(message);
  }
//endregion

  void onDidReceiveLocalNotificationIos(int id, String? title, String? body, String? payload) async
  {
    // display a dialog with the notification details, tap ok to go to another page
    logCat( 'NotificationController: IN onDidReceiveLocalNotification Ios' );
    logCat('NotificationController:  id: $id / $title / $body / $payload');
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title??''),
        content: Text(body??''),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();

            },
          )
        ],
      ),
    );
  }

  getNavigatorPushNamed({ required NotificationResponse? notificationResponse }) async {
    try {
      if (notificationResponse!= null ) {
        if (notificationResponse.payload != null && notificationResponse.payload!.isNotEmpty) {
          // PayLoadModel payLoad = PayLoadModel().fromJson(notificationResponse.payload!);
          // switch (payLoad.pageUrl) {
          //   case RouteHelper.homeDefault:
          //   case RouteHelper.routeBooks:
          //     BooksController booksController = Get.find<BooksController>();
          //     booksController.getBooks();
          //     String liv = TypeSafeConversion.nullSafeString(payLoad.dayVerses?.bookOsis);
          //     int chap = TypeSafeConversion.nullSafeInt( payLoad.dayVerses?.chapter );
          //     int ver = TypeSafeConversion.nullSafeInt( payLoad.dayVerses?.verse );
          //     Tools.logCat('routeBooks: liv: $liv | chap:$chap | ver:$ver');
          //     var bookSelected = BooksModel();
          //     bookSelected = booksController.booksList![booksController.booksList!.indexWhere((e) => e.osis == liv)];
          //     bookSelected.chaptersSelected = chap;
          //     bookSelected.versetSelected = ver;
          //     booksController.setBookSelected( bookSelected );
          //     //RouteHelper.navHome();
          //     break;
          //   case RouteHelper.routePlanDeLectureDetails:
          //     String codeSubscription = TypeSafeConversion.nullSafeString(payLoad.codePage);
          //     Tools.logCat('01-codeSubscription: $codeSubscription');
          //     RouteHelper.navPlanDeLectureDetails(codeLecture: '', codeSubscription: codeSubscription);
          //     break;
          //   default:
          //     Get.toNamed( payLoad.pageUrl );
          //     break;
          // }
        }
      }
    } catch (ex, trace) {
      logError(ex, trace: trace, position: 'catch::getNavigatorPushNamed');
    }
  }

  // bool _isLoading = false;
  // bool get isLoading => _isLoading;

  //List<Notifications> _notificationList=[];
  //List<Notifications> get notificationList => _notificationList;
  // Future getNotificationList() async{
  //   _notificationList = [];
  //   Response response = await notificationRepo.getNotificationList();
  //   if(response.body != null && response.body != {} && response.statusCode == 200){
  //     response.body['notifications'].forEach((notify) {_notificationList.add(Notifications.fromJson(notify));});
  //     _isLoading = false;
  //     update();
  //   }else {
  //     //ApiChecker.checkApi(response);
  //     _isLoading = false;
  //   }
  // }

  //region [ NOTIFICATIONS ]
  String _timeReminderReadPlan='08:00 AM';
  String get timeReminderReadPlan => _timeReminderReadPlan;
  getTimeReminderReadPlan() async {
    _timeReminderReadPlan = await mySharedPref.getTimeReminderReadPlan();
    _timeReminderReadPlan='08:00 AM';
    update();
  }
  int id = 0;

  Future<void> fetchPendingNotificationRequest() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
    await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (PendingNotificationRequest request in pendingNotificationRequests) {
      final int id = request.id; // Identifiant de la notification
      final String? title = request.title; // Titre de la notification
      final String? body = request.body; // Corps de la notification
      // Autres informations disponibles...
      logCat('001-fetchPendingNotificationRequest :: Notification - ID: $id, Title: $title, Body: $body');
    }
  }
  Future<void> fetchActiveNotifications() async {
    final List<ActiveNotification> activeNotifications =
    await flutterLocalNotificationsPlugin.getActiveNotifications();

    for (ActiveNotification notification in activeNotifications) {
      final int id = notification.id??0; // Identifiant de la notification
      final String? title = notification.title; // Titre de la notification
      final String? body = notification.body; // Corps de la notification
      // Autres informations disponibles...
      logCat('002-fetchActiveNotifications :: Active Notification - ID: $id, Title: $title, Body: $body');
    }
  }

  Future<void> activateNotification({
    required String time,
    required int notificationId,
    required String codeLecture, String? codeSubscription,
    required String titre,
    required String description,
    String imageBg='${Constant.assetsBiblePath}b1.jpg',
    required String pageUrl,
    ChannelModel? channel,
  }) async
  {
    try{
      _timeReminderReadPlan = time;
      PayLoadModel payLoad = PayLoadModel();
      payLoad.notificationId = notificationId;
      payLoad.codePage = codeLecture;
      payLoad.pageUrl = pageUrl;
      payLoad.titre = titre;
      payLoad.description = description;
      payLoad.imageBg = imageBg;
      ChannelModel chan = channel??ChannelModel();

      await flutterLocalNotificationsPlugin.zonedSchedule(
          payLoad.notificationId,
          'msg_do_not_forget_to_read_bible_plan'.tr,// (${'label_stay_on_track'.tr})',
          ' [ ${payLoad.titre} ]',// ${payLoad.description.toLowerCase()}',

          payload: payLoad.jsonEncodeString,
          _nextInstanceOfTenAM(),
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
          matchDateTimeComponents: DateTimeComponents.time);

    }catch(ex, trace){
      logError(ex, trace: trace, position: 'ERROR:Utilities.Exception: activateNotification()');
    }
  }

  Future<void> cancelNotification({required int id }) async {
    try {
      await flutterLocalNotificationsPlugin.cancel( id );
    }catch(ex, trace){
      logError(ex, trace: trace, position: 'cancelNotification()');
    }
  }
  Future<void> cancelAllNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    }catch(ex, trace){
      logError(ex, trace: trace, position: 'cancelAllNotification()');
    }
  }

  Future<void> repeatNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
        'repeating channel id',
        'repeating channel name',
        channelDescription: 'repeating description');

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    logCat('01.-repeatNotification()');
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
    logCat('02.-repeatNotification() : $id');
  }

  //region [ Local Notification ]
  TimeOfDay stringToTimeOfDay(String tod) {
    final format = DateFormat.jm(); //"6:00 AM"
    return TimeOfDay.fromDateTime(format.parse(tod));
  }
  tz.TZDateTime _nextInstanceOfTenAM() {
    TimeOfDay timeOfDay = stringToTimeOfDay( _timeReminderReadPlan );
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    //var now = DateTime.now();
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
  //endregion
  //endregion
}