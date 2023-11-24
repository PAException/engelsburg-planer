/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:flutter/material.dart';

class StreamConsumer<T> extends StatelessWidget {
  const StreamConsumer({
    super.key,
    required this.doc,
    required this.itemBuilder,
    this.errorBuilder,
  });

  final Document<T> doc;
  final Widget Function(BuildContext context, Document<T> doc, T t) itemBuilder;
  final Widget? Function(BuildContext context, Document<T> doc, Object? error)?
  errorBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T?>(
      stream: doc.stream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return itemBuilder.call(context, doc, snapshot.data as T);
        }

        return errorBuilder?.call(context, doc, snapshot.error) ?? Container();
      },
    );
  }
}

class NullableStreamConsumer<T> extends StatelessWidget {
  const NullableStreamConsumer({
    super.key,
    required this.doc,
    required this.itemBuilder,
    this.errorBuilder,
  });

  final Document<T>? doc;
  final Widget Function(BuildContext context, Document<T>? doc, T? t)
  itemBuilder;
  final Widget? Function(BuildContext context, Document<T>? doc, Object? error)?
  errorBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T?>(
      stream: doc?.stream(),
      builder: (context, snapshot) {
        var data = doc == null ? null : snapshot.data;

        if (!snapshot.hasError) {
          return itemBuilder.call(context, doc, data);
        }

        return errorBuilder?.call(context, doc, data) ?? Container();
      },
    );
  }
}
