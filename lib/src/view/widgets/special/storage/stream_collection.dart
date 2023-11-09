/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/collection.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:flutter/material.dart';

class StreamCollection<T> extends StatelessWidget {
  const StreamCollection({
    super.key,
    required this.collection,
    required this.itemBuilder,
    this.errorBuilder,
  });

  final Collection<T> collection;
  final Widget Function(BuildContext context, Collection<T> collection, List<Document<T>> t) itemBuilder;
  final Widget? Function(BuildContext context, Collection<T> collection, Object? error)?
  errorBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Document<T>>>(
      stream: collection.stream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return itemBuilder.call(context, collection, snapshot.data!);
        }

        return errorBuilder?.call(context, collection, snapshot.error) ?? Container();
      },
    );
  }
}
