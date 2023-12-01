/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/model/article.dart';
import 'package:engelsburg_planer/src/backend/controller/article_controller.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/services/firebase/analytics.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/pages/article/article_page.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:engelsburg_planer/src/view/widgets/util/wrap_if.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:octo_image/octo_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tap_debouncer/tap_debouncer.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Stateful widget to show an article in a card format on the [ArticlePage]
class ArticleCard extends StatefulWidget {
  final Article article;
  final VoidCallback? onTap;

  const ArticleCard({super.key, required this.article, this.onTap});

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
          onTap: () {
            Analytics.interaction.article.select(widget.article);

            if (widget.onTap != null) return widget.onTap!.call();

            context.navigate(
              "/article/${widget.article.articleId}?hero=$hero",
              extra: widget.article,
            );
          },
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

  const ArticleImage({super.key, required this.article, required this.heroTag});

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
            height: 200,
            fit: BoxFit.cover,
            image: NetworkImageWithRetry(
              article.mediaUrl!,
              fetchStrategy: (uri, failure) async => FetchInstructions.attempt(
                uri: uri,
                timeout: const Duration(seconds: 4),
              ),
            ),
            placeholderBuilder: (_) => SpinKitCircle(
              color: Theme.of(context).colorScheme.primary,
            ),
            /* //TODO
            placeholderBuilder: article.blurHash != null && article.blurHash!.length >= 6
                ? OctoPlaceholder.blurHash(article.blurHash!)
                : (_) => SpinKitCircle(
                      color: Theme.of(context).colorScheme.primary,
                    ),*/
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
    super.key,
    required this.article,
    required this.heroTag,
    required this.textStyle,
  });

  const ArticleTitle.card({
    super.key,
    required this.article,
    required this.heroTag,
  })  : textStyle = const TextStyle(fontSize: 20.0);

  const ArticleTitle.extended({
    super.key,
    required this.article,
    required this.heroTag,
  })  : textStyle = const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    return WrapIf(
      condition: article.mediaUrl == null,
      wrap: (child, context) => HeroText(tag: heroTag, child: child),
      child: Text(
        unescapeHtml(article.title.toString()),
        style: textStyle,
      ),
    );
  }
}

/// Action section of [ArticleCard]
class ArticleCardActions extends StatelessWidget {
  final Article article;

  const ArticleCardActions({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateTime.fromMillisecondsSinceEpoch(article.date).elapsed(context),
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color),
          ),
          Expanded(child: Container()),
          ArticleSaveIconButton(article),
          ShareIconButton(
            article.link,
            onShare: () => Analytics.interaction.article.share(article, "article_page"),
          ),
        ],
      ),
    );
  }
}

/// Stateful IconButton to view and change the current saved status of an article
class ArticleSaveIconButton extends StatefulWidget {
  final Article article;

  const ArticleSaveIconButton(this.article, {super.key});

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

        if (saved) {
          DelayedExecution.exec(
            "save_article_${widget.article.articleId}",
                () => Analytics.interaction.article.save(widget.article),
          );
        }
        setState(() {});
      },
      builder: (context, onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(saved ? Icons.bookmark_added_outlined : Icons.bookmark_add_outlined),
      ),
    );
  }
}

/// Simple IconButton with const icon to open an url in a browser
class OpenInBrowserIconButton extends StatelessWidget {
  final String? url;

  const OpenInBrowserIconButton(this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    if (url == null) return Container();

    return TapDebouncer(
      onTap: () => url_launcher.launchUrl(Uri.parse(url!)),
      builder: (context, onTap) => IconButton(
        onPressed: onTap,
        tooltip: context.l10n.openInBrowser,
        icon: const Icon(Icons.open_in_new),
      ),
    );
  }
}

/// Simple IconButton with const icon to share an url
class ShareIconButton extends StatelessWidget {
  final String? url;
  final VoidCallback? onShare;

  const ShareIconButton(this.url, {super.key, this.onShare});

  @override
  Widget build(BuildContext context) {
    if (url == null) return Container();

    return TapDebouncer(
      onTap: () async {
        final box = context.findRenderObject() as RenderBox?;

        var result = await Share.shareWithResult(
          url!,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
        if (result.status == ShareResultStatus.success) onShare?.call();
      },
      builder: (context, onTap) => IconButton(
        onPressed: onTap,
        tooltip: context.l10n.share,
        icon: const Icon(Icons.share),
      ),
    );
  }
}
