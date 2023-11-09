/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

class SessionPersistentData {
  static final Map<String, dynamic> keyed = {};
  static final Map<Type, dynamic> _typedData = {};

  static bool isSet<T>() => _typedData.containsKey(T);
  
  static void set(dynamic data) => _typedData[data.runtimeType] = data;
  
  static T? get<T>() => _typedData[T] as T?;
}
