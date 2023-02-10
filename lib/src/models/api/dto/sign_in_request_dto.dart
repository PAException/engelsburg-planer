/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class SignInRequestDTO {
  final String? email;
  final String? password;

  SignInRequestDTO({
    this.email,
    this.password,
  });

  dynamic toJson() => {"email": email, "password": password};
}
