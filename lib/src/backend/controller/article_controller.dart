/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/api_error.dart';
import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/model/article.dart';
import 'package:engelsburg_planer/src/backend/database/cache/app_persistent_data.dart';
import 'package:engelsburg_planer/src/backend/database/sql/sql_database.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/services/promise.dart';

class ArticleService extends DataService {
  final Set<int> _saved = {};

  /// Set up initial saved article data
  @override
  Future<void> setup() async {
    //If user is not logged in get saved articles from cache
    var cached = AppPersistentData.get<List<int>>("article_saved");
    if (cached != null) _saved.addAll(cached);
  }

  /// Get saved articles from db via in memory
  Promise<Article> get promiseSavedArticles => Promise<Article>(
        fetch: () async {
          if (_saved.isEmpty) {
            return const ApiResponse.error(ApiError(404, "NOT_FOUND", "articles"));
          }

          final articles = await SqlDatabase.getBatched<Article>(
            orderBy: "date DESC",
            where: "articleId=?",
            whereArgs: _saved.toList().map((e) => [e]).toList(),
          );

          if (articles.isEmpty) {
            return const ApiResponse.error(ApiError(404, "NOT_FOUND", "articles"));
          }

          return ApiResponse(null, null, articles);
        },
      );

  /// Saves or un-saves an article
  Future<void> setArticleSave(Article article, bool saved) async {
    //If the user is not logged in update in memory and write in memory to cache
    _setSaved(article, saved);

    List<int> cached = AppPersistentData.get<List<int>>("article_saved") ?? [];
    if (saved && !cached.contains(article.articleId)) {
      cached.add(article.articleId);
    } else if (cached.contains(article.articleId)) {
      cached.remove(article.articleId);
    }

    AppPersistentData.set("article_saved", cached);
  }

  /// Add or remove to/from saved articles
  void _setSaved(Article article, bool saved) {
    if (saved) {
      _saved.add(article.articleId);
    } else {
      _saved.remove(article.articleId);
    }
  }

  /// Returns whether an article is saved or not
  bool isSaved(Article article) => _saved.contains(article.articleId);
}
