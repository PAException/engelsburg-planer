/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class SignUpRequestDTO {
  final String? email;
  final String? password;

  SignUpRequestDTO({
    this.email,
    this.password,
  });

  dynamic toJson() => {"email": email, "password": password};
}
