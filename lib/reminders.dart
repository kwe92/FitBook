import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:fit_book/database/database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

Timer? timer;

void setupReminders() {
  if (Platform.isAndroid || Platform.isIOS) {
    Workmanager().initialize(
      doMobileReminders,
      isInDebugMode: kDebugMode,
    );
    Workmanager().registerPeriodicTask(
      "reminders",
      "reminders",
      frequency: const Duration(minutes: 15),
    );
  } else {
    timer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => doDesktopReminders(),
    );
  }
}

doDesktopReminders() async {
  const linuxSettings =
      LinuxInitializationSettings(defaultActionName: 'Open notification');
  const darwinSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    linux: linuxSettings,
    macOS: darwinSettings,
  );
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(initSettings);

  final db = AppDatabase();

  final entries = await (db.entries.select()
        ..where(
          (u) => const CustomExpression(
            "created >= strftime('%s', 'now', 'localtime', '-24 hours')",
          ),
        ))
      .get();
  final now = DateTime.now();
  final hour = now.hour;

  if (hour >= 6 && hour < 12) {
    final entered = entries
        .where((entry) => entry.created.hour >= 6 && entry.created.hour < 12);
    if (entered.isEmpty)
      await plugin.show(
        1,
        "Don't forget to log breakfast",
        null,
        null,
      );
  } else if (hour >= 12 && hour < 16) {
    final entered = entries.where(
      (entry) => entry.created.hour >= 12 && entry.created.hour < 16,
    );
    if (entered.isEmpty)
      await plugin.show(
        2,
        "Don't forget to log lunch",
        null,
        null,
      );
  } else if (hour >= 16 && hour < 22) {
    final entered = entries.where(
      (entry) => entry.created.hour >= 16 && entry.created.hour < 22,
    );
    if (entered.isEmpty)
      await plugin.show(
        3,
        "Don't forget to log dinner",
        null,
        null,
      );
  }
}

void cancelReminders() {
  if (Platform.isAndroid || Platform.isIOS)
    Workmanager().cancelByUniqueName('reminders');
  else
    timer?.cancel();
}

@pragma(
  'vm:entry-point',
)
void doMobileReminders() {
  Workmanager().executeTask((task, inputData) async {
    const darwinSettings = DarwinInitializationSettings();
    const androidSettings =
        AndroidInitializationSettings('@drawable/nutrition');
    const initSettings = InitializationSettings(
      iOS: darwinSettings,
      android: androidSettings,
    );
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(initSettings);

    final db = AppDatabase();

    final entries = await (db.entries.select()
          ..where(
            (u) => const CustomExpression(
              "created >= strftime('%s', 'now', 'localtime', '-24 hours')",
            ),
          ))
        .get();
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 12) {
      final entered = entries
          .where((entry) => entry.created.hour >= 6 && entry.created.hour < 12);
      if (entered.isEmpty)
        await plugin.show(
          1,
          "Don't forget to log breakfast",
          null,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'breakfast-reminders',
              'Breakfast reminders',
              channelDescription: 'Reminders to log breakfast',
            ),
          ),
        );
    } else if (hour >= 12 && hour < 16) {
      final entered = entries.where(
        (entry) => entry.created.hour >= 12 && entry.created.hour < 16,
      );
      if (entered.isEmpty)
        await plugin.show(
          2,
          "Don't forget to log lunch",
          null,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'lunch-reminders',
              'Lunch reminders',
              channelDescription: 'Reminders to log lunch',
            ),
          ),
        );
    } else if (hour >= 16 && hour < 22) {
      final entered = entries.where(
        (entry) => entry.created.hour >= 16 && entry.created.hour < 22,
      );
      if (entered.isEmpty)
        await plugin.show(
          3,
          "Don't forget to log dinner",
          null,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'dinner-reminders',
              'Dinner reminders',
              channelDescription: 'Reminders to log dinner',
            ),
          ),
        );
    }

    return Future.value(true);
  });
}
