import 'package:amnesia_music_player/globals.dart';

void main() {
  DartVLC.initialize();
  runApp(const App());

  final appDataDirectory = Directory(Globals.appDataPath);

  if(!appDataDirectory.existsSync()) {
    appDataDirectory.createSync();
  }
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
            tertiaryContainer: const Color.fromARGB(255, 105, 105, 105),
            secondaryContainer: const Color.fromARGB(255, 156, 156, 156),
            onPrimary: Colors.white,
            onSecondary: Colors.black
          ),
          scaffoldBackgroundColor: const Color.fromARGB(255, 88, 88, 88)
        ),
        home: const HomePage()
      )
    );
  }
}

class AppState extends ChangeNotifier {
  int navigationSelectedIndex = 0;
  String selectedArtist = '';
  Collection selectedCollection = Collection.empty;
  Track selectedTrack = Track.empty;
  Content selectedContent = Content.empty;
  List<Content>? currentContentQueue;

  void goToPage(int index) {
    navigationSelectedIndex = index;
    notifyListeners();
  }
}
