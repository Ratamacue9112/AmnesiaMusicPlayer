import 'package:amnesia_music_player/globals.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    AppStyles.initStyles(theme);

    final page;
    switch(selectedIndex) {
      case 0:
        page = const ArtistsPage();
        break;
      case 1:
        page = const CollectionsPage();
        break;
      case 2:
        page = const TracklistPage();
        break;
      case 3:
        page = const ContentPlayerPage();
        break;
      default:
        page = const ArtistsPage();
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              backgroundColor: theme.colorScheme.primaryContainer,
              indicatorColor: theme.colorScheme.secondaryContainer,
              selectedIconTheme: const IconThemeData(color: Color.fromARGB(255, 46, 43, 43)),
              unselectedIconTheme: const IconThemeData(color: Color.fromARGB(255, 194, 194, 194)),
              extended: true,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.mic_external_on),
                  label: Text('Artists', style: AppStyles.mediumText),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.library_music),
                  label: Text('Collections', style: AppStyles.mediumText),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.queue_music),
                  label: Text('Tracklist', style: AppStyles.mediumText),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Content Player', style: AppStyles.mediumText),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                updatePage(value);
              },
            ),
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.primaryContainer,
              child: page,
            ),
          ),
        ],
      ),
    );
  }

  void updatePage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }
}
