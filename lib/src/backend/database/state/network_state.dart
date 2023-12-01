/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/logger.dart';
import 'package:engelsburg_planer/src/view/widgets/special/network_status.dart';
import 'package:flutter/material.dart';

enum NetworkStatus { online, loading, offline }

/// Provided state to keep track of the current network status. See [NetworkStatusBar]
class NetworkState extends ChangeNotifier with Logs<NetworkState> {
  NetworkStatus _current = NetworkStatus.online;

  /// Get the current network status
  NetworkStatus get status => _current;

  /// Update the current network status and notify all listeners
  void update(NetworkStatus status) {
    //Don't set status to loading just while retrying timed out requests
    if (status == NetworkStatus.loading && _current == NetworkStatus.offline) return;

    logger.info("Status of network changed to ${_current.name}");

    //Set current status and notify listeners
    _current = status;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }
}
