import 'globals.dart';

class Collection {
  final String name;
  final String artistName;
  final ImageProvider icon;
  final Directory directory;

  static final Collection empty = Collection('', '', const AssetImage('assets/images/uncategorized_collection_icon.png'), Directory(Globals.appDataPath));

  const Collection(this.name, this.artistName, this.icon, this.directory);

  bool isEmpty() {
    return name == '';
  }
}

class Track {
  final String name;
  final String artistName;
  final Collection collection;
  final Directory directory;

  const Track(this.name, this.artistName, this.collection, this.directory);
}