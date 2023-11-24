/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';
import 'dart:isolate';

/// Worker class to run synchronous or asynchronous operations in a separate isolate (thread)
class IsolatedWorker {
  static late SendPort _sendIn;

  /// Function where operations get executed, used in Isolate.spawn
  static void _isolateWorker(SendPort sendOut) {
    //Set up communication ports inside isolate
    ReceivePort receiveIn = ReceivePort();
    SendPort sendIn = receiveIn.sendPort;

    //Tell out port to send to
    sendOut.send(sendIn);

    //Listen for messages
    receiveIn.listen((message) {
      if (message != null && message is IsolateTask) {
        //After completion of future send result
        var possibleFuture = message.task.call();
        Future.value(possibleFuture).then((result) => message.sendOut.send(result));
      }
    });
  }

  /// Called on app init, sets isolate (Isolate.spawn) and communication up
  static Future<void> initialize() async {
    //Init ports for temporary port exchange
    final ReceivePort receiveOut = ReceivePort();
    SendPort sendOut = receiveOut.sendPort;

    //Create isolate
    Isolate.spawn<SendPort>(_isolateWorker, sendOut);

    //Get send-to-isolate-port from isolate
    _sendIn = await receiveOut.first;
  }

  /// Call to compute an sync or async task in another isolate (thread).
  /// Function establishes a connection to the isolate and writes the task.
  /// After that the result will be received and returned.
  static Future<T> compute<T>(FutureOr<T> Function() future) async {
    //Init ports outside
    ReceivePort tempReceiveOut = ReceivePort();
    SendPort tempSendOut = tempReceiveOut.sendPort;

    //Send isolate task
    _sendIn.send(IsolateTask<T>(tempSendOut, future));

    //Get first message and return
    return await tempReceiveOut.first as T;
  }
}

/// Util class to write typed task to the isolate
class IsolateTask<T> {
  final SendPort sendOut;
  final FutureOr<T> Function() task;

  IsolateTask(this.sendOut, this.task);
}
