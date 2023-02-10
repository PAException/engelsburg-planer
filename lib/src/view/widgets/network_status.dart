/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/network_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget to show the current network status above a given child. Usually used on between the body
/// property of the scaffold and the following tree.
///
/// Example:
///
/// ```dart
/// @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: NetworkStatusBar(
///         child: ...,
///       ),
///     );
///   }
/// ```
///
/// The current status is maintained by the [NetworkState] provider.
class NetworkStatusBar extends StatefulWidget {
  final Widget child;

  const NetworkStatusBar({Key? key, required this.child}) : super(key: key);

  @override
  State<NetworkStatusBar> createState() => _NetworkStatusBarState();
}

class _NetworkStatusBarState extends State<NetworkStatusBar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<NetworkState>(
          builder: (context, state, child) {
            var networkStateWidget = NetworkStatusWidget.from(state.status);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: networkStateWidget.preferredSize.height,
              child: networkStateWidget,
            );
          },
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Abstract class to reduce boilerplate code for the network status widgets
abstract class NetworkStatusWidget extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const NetworkStatusWidget({Key? key, required this.height}) : super(key: key);

  @override
  @nonVirtual
  Size get preferredSize => Size.fromHeight(height);

  /// Get network state widget by specific network state
  factory NetworkStatusWidget.from(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.online:
        return const OnlineWidget();
      case NetworkStatus.loading:
        return const LoadingWidget();
      case NetworkStatus.offline:
        return const OfflineWidget();
    }
  }
}

/// Standby widget = nothing
class OnlineWidget extends NetworkStatusWidget {
  const OnlineWidget({Key? key}) : super(key: key, height: 0);

  @override
  Widget build(BuildContext context) => Container();
}

/// Dynamic blue thin LinearProgressIndicator
class LoadingWidget extends NetworkStatusWidget {
  const LoadingWidget({Key? key}) : super(key: key, height: 4);

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
        minHeight: height,
        backgroundColor: Colors.blue,
        color: Colors.lightBlue,
      );
}

/// Small rectangular widget labeled with OFFLINE
class OfflineWidget extends NetworkStatusWidget {
  const OfflineWidget({Key? key}) : super(key: key, height: 20);

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        color: Theme.of(context).colorScheme.secondary,
        child: const Center(
          child: Text("OFFLINE"),
        ),
      );
}
