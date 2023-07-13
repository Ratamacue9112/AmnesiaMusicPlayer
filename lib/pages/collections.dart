import 'package:amnesia_music_player/globals.dart';
import 'package:path/path.dart' as path;

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  Map<String, ImageProvider> collections = {};

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();
    ImageProvider artistIcon;

    updateCollections();

    File artistIconFile = File(path.join(Globals.appDataPath, '--${appState.selectedArtist}--', 'icon.png'));
    if(artistIconFile.existsSync()) {
      artistIcon = FileImage(artistIconFile);
    }
    else {
      artistIcon = const AssetImage('assets/images/default_artist_icon.png');
    }

    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: artistIcon,
                      fit: BoxFit.contain
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              RichText(
                text: TextSpan(
                  style: AppStyles.titleText,
                  children: [
                    TextSpan(text: appState.selectedArtist, style: const TextStyle(fontWeight: FontWeight.w300)),
                    const TextSpan(text: ' - Collections', style: TextStyle(fontWeight: FontWeight.w100))
                  ]
                )
              )
            ]
          ),
          Expanded(
            child: GridView.extent(
              maxCrossAxisExtent: 300.0,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              padding: const EdgeInsets.all(12.0),
              children: [
                for(MapEntry<String, ImageProvider> item in collections.entries)
                  CollectionProfile(item.key, item.value)
              ],
            ),
          )
        ],
      )
    );
  }

  void updateCollections() {
    AppState appState = context.watch<AppState>();
    Map<String, ImageProvider> newCollections = {};

    for(FileSystemEntity item in Directory(path.join(Globals.appDataPath, '--${appState.selectedArtist}--', 'collections')).listSync()) {
      if(item is Directory) {
        String basename = path.basename(item.path);
        if(basename.startsWith('--') && basename.endsWith('--')) {
          String collectionName = basename.substring(2, basename.length - 2);
          File imageFile = File(path.join(item.path, 'icon.png'));
          ImageProvider image;
          if(imageFile.existsSync()) {
            image = FileImage(imageFile);
          }
          else {
            image = const AssetImage('assets/images/default_collection_icon.png');
          }

          newCollections[collectionName] = image;
        }
      }
    }

    setState(() {
      collections = newCollections;
    });
  }
}

class CollectionProfile extends StatelessWidget {
  final ImageProvider image;
  final String name;

  const CollectionProfile(this.name, this.image, {super.key});

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();

    return InkWell(
      onTap: () {
        appState.selectedCollection = name;
        appState.goToPage(2);
      },
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: image,
                    fit: BoxFit.contain
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(name, style: AppStyles.largeText), 
          ]
        ),
      ),
    );
  }
}