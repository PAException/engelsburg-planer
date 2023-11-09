/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:flutter/material.dart';

class StreamSelector<T, V> extends StatelessWidget {
  const StreamSelector({
    super.key,
    required this.doc,
    required this.selector,
    required this.builder,
    this.errorBuilder,
  });

  final Document<T> doc;
  final Widget Function(BuildContext context, Document doc, T t, V v) builder;
  final V Function(T t) selector;
  final Widget? Function(BuildContext context, Document doc, Object? error)?
  errorBuilder;

  @override
  Widget build(BuildContext context) {
    doc.load();
    V? v;
    late Widget currentBuild;

    return StreamConsumer<T>(
      doc: doc,
      errorBuilder: errorBuilder,
      itemBuilder: (context, doc, t) {
        if (v == null) {
          v = selector.call(t);
        } else {
          V newV = selector.call(t);
          if (v == newV) return currentBuild;

          v = newV;
        }

        currentBuild = builder.call(context, doc, t, v as V);
        return currentBuild;
      },
    );
  }
}
