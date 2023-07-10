import 'package:path/path.dart' as path;

import 'package:amnesia_music_player/globals.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  Map<String, ImageProvider> artists = {};

  @override
  Widget build(BuildContext context) {
    updateArtists();

    return Scaffold(
      body: GridView.extent(
        maxCrossAxisExtent: 200.0,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        padding: const EdgeInsets.all(12.0),
        children: [
          for(MapEntry<String, ImageProvider> item in artists.entries)
            ArtistProfile(name: item.key, image: item.value)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        
      )
    );
  }

  void updateArtists() {
    Map<String, ImageProvider> newArtists = {};

    for(FileSystemEntity item in Directory(Globals.appDataPath).listSync()) {
      if(item is Directory) {
        String basename = path.basename(item.path);
        if(basename.startsWith('--') && basename.endsWith('--')) {
          String artistName = basename.substring(2, basename.length - 2);
          File imageFile = File(path.join(item.path, 'icon.png'));
          ImageProvider image;
          if(imageFile.existsSync()) {
            image = FileImage(imageFile);
          }
          else {
            image = const AssetImage('assets/images/default_artist_icon.png');
          }

          newArtists[artistName] = image;
        }
      }
    }

    setState(() {
      artists = newArtists;
    });
  }
}

class ArtistProfile extends StatelessWidget {
  final ImageProvider image;
  final String name;

  const ArtistProfile({required this.name, required this.image, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: image,
                fit: BoxFit.fill
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(name, style: AppStyles.largeText), 
      ]
    );
  }
}