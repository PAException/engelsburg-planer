/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/collection.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:flutter/material.dart';

class CollectionStreamBuilder<T> extends StatelessWidget {
  const CollectionStreamBuilder({
    super.key,
    required this.collection,
    required this.itemBuilder,
    this.separatorBuilder,
    this.loading,
    this.empty,
    this.sort,
    this.filter,
  });

  final Collection<T> collection;
  final Widget Function(BuildContext context, Document<T> doc) itemBuilder;
  final Widget Function(BuildContext context, Document<T> doc)?
  separatorBuilder;
  final int Function(Document<T> a, Document<T> b)? sort;
  final bool Function(Document<T> doc)? filter;
  final Widget? loading;
  final Widget? empty;

  final Widget kLoading = const Center(child: CircularProgressIndicator());
  final Widget kEmpty = const Center(child: Text("Not Found"));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Document<T>>>(
      stream: collection.stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading ?? kLoading;
        }

        var data = snapshot.data ?? [];
        if (filter != null) data.removeWhere((doc) => !filter!.call(doc));
        if (sort != null) data.sort(sort!);

        if (data.isEmpty) {
          return empty ?? loading ?? kLoading;
        }

        return ListView.separated(
          itemBuilder: (context, index) =>
              itemBuilder.call(context, data[index]),
          separatorBuilder: (context, index) =>
          separatorBuilder?.call(context, data[index]) ?? Container(),
          itemCount: data.length,
        );
      },
    );
  }
}
