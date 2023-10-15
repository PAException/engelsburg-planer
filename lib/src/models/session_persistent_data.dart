/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

class SessionPersistentData {
  static final Map<Type, dynamic> _data = {};
  
  static void set(dynamic data) => _data[data.runtimeType] = data;
  
  static T? get<T>() => _data[T] as T?;
}
