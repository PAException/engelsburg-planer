/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart' hide NavigatorExt;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:engelsburg_planer/src/backend/api/model/article.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/backend/database/sql/sql_database.dart';
import 'package:engelsburg_planer/src/services/firebase/analytics.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/article/article_card.dart';
import 'package:engelsburg_planer/src/view/widgets/special/network_status.dart';
import 'package:engelsburg_planer/src/view/widgets/util/wrap_if.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:octo_image/octo_image.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:url_launcher/url_launcher_string.dart';

final _dateFormat = DateFormat('dd.MM.yyyy, HH:mm');

class ExtendedArticle extends StatefulWidget {
  final Article? article;
  final String? hero;
  final int? articleId;

  final VoidCallback? popCallback;
  final bool statusBar;

  const ExtendedArticle({
    this.article,
    this.hero,
    this.articleId,
    this.popCallback,
    this.statusBar = true,
    super.key,
  }) : assert(articleId != null || article != null);

  @override
  ExtendedArticleState createState() => ExtendedArticleState();
}

class ExtendedArticleState extends State<ExtendedArticle> {
  late Future<Article?> fetchArticle;

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      fetchArticle = Future.value(widget.article!);
    } else {
      fetchArticle = Future(() async {
        var article = await SqlDatabase.get<Article>(
          where: "articleId=?",
          whereArgs: [widget.articleId!],
        );
        article ??=
            (await getArticle(widget.articleId!).build().api(Article.fromJson))
                .data;

        return article;
      });
    }
  }

  @override
  void didUpdateWidget(ExtendedArticle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article != widget.article && widget.article != null) {
      fetchArticle = Future.value(widget.article!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Article?>(
      future: fetchArticle,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator().toCenter();
        }
        if (snapshot.data == null) {
          return Text(context.l10n.articlesNotFoundError).toCenter();
        }
        var article = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_outlined),
              onPressed: () => widget.popCallback != null
                  ? widget.popCallback!.call()
                  : context.navigate("/article"),
            ),
            actions: [
              ArticleSaveIconButton(article),
              OpenInBrowserIconButton(article.link),
              ShareIconButton(
                article.link,
                onShare: () => Analytics.interaction.article
                    .share(article, "article_extended"),
              ),
            ],
          ),
          body: WrapIf(
            condition: widget.statusBar,
            wrap: (child, context) => NetworkStatusBar(child: child),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ArticleTitle.extended(
                        article: article, heroTag: widget.hero ?? ""),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                      child: Text(
                        _dateFormat.format(
                            DateTime.fromMillisecondsSinceEpoch(article.date)),
                      ),
                    ),
                    const Divider(height: 32.0),
                    HtmlWidget(
                      article.content.toString(),
                      textStyle: const TextStyle(height: 1.5, fontSize: 18.0),
                      onTapUrl: (url) => url_launcher.launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                      onTapImage: (meta) => showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: double.infinity,
                                height: 500,
                                child: OctoImage(
                                  image: CachedNetworkImageProvider(
                                      meta.sources.first.url),
                                  fit: BoxFit.contain,
                                  placeholderBuilder: (_) => SpinKitCircle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
