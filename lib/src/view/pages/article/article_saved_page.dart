/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/controller/article_controller.dart';
import 'package:engelsburg_planer/src/models/api/article.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/article/article_card.dart';
import 'package:engelsburg_planer/src/view/pages/article/article_extended.dart';
import 'package:engelsburg_planer/src/view/widgets/promised.dart';
import 'package:flutter/material.dart';

/// Page to display all saved articles by the user
class SavedArticlePage extends StatelessWidget {
  const SavedArticlePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (context.isLandscape && constraints.maxWidth > 600) {
          Article? currentArticle;
          var promise = context.data<ArticleService>()!.promiseSavedArticles;

          return StatefulBuilder(builder: (context, setState) {
            return Row(
              children: [
                Flexible(
                  flex: 1,
                  child: Promised<Article>(
                    promise: promise,
                    dataBuilder: (articles, refresh, context) => RefreshIndicator(
                      onRefresh: refresh,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: articles.length,
                        itemBuilder: (context, index) => ArticleCard(
                          article: articles[index],
                          onTap: () => setState.call(() {
                            currentArticle = articles[index];
                          }),
                        ),
                        separatorBuilder: (context, index) => const Divider(height: 0),
                      ),
                    ),
                    errorBuilder: (error, context) => Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Text(
                          context.l10n.noArticlesSaved,
                          textScaleFactor: 1.2,
                          style: TextStyle(
                            color: DefaultTextStyle.of(context).style.color!.withOpacity(3 / 4),
                          ),
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

        return Promised<Article>(
          promise: context.data<ArticleService>()!.promiseSavedArticles,
          dataBuilder: (articles, refresh, context) => RefreshIndicator(
            onRefresh: refresh,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              itemCount: articles.length,
              itemBuilder: (context, index) => ArticleCard(article: articles[index]),
              separatorBuilder: (context, index) => const Divider(height: 0),
            ),
          ),
          errorBuilder: (error, context) => Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Text(
                context.l10n.noArticlesSaved,
                textScaleFactor: 1.2,
                style: TextStyle(
                  color: DefaultTextStyle.of(context).style.color!.withOpacity(3 / 4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
