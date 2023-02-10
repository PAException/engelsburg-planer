/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/controller/article_controller.dart';
import 'package:engelsburg_planer/src/models/api/article.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/pages/home/articles_page.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:octo_image/octo_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tap_debouncer/tap_debouncer.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Stateful widget to show an article in a card format on the [ArticlesPage]
class ArticleCard extends StatefulWidget {
  final Article article;

  const ArticleCard({Key? key, required this.article}) : super(key: key);

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  final String hero = StringUtils.randomAlphaNumeric(16);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 500,
        child: InkWell(
          onTap: () =>
              context.go("/article/${widget.article.articleId}?hero=$hero", extra: widget.article),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ArticleImage(article: widget.article, heroTag: hero),
                ArticleTitle.card(article: widget.article, heroTag: hero),
                ArticleCardActions(article: widget.article),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Image section of [ArticleCard]
class ArticleImage extends StatelessWidget {
  final Article article;
  final String heroTag;

  const ArticleImage({Key? key, required this.article, required this.heroTag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Show no image if no url is available
    if (article.mediaUrl == null) return Container();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: OctoImage(
            image: NetworkImageWithRetry(
              article.mediaUrl!,
              fetchStrategy: (uri, failure) async => FetchInstructions.attempt(
                uri: uri,
                timeout: const Duration(seconds: 4),
              ),
            ),
            placeholderBuilder: article.blurHash != null
                ? OctoPlaceholder.blurHash(article.blurHash!)
                : (_) => SpinKitCircle(
                      color: Theme.of(context).backgroundColor,
                    ),
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// Title section of [ArticleCard]
class ArticleTitle extends StatelessWidget {
  final Article article;
  final String heroTag;
  final TextStyle textStyle;

  const ArticleTitle({
    Key? key,
    required this.article,
    required this.heroTag,
    required this.textStyle,
  }) : super(key: key);

  const ArticleTitle.card({
    Key? key,
    required this.article,
    required this.heroTag,
  })  : textStyle = const TextStyle(fontSize: 20.0),
        super(key: key);

  const ArticleTitle.extended({
    Key? key,
    required this.article,
    required this.heroTag,
  })  : textStyle = const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        super(key: key);

  @override
  Widget build(BuildContext context) => Text(
        HtmlUtils.unescape(article.title.toString()),
        style: textStyle,
      ).wrapIf(
        //Wrap in hero text if media url == null, otherwise hero is already the image
        value: article.mediaUrl == null,
        wrap: (child) => HeroText(tag: heroTag, child: child),
      );
}

/// Action section of [ArticleCard]
class ArticleCardActions extends StatelessWidget {
  final Article article;

  const ArticleCardActions({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateTime.fromMillisecondsSinceEpoch(article.date).elapsed(context),
            style: TextStyle(color: Theme.of(context).textTheme.caption!.color),
          ),
          Expanded(child: Container()),
          ArticleSaveIconButton(article),
          ShareIconButton(article.link),
        ],
      ),
    );
  }
}

/// Stateful IconButton to view and change the current saved status of an article
class ArticleSaveIconButton extends StatefulWidget {
  final Article article;

  const ArticleSaveIconButton(this.article, {Key? key}) : super(key: key);

  @override
  State<ArticleSaveIconButton> createState() => _ArticleSaveIconButtonState();
}

class _ArticleSaveIconButtonState extends State<ArticleSaveIconButton> {
  @override
  Widget build(BuildContext context) {
    var saved = context.data<ArticleService>()!.isSaved(widget.article);

    return TapDebouncer(
      onTap: () async {
        await context.data<ArticleService>()!.setArticleSave(widget.article, !saved);
        setState(() {});
      },
      builder: (context, onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(saved ? Icons.bookmark_outlined : Icons.bookmark_border_outlined),
      ),
    );
  }
}

/// Simple IconButton with const icon to open an url in a browser
class OpenInBrowserIconButton extends StatelessWidget {
  final String? url;

  const OpenInBrowserIconButton(this.url, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (url == null) return Container();

    return TapDebouncer(
      onTap: () => url_launcher.launchUrl(Uri.parse(url!)),
      builder: (context, onTap) => IconButton(
        onPressed: onTap,
        tooltip: AppLocalizations.of(context)!.openInBrowser,
        icon: const Icon(Icons.open_in_new),
      ),
    );
  }
}

/// Simple IconButton with const icon to share an url
class ShareIconButton extends StatelessWidget {
  final String? url;

  const ShareIconButton(this.url, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (url == null) return Container();

    return TapDebouncer(
      onTap: () => Share.share(url!),
      builder: (context, onTap) => IconButton(
        onPressed: onTap,
        tooltip: AppLocalizations.of(context)!.share,
        icon: const Icon(Icons.share),
      ),
    );
  }
}
