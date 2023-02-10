/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class ResetPasswordRequestDTO {
  final String? password;
  final String? token;

  ResetPasswordRequestDTO(
    this.password,
    this.token,
  );

  dynamic toJson() => {
        "password": password,
        "token": token,
      };
}
