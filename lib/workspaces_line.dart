import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WorkspacesLine extends HookConsumerWidget {
  const WorkspacesLine({
    super.key,
    required this.workspacesCount,
    required this.workspaceIndex,
    required this.fill,
  });

  final int workspacesCount;
  final int workspaceIndex;
  final bool fill;

  @override
  Widget build(context, ref) {
    final gradientColors = useState([
      Colors.blue,
      Colors.white,
      Colors.cyan,
    ]);

    void cycleColors() {
      gradientColors.value = [
        gradientColors.value[1],
        gradientColors.value[2],
        gradientColors.value[0],
      ];
    }

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 10), cycleColors);
      return () {};
    }, []);

    return SizedBox(
      height: 9,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: LayoutBuilder(
          builder: (context, constrains) {
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: fill
                      ? 0
                      : constrains.maxWidth *
                          (workspaceIndex / workspacesCount),
                  bottom: 0,
                  width: fill
                      ? constrains.maxWidth
                      : constrains.maxWidth / workspacesCount,
                  top: 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: 9,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1500),
                        onEnd: () {
                          cycleColors();
                        },
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors.value,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(5),
                            topRight: const Radius.circular(5),
                            bottomLeft: Radius.circular(fill ? 5 : 0),
                            bottomRight: Radius.circular(fill ? 5 : 0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
