/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/controller/article_controller.dart';
import 'package:engelsburg_planer/src/models/api/article.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/view/widgets/article_card.dart';
import 'package:engelsburg_planer/src/view/widgets/promised.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Page to display all saved articles by the user
class SavedArticlesPage extends StatelessWidget {
  const SavedArticlesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            AppLocalizations.of(context)!.noArticlesSaved,
            textScaleFactor: 1.2,
            style: TextStyle(
              color: DefaultTextStyle.of(context).style.color!.withOpacity(3 / 4),
            ),
          ),
        ),
      ),
    );
  }
}
