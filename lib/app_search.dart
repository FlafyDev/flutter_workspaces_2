import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_workspaces_2/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:xdg_icons/xdg_icons.dart';
import 'package:collection/collection.dart';

class App {
  App({
    required this.name,
    required this.icon,
    required this.exec,
  });

  final String name;
  final String icon;
  final String exec;

  Future<void> run() {
    return Process.run(
      exec.split(" ").first,
      exec.split(" ").skip(1).where((arg) => !arg.startsWith("%")).toList(),
    );
  }
}

final appsProvider = FutureProvider((ref) async {
  final xdgDataDirs = Platform.environment["XDG_DATA_DIRS"]?.split(":");
  final apps = <App>[];

  for (final dir in xdgDataDirs ?? []) {
    final appsDir = Directory("$dir/applications");

    if (await appsDir.exists()) {
      final entities = await appsDir.list().toList();
      for (final file in entities.whereType<File>()) {
        final lines = await file.readAsLines();
        final name = lines.firstWhere((line) => line.startsWith("Name="),
            orElse: () => "");
        final icon = lines.firstWhere((line) => line.startsWith("Icon="),
            orElse: () => "");
        final exec = lines.firstWhere((line) => line.startsWith("Exec="),
            orElse: () => "");
        apps.add(App(
          name: name.split("=").last,
          icon: icon.split("=").last,
          exec: exec.split("=").last,
        ));
      }
    }
  }

  return apps;
});

class AppSearch extends HookConsumerWidget {
  const AppSearch({
    super.key,
    this.inputController,
    this.inputFocusNode,
    this.onLaunch,
  });

  final TextEditingController? inputController;
  final FocusNode? inputFocusNode;
  final void Function(App app)? onLaunch;

  @override
  Widget build(context, ref) {
    final apps = (ref.watch(appsProvider).valueOrNull ?? <App>[])
        .unique((app) => app.name);
    final queriedApps = useState<List<App>>([]);

    useEffect(() {
      queriedApps.value = apps.take(5).toList();
      return () {};
    }, [apps]);

    useEffect(() {
      void onQuery() {
        final query = inputController!.text.toLowerCase();
        if (query.isEmpty) {
          queriedApps.value = apps.take(5).toList();
        } else {
          queriedApps.value = apps
              .where((app) => app.name.toLowerCase().contains(query))
              .take(5)
              .toList();
        }
      }

      inputController?.addListener(onQuery);
      return () {
        inputController?.removeListener(onQuery);
      };
    }, [inputController, apps]);

    return Column(
      children: [
        Flexible(
          child: FractionallySizedBox(
            heightFactor: 0.3,
            child: TextField(
              controller: inputController,
              focusNode: inputFocusNode,
              onChanged: (value) {},
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
              ),
              onSubmitted: (value) async {
                final app = queriedApps.value.firstOrNull;
                if (app != null) {
                  onLaunch?.call(app);
                  await app.run();
                }
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(8),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.6),
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(15),
                  ),
                ),
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        Flexible(
          child: FractionallySizedBox(
            heightFactor: 0.7,
            child: Center(
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: queriedApps.value.map((app) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AppResult(
                      app: app,
                      onPressed: () async {
                        onLaunch?.call(app);
                        await app.run();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppResult extends HookConsumerWidget {
  const AppResult({
    super.key,
    required this.app,
    required this.onPressed,
  });

  final App app;
  final void Function() onPressed;

  @override
  Widget build(context, ref) {
    return Tooltip(
      message: app.name,
      child: AspectRatio(
        aspectRatio: 1,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(0),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: app.icon.isNotEmpty
              ? XdgIcon(
                  name: app.icon,
                  size: 48,
                )
              : Text(
                  app.name,
                  style: const TextStyle(fontSize: 12),
                ),
        ),
      ),
    );
  }
}
