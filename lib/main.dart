import 'package:drift/drift.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:fit_book/database/database.dart';
import 'package:fit_book/entry/entry_page.dart';
import 'package:fit_book/entry/entry_state.dart';
import 'package:fit_book/food/food_page.dart';
import 'package:fit_book/graph_page.dart';
import 'package:fit_book/reminders.dart';
import 'package:fit_book/settings/settings_state.dart';
import 'package:fit_book/weight/weight_page.dart';
import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

AppDatabase db = AppDatabase();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = await (db.settings.select()).getSingle();
  final settingsState = SettingsState(settings);

  if (settings.reminders)
    setupReminders();
  else
    cancelReminders();

  final packageInfo = await PackageInfo.fromPlatform();
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: '${packageInfo.appName}/${packageInfo.version} (brandon@presley.nz)',
    url: 'https://github.com/brandonp2412/FitBook',
  );
  OpenFoodAPIConfiguration.globalUser = User(
    userId: settingsState.value.offLogin ?? '',
    password: settingsState.value.offPassword ?? '',
  );

  runApp(appProviders(settingsState));
}

Widget appProviders(SettingsState settingsState) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => settingsState),
        ChangeNotifierProvider(create: (context) => EntryState()),
      ],
      child: const App(),
    );

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>().value;

    final defaultTheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    final defaultDark = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        title: 'FitBook',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: settings.systemColors ? lightDynamic : defaultTheme,
          fontFamily: 'Manrope',
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: settings.systemColors ? darkDynamic : defaultDark,
          fontFamily: 'Manrope',
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
        themeMode: ThemeMode.values
            .byName(settings.themeMode.replaceAll('ThemeMode.', '')),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          body: TabBarView(
            children: [
              EntryPage(),
              GraphPage(),
              FoodPage(),
              WeightPage(),
            ],
          ),
          bottomNavigationBar: TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.date_range),
                text: "Diary",
              ),
              Tab(
                icon: Icon(Icons.insights),
                text: "Graph",
              ),
              Tab(
                icon: Icon(Icons.restaurant),
                text: "Food",
              ),
              Tab(
                icon: Icon(Icons.scale),
                text: "Weight",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
