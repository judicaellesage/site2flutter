// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;

  //bool check internet
  bool checknet = true;

  @override
  void initState() {
    //checher si la connexion existe
    InternetConnectionChecker().onStatusChange.listen((event) {
      if (event == InternetConnectionStatus.disconnected) {
        setState(() {
          checknet = false;
        });
      } else {
        setState(() {
          checknet = true;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // detect Android back button click
        final controller = webViewController;
        if (controller != null) {
          if (await controller.canGoBack()) {
            controller.goBack();
            return false;
          }
        }
        return true;
      },
      child: SafeArea(
        top: true,
        child: Scaffold(
          body: checknet == true
              ? Column(children: <Widget>[
                  Expanded(
                    child: InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                          url: WebUri(
                              "https://application-abakesfoundation.org/application/")),
                      initialSettings: InAppWebViewSettings(
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                      ),
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      onPermissionRequest: (controller, request) async {
                        final resources = <PermissionResourceType>[];
                        if (request.resources
                            .contains(PermissionResourceType.CAMERA)) {
                          final cameraStatus =
                              await Permission.camera.request();
                          if (!cameraStatus.isDenied) {
                            resources.add(PermissionResourceType.CAMERA);
                          }
                        }
                        if (request.resources
                            .contains(PermissionResourceType.MICROPHONE)) {
                          final microphoneStatus =
                              await Permission.microphone.request();
                          if (!microphoneStatus.isDenied) {
                            resources.add(PermissionResourceType.MICROPHONE);
                          }
                        }
                        // only for iOS and macOS
                        if (request.resources.contains(
                            PermissionResourceType.CAMERA_AND_MICROPHONE)) {
                          final cameraStatus =
                              await Permission.camera.request();
                          final microphoneStatus =
                              await Permission.microphone.request();
                          if (!cameraStatus.isDenied &&
                              !microphoneStatus.isDenied) {
                            resources.add(
                                PermissionResourceType.CAMERA_AND_MICROPHONE);
                          }
                        }

                        return PermissionResponse(
                            resources: resources,
                            action: resources.isEmpty
                                ? PermissionResponseAction.DENY
                                : PermissionResponseAction.GRANT);
                      },
                    ),
                  ),
                ])
              : noInternetPage(),
        ),
      ),
    );
  }

  Widget noInternetPage() {
    return const Center(
      child: Text(
        'Aucune connexion internet',
        style: TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
