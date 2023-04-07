/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/models/state/network_state.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide ErrorBuilder;

const Widget kLoadingWidget = Center(child: CircularProgressIndicator());

/// Widget to build efficiently from an api request.
/// On Build the given request is taken, executed and parsed to <T>.
/// While the request performs loading builder is called and its widget is returned.
/// If the requests completes the returning widget is dependent on the result of the request.
/// If the request returns data the data builder will be called, on an error the error
/// builder will be called. If no data and no error are returned the widget will constantly display
/// the loading widget.
class ApiFutureBuilder<T> extends StatefulWidget {
  final Request request;
  final Parser<T> parser;
  final DataBuilder<T> dataBuilder;
  final ErrorBuilder errorBuilder;
  final LoadingBuilder? loadingBuilder;

  const ApiFutureBuilder({
    Key? key,
    required this.request,
    required this.parser,
    required this.dataBuilder,
    required this.errorBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<ApiFutureBuilder<T>> createState() => _ApiFutureBuilderState<T>();
}

class _ApiFutureBuilderState<T> extends State<ApiFutureBuilder<T>> {
  @override
  Widget build(BuildContext context) {
    var future = widget.request.api(widget.parser);

    return FutureBuilder<ApiResponse<T>>(
      future: future,
      builder: (context, snapshot) {
        //Request was performed, response is available
        if (snapshot.connectionState == ConnectionState.done) {
          //Should never happen
          if (snapshot.hasError) {
            if (kDebugMode) print(snapshot.error!);
            if (kDebugMode) print(snapshot.stackTrace!);
          }

          //Snapshot has data
          if (snapshot.hasData) {
            var apiResponse = snapshot.data!;
            if (apiResponse.errorPresent) {
              //If error is timed out dispatch offline notification
              if (apiResponse.error!.isTimedOut)
                context.read<NetworkState>().update(NetworkStatus.offline);

              return widget.errorBuilder.call(apiResponse.error!, context);
            }
            if (apiResponse.dataPresent) {
              return widget.dataBuilder.call(
                apiResponse.data as T,
                () async => setState(() {}),
                context,
              );
            }
          }
        }

        //Future is awaited and request is performing
        return widget.loadingBuilder?.call(context) ?? kLoadingWidget;
      },
    );
  }
}
