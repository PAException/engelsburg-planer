/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/api_error.dart';
import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart' as requests;
import 'package:engelsburg_planer/src/backend/db/db_service.dart';
import 'package:engelsburg_planer/src/models/api/article.dart';
import 'package:engelsburg_planer/src/services/cache_service.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/services/synchronization_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';

class ArticleService extends DataService {
  final Set<int> _saved = {};

  /// Set up initial saved article data
  @override
  Future<void> setup() async {
    await CacheService.remove("article_saved");

    if (context.loggedIn) return;

    //If user is not logged in get saved articles from cache
    Iterable<int>? cached = CacheService.getNullableJson<List>("article_saved")?.cast<int>();
    if (cached != null) _saved.addAll(cached);
  }

  /// Only synced data gets refreshed
  Future<void> refresh() async {
    if (!context.loggedIn) return;

    //If user is logged in try to get saved articles from api
    var res =
        await requests.getSavedArticles().build().api((json) => json["savedArticles"] as List<int>);
    if (res.dataPresent) _saved.addAll(res.data!);
  }

  /// Get saved articles from db via in memory
  Promise<Article> get promiseSavedArticles => Promise<Article>(
        fetch: () async {
          await refresh();

          if (_saved.isEmpty) {
            return const ApiResponse.error(ApiError(404, "NOT_FOUND", "articles"));
          }

          final articles = await DatabaseService.getBatched<Article>(
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
    if (context.loggedIn) {
      //If user is logged in try to write changes to api
      var res = await requests.saveArticle(article.articleId, saved).build().api((json) => json);

      //Also apply changes on specific errors, it will have no impact on the persistence of
      //the data as the saved ints is a set.
      if (!res.errorPresent || res.error!.isAlreadyExisting || res.error!.isNotFound) {
        _setSaved(article, saved);
      }
    } else {
      //If the user is not logged in update in memory and write in memory to cache
      _setSaved(article, saved);

      List<int> cached =
          CacheService.getNullableJson<List>("article_saved")?.cast<int>().toList() ?? [];
      if (saved && !cached.contains(article.articleId)) {
        cached.add(article.articleId);
      } else if (cached.contains(article.articleId)) {
        cached.remove(article.articleId);
      }

      await CacheService.setJson("article_saved", cached);
    }
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
