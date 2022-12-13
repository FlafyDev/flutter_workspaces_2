import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_workspaces_2/search_result.dart';
import 'package:flutter_workspaces_2/workspaces_line.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hyprland_ipc/hyprland_ipc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'app_search.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final hyprlandIPCProvider = FutureProvider((ref) => HyprlandIPC.fromInstance());
final activeWorkspaceProvider = StreamProvider<int>((ref) async* {
  final ipc = ref.watch(hyprlandIPCProvider);
  if (ipc.value == null) return;

  await for (final event in ipc.value!.eventsStream) {
    if (event is WorkspaceEvent) {
      yield (int.parse(event.workspaceName) - 1);
    }
  }
});

const platform = MethodChannel("general");

void listenToWorkspace(
    HyprlandIPC hyprlandIPC, void Function(int clients) onWorkspace) async {
  final clients = await hyprlandIPC.getClients();
  final workspacesClients = <String, List<int>>{};

  void addAddress(String workspaceName, int address) {
    if (workspacesClients.containsKey(workspaceName)) {
      workspacesClients[workspaceName]!.add(address);
    } else {
      workspacesClients[workspaceName] = [address];
    }
  }

  String? removeAddress(int address) {
    String? workName;
    workspacesClients.forEach((workspaceName, addresses) {
      if (workspacesClients[workspaceName]!.remove(address)) {
        workName = workspaceName;
      }
    });
    return workName;
  }

  for (final client in clients) {
    addAddress(client.workspaceName, client.address);
  }

  await for (final event in hyprlandIPC.eventsStream) {
    if (event is OpenWindowEvent) {
      addAddress(event.workspaceName, event.windowAddress);
      onWorkspace(workspacesClients[event.workspaceName]!.length);
    } else if (event is CloseWindowEvent) {
      final workspaceName = removeAddress(event.windowAddress);
      if (workspaceName != null) {
        onWorkspace(workspacesClients[workspaceName]!.length);
      }
    } else if (event is MoveWindowEvent) {
      removeAddress(event.windowAddress);
      addAddress(event.workspaceName, event.windowAddress);
      onWorkspace(workspacesClients[event.workspaceName]!.length);
    } else if (event is WorkspaceEvent) {
      if (!workspacesClients.containsKey(event.workspaceName)) {
        workspacesClients[event.workspaceName] = [];
      }
      onWorkspace(workspacesClients[event.workspaceName]!.length);
    }
  }
}

String randomVaxryQuote() {
  final quotes = <String>[
    "fuck you",
    "oh fuck off I make your entire desktop",
    "I am a kiddo in some random-ass irish dorm",
    "BRO FRANCE BANNED MS OFFICE AND GOOGLE DOCS IN SCHOOLS LMAO L L L L L L L L L L L L L L L L",
    "he he he ha",
    "no",
  ];
  return (quotes..shuffle()).first;
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(context, ref) {
    final appearAnimController = useAnimationController(
      duration: const Duration(milliseconds: 1000),
    );
    final launcherInputController = useTextEditingController();
    final launcherInputFocusNode = useFocusNode();
    final extended = useState(false);

    final activeWorkspace = ref.watch(activeWorkspaceProvider).value ?? 0;
    final hyprlandIPC = ref.watch(hyprlandIPCProvider).valueOrNull;
    final quote = useState(randomVaxryQuote());

    // void awakeOpacity() {
    //   opacityAnimController.value = 1.0;
    //   opacityAnimController.animateTo(0.5, curve: const LongCurve());
    // }

    useEffect(() {
      // awakeOpacity();
      appearAnimController.addListener(() {
        final curve = appearAnimController.status == AnimationStatus.forward
            ? Curves.elasticOut
            : Curves.bounceIn;
        platform.invokeMethod("resize", {
          "height": (Tween<double>(begin: 9, end: 230)
                  .transform(curve.transform(appearAnimController.value)))
              .round(),
        });
        if (appearAnimController.status == AnimationStatus.dismissed) {
          WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
          launcherInputController.value = const TextEditingValue(text: "");
          quote.value = randomVaxryQuote();
        }
      });
      return () {
        appearAnimController.dispose();
      };
    }, []);

    // useEffect(() {
    //   print(hyprlandIPC);
    //   if (hyprlandIPC != null) {
    //     listenToWorkspace(hyprlandIPC, (clients) {
    //       print(clients);
    //       if (clients > 0) {
    //         extended.value = false;
    //       } else {
    //         extended.value = true;
    //       }
    //     });
    //   }
    //   return () {};
    // }, [hyprlandIPC]);

    useEffect(() {
      if (extended.value) {
        if (!appearAnimController.isAnimating ||
            appearAnimController.status != AnimationStatus.forward) {
          appearAnimController.forward();
          platform.invokeMethod("focusable", {"focusable": true});
        }
        launcherInputFocusNode.requestFocus();
      } else {
        if (!appearAnimController.isAnimating ||
            appearAnimController.status != AnimationStatus.reverse) {
          if (appearAnimController.value > 0.3) {
            appearAnimController.value = 1.0;
          } else if (appearAnimController.value >= 0.2) {
            appearAnimController.value = 0.8;
          }

          appearAnimController.reverse();
          platform.invokeMethod("focusable", {"focusable": false});
        }
      }
      return () {};
    }, [extended.value]);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MouseRegion(
        onHover: (e) async {
          // awakeOpacity();
          extended.value = true;
        },
        onExit: (e) async {
          extended.value = false;
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              WorkspacesLine(
                workspacesCount: 10,
                workspaceIndex: activeWorkspace,
                fill: extended.value,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                height: 230 - 9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 400,
                      child: Column(
                        children: [
                          const Text(
                            "Random Vaxry quote",
                            style: TextStyle(
                              inherit: true,
                              fontSize: 20.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Arial",
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                          Text(
                            "\"${quote.value}\"",
                            style: const TextStyle(
                              inherit: true,
                              fontSize: 20.0,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Arial",
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 600,
                      child: AppSearch(
                        inputController: launcherInputController,
                        inputFocusNode: launcherInputFocusNode,
                        onLaunch: (app) {
                          extended.value = false;
                        },
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: Image.asset("assets/nixos.png"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
