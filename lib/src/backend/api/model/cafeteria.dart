/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

class Cafeteria {
  final String? content;
  final String? link;
  final String? mediaUrl;
  final String? blurHash;

  Cafeteria({
    this.content,
    this.link,
    this.mediaUrl,
    this.blurHash,
  });

  factory Cafeteria.fromJson(dynamic json) => Cafeteria(
        content: json["content"],
        link: json["link"],
        mediaUrl: json["mediaURL"],
        blurHash: json["blurHash"],
      );

  dynamic toJson() => {
        "content": content,
        "link": link,
        "mediaURL": mediaUrl,
        "blurHash": blurHash,
      };
}
