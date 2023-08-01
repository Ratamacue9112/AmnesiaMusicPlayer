import 'globals.dart';
import 'package:path/path.dart' as path;

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
  String name;
  final String artistName;
  final Collection collection;
  Directory directory;
  bool hasDemo = false;
  bool hasFinal = false;

  Settings? settings;

  static final Track empty = Track('', '', Collection.empty, Collection.empty.directory);

  Track(this.name, this.artistName, this.collection, this.directory) {
    settings = Settings(directory);
  }
}

class Content {
  final String name;
  final Track track;
  final File file;
  final SongContentType type;
  bool isDemo = false;
  bool isFinal = false;

  Content(this.name, this.track, this.file, this.type);

  static Content empty = Content('', Track.empty, File(''), SongContentType.text);
}

enum SongContentType {
  image,
  video,
  audio,
  text,
}

class Settings {
  Map<String, String> settings = {};

  Directory songDirectory;

  Settings(this.songDirectory);

  T get<T>(String setting, T defaultValue) {
    if(!settings.containsKey(setting)) return defaultValue; 

    if(T == bool) {
      return (settings[setting] == 'true') as T;
    }
    if(T == String) {
      return settings[setting].toString() as T;
    }

    return defaultValue;
  }

  void set<T>(String setting, T value) {
    settings[setting] = value.toString();
  }

  void read() {
    File settingsFile = File(path.join(songDirectory.path, 'settings.txt'));
    if(!settingsFile.existsSync()) settingsFile.createSync();

    settings = {};

    for(String line in settingsFile.readAsLinesSync()) {
      List<String> setting = line.split('=');
      settings[setting.first] = setting.last;
    }
  }

  void save() {
    String settingsString = '';

    for(String setting in settings.keys) {
      settingsString += '$setting=${settings[setting]}\n';
    }

    File settingsFile = File(path.join(songDirectory.path, 'settings.txt'));
    if(!settingsFile.existsSync()) settingsFile.createSync();

    settingsFile.writeAsStringSync(settingsString);
  }
}