/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

class UpdateNotificationSettingsDTO {
  final String token;
  final Iterable<String> priorityTopics;

  UpdateNotificationSettingsDTO({
    required this.token,
    required this.priorityTopics,
  });

  Map<String, dynamic> toJson() => {
        "token": token,
        "priorityTopics": priorityTopics.toList(),
      };
}
