import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SearchResult extends HookConsumerWidget {
  const SearchResult({
    super.key,
  });

  @override
  Widget build(context, ref) {
    return AspectRatio(
      aspectRatio: 1,
      child: ElevatedButton(
        onPressed: () {},
        child: const Center(
          child: Text("Search result"),
        ),
      ),
    );
  }
}
