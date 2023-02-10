/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

/// Value [T] that can be enabled/disabled. Useful to enable or disable data and save it
/// without the information getting lost.
class Switch<T> {
  bool enabled;
  T data;

  Switch(this.data, [this.enabled = false]);

  static Switch<T> fromJson<T>(dynamic json) => Switch(json["data"], json["enabled"]);

  dynamic toJson() => {"enabled": enabled, "data": data};
}

class ListSwitch<T> extends Switch<List<T>> {
  ListSwitch([bool enabled = false]) : super(const [], enabled);
}
