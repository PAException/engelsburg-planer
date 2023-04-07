/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

class UpdateNotificationSettingsDTO {
  final String token;
  final List<String> priorityTopics;

  UpdateNotificationSettingsDTO({
    required this.token,
    required this.priorityTopics,
  });

  Map<String, dynamic> toJson() => {
        "token": token,
        "priorityTopics": priorityTopics,
      };

  factory UpdateNotificationSettingsDTO.fromJson(Map<String, dynamic> json) =>
      UpdateNotificationSettingsDTO(
        token: json["token"],
        priorityTopics: json["priorityTopics"].cast<String>(),
      );
//
}
