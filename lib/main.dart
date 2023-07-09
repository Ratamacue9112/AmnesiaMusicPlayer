import 'package:provider/provider.dart';

import 'imports.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Amnesia Music Player',
        theme: ThemeData(
          fontFamily: 'Montserrat',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 65, 65, 65),
            primaryContainer: const Color.fromARGB(255, 97, 97, 97),
            secondaryContainer: const Color.fromARGB(255, 156, 156, 156) ,
            onPrimary: Colors.white
          ),
          scaffoldBackgroundColor: const Color.fromARGB(255, 88, 88, 88)
        ),
        home: const HomePage()
      )
    );
  }
}

class AppState extends ChangeNotifier {}
