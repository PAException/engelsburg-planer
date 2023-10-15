/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/models/api/article.dart';
import 'package:engelsburg_planer/src/services/synchronization_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/article/article_card.dart';
import 'package:engelsburg_planer/src/view/pages/article/article_extended.dart';
import 'package:engelsburg_planer/src/view/pages/home_page.dart';
import 'package:engelsburg_planer/src/view/routing/page.dart';
import 'package:engelsburg_planer/src/view/widgets/special/paged_promised.dart';
import 'package:engelsburg_planer/src/view/widgets/special/updatable.dart';
import 'package:flutter/material.dart';

/// Page to display all articles of the engelsburg
class ArticlePage extends HomeScreenPage {
  const ArticlePage({super.key});

  @override
  State<ArticlePage> createState() => _ArticlePageState();

  @override
  Stream<Map<String, dynamic>> get update => createConnection("/article");
}

class _ArticlePageState extends HomeScreenPageState<ArticlePage> {
  /// Controls the scroll of the list view inside of the paged promise
  final ScrollController scrollController = ScrollController();

  /// Information to build the automated paged promise
  final PagedPromise<Article> promise = SyncService.paged(
    request: (paging) => getArticles(paging: paging).build(),
    parse: (e) => Article.fromArticles(e),
    dbOrderBy: "date DESC",
    pagingSize: 20,
  );

  Article? currentArticle;

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
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final floatingActionButton = FloatingActionButton(
          heroTag: StringUtils.randomAlphaNumeric(10),
          onPressed: () => context.navigate(Pages.savedArticles.path),
          child: const Icon(Icons.bookmark_outlined),
        );

        if (context.isLandscape && constraints.maxWidth > 600) {
          return StatefulBuilder(builder: (context, setState) {
            return Row(
              children: [
                Flexible(
                  flex: 1,
                  child: Scaffold(
                    floatingActionButton: floatingActionButton,
                    body: PagedPromised<Article>(
                      promise: promise,
                      scrollController: scrollController,
                      itemBuilder: (article, context) => ArticleCard(
                        article: article,
                        onTap: () => setState.call(() => currentArticle = article),
                      ),
                      separatorBuilder: (context, index) => const Divider(height: 2, thickness: 1),
                      errorBuilder: (error, context) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(50),
                          child: Text(context.l10n.noArticles),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(),
                Flexible(
                  flex: 2,
                  child: currentArticle == null
                      ? Container()
                      : ExtendedArticle(
                          article: currentArticle,
                          statusBar: false,
                          popCallback: () => setState.call(() => currentArticle = null),
                        ),
                ),
              ],
            );
          });
        }

        return Scaffold(
          floatingActionButton: floatingActionButton,
          body: PagedPromised<Article>(
            promise: promise,
            scrollController: scrollController,
            itemBuilder: (article, context) => ArticleCard(article: article),
            separatorBuilder: (context, index) => const Divider(height: 2, thickness: 1),
            errorBuilder: (error, context) => Center(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Text(context.l10n.noArticles),
              ),
            ),
          ),
        );
      },
    );
  }
}
