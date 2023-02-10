/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class Article {
  final int articleId;
  int date;
  String? link;
  String? title;
  String? content;
  String? contentHash;
  String? mediaUrl;
  String? blurHash;

  Article({
    required this.articleId,
    required this.date,
    this.link,
    this.title,
    this.content,
    this.contentHash,
    this.mediaUrl,
    this.blurHash,
  });

  static List<Article> fromArticles(dynamic json) {
    if (json is Map) json = json["articles"];

    return json.map<Article>((e) => Article.fromJson(e)).toList();
  }

  factory Article.fromJson(dynamic json) => Article(
        articleId: json["articleId"],
        date: json["date"],
        link: json["link"],
        title: json["title"],
        content: json["content"],
        contentHash: json["contentHash"],
        mediaUrl: json["mediaUrl"],
        blurHash: json['blurHash'],
      );

  dynamic toJson() => {
        "articleId": articleId,
        "date": date,
        "link": link,
        "title": title,
        "content": content,
        "contentHash": contentHash,
        "mediaUrl": mediaUrl,
        "blurHash": blurHash,
      };

  @override
  String toString() {
    return 'Article{articleId: $articleId, date: $date, link: $link, title: $title, content: $content, contentHash: $contentHash, mediaUrl: $mediaUrl, blurHash: $blurHash}';
  }
}
