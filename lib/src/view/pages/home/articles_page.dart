/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/models/api/article.dart';
import 'package:engelsburg_planer/src/services/synchronization_service.dart';
import 'package:engelsburg_planer/src/view/pages/home/home_page.dart';
import 'package:engelsburg_planer/src/view/pages/page.dart';
import 'package:engelsburg_planer/src/view/widgets/article_card.dart';
import 'package:engelsburg_planer/src/view/widgets/paged_promised.dart';
import 'package:engelsburg_planer/src/view/widgets/util/updatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Page to display all articles of the engelsburg
class ArticlesPage extends HomeScreenPage {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();

  @override
  Stream<Map<String, dynamic>> get update => createConnection("/article");
}

class _ArticlesPageState extends HomeScreenPageState<ArticlesPage> {
  /// Controls the scroll of the list view inside of the paged promise
  final ScrollController scrollController = ScrollController();

  /// Information to build the automated paged promise
  final PagedPromise<Article> promise = SyncService.paged(
    request: (paging) => getArticles(paging: paging).build(),
    parse: (e) => Article.fromArticles(e),
    dbOrderBy: "date DESC",
    pagingSize: 20,
  );

  @override
  void onUpdate(Map<String, dynamic> update) {
    //Resets the offset of the scroll if the bottomNavigationBar item is pressed while on the page
    if (update["resetView"] ?? false) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: PagedPromised<Article>(
        promise: promise,
        scrollController: scrollController,
        itemBuilder: (article, context) => ArticleCard(article: article),
        separatorBuilder: (context, index) => const Divider(height: 0),
        errorBuilder: (error, context) => Center(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Text(AppLocalizations.of(context)!.noArticles),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(Pages.savedArticles.path),
        child: const Icon(Icons.bookmark_outlined),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }
}
