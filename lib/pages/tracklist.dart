import 'package:amnesia_music_player/globals.dart';
import 'package:path/path.dart' as path;

class TracklistPage extends StatefulWidget {
  const TracklistPage({super.key});

  @override
  State<TracklistPage> createState() => _TracklistPageState();
}

class _TracklistPageState extends State<TracklistPage> {
  List<Track> tracklist = [];

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();
    ThemeData theme = Theme.of(context);
    bool isUncategorized = appState.selectedCollection.name == 'Uncategorized';

    if(appState.selectedCollection.isEmpty()) {
      return Scaffold(
        body: Center(
          child: Text('You have not selected a collection.', style: AppStyles.largeText)
        ),
      );
    }

    if(!isUncategorized) {
      updateTracklist(appState.selectedCollection);
    }
    else {
      updateUncategorized(appState.selectedCollection);
    }

    Widget bodyWidget;
    if(tracklist.isEmpty) {
      bodyWidget = Column(
        children: [
          const SizedBox(height: 150),
          Center(
            child: Text('${appState.selectedCollection.name} is empty.', style: AppStyles.largeText)
          ),
        ],
      );
    }
    else {
      bodyWidget = Column(
        children: [
          for(int i = 0; i < tracklist.length; i++)
            TracklistItem(tracklist[i], i + 1, isUncategorized,
              deleteItem: (item) {
                if(isUncategorized) {
                  showDialog(context: context, builder: (context) {
                    return AlertDialog(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      content: Text('Are you sure want to delete?\nThis will delete all related content and cannot be undone.', textAlign: TextAlign.center, style: AppStyles.largeText),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Directory(path.join(appState.selectedCollection.directory.parent.parent.path, 'songs', item)).deleteSync(recursive: true);
                            if(appState.selectedTrack.name == item) {
                              appState.selectedTrack = Track.empty;
                            }
                            updateTracklist(appState.selectedCollection);
                            Navigator.pop(context);
                          }, 
                          child: Text('Yes', style: AppStyles.mediumTextSecondary)
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          }, 
                          child: Text('No', style: AppStyles.mediumTextSecondary)
                        )
                      ],
                    );
                  });
                }
                else {
                  for(Track track in tracklist) {
                    if(track.name == item) {
                      setState(() {
                        tracklist.remove(track);
                      });
                      break;
                    }
                  }

                  if(appState.selectedTrack.name == item) {
                    appState.selectedTrack = Track.empty;
                  }

                  File tracklistFile = File(path.join(appState.selectedCollection.directory.path, 'tracklist.txt'));
                  tracklistFile.writeAsStringSync(Utilities.listToString(tracklist));
                  updateTracklist(appState.selectedCollection);
                }
              },
              moveItem: (index, isUp) {
                if(isUp && index != 0) {
                  Track movingItem = tracklist[index];
                  Track originalItem = tracklist[index - 1];

                  setState(() {
                    tracklist[index] = originalItem;
                    tracklist[index - 1] = movingItem;
                  });
                }
                else if(!isUp && index != tracklist.length - 1) {
                  Track movingItem = tracklist[index];
                  Track originalItem = tracklist[index + 1];

                  setState(() {
                    tracklist[index] = originalItem;
                    tracklist[index + 1] = movingItem;
                  });
                }

                File tracklistFile = File(path.join(appState.selectedCollection.directory.path, 'tracklist.txt'));
                tracklistFile.writeAsStringSync(Utilities.listToString(tracklist));
                updateTracklist(appState.selectedCollection);
              },
              getQueue: (startIndex) => getQueue(startIndex),
            ),
          Visibility(
            visible: getQueue(0).isNotEmpty,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        List<Content> queue = getQueue(0);
                        if(queue.isNotEmpty) {
                          queue.shuffle();
                          appState.currentContentQueue = queue;
                          appState.selectedContent = queue.first;
                          appState.goToPage(4);
                        }
                      }, 
                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                      icon: Icon(Icons.shuffle, color: theme.colorScheme.onSecondary), 
                      label: Text('Shuffle', style: AppStyles.largeTextSecondary)
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 75)
        ],
      );
    }

    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Image(image: appState.selectedCollection.icon, width: 250, height: 250),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SizedBox(
                    height: 250,
                    child: Column(
                      children: [
                        const Spacer(),
                        RichText(text: TextSpan(
                          children: [
                            TextSpan(text: appState.selectedCollection.name, style: AppStyles.titleText.copyWith(fontSize: 45)),
                            TextSpan(text: '  ${appState.selectedCollection.artistName}', style: AppStyles.titleText.copyWith(fontWeight: FontWeight.w100, fontSize: 30))
                          ]
                        )),
                      ],
                    )
                  ),
                )
              ],
            ),
          ),
          bodyWidget,
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (context) {
            if(isUncategorized) {
              return AddTrackNewDialog(updatePage: () {
                updateUncategorized(appState.selectedCollection);
              });
            }
            return AddTrackChooseDialog(updatePage: () {
              updateTracklist(appState.selectedCollection);
            });
          });
        },
        tooltip: 'Add Track',
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: const Icon(Icons.add)
      ),
    );
  }

  void updateTracklist(Collection collection) {
    List<Track> newTracklist = [];

    File tracklistFile = File(path.join(collection.directory.path, 'tracklist.txt'));
    if(!tracklistFile.parent.existsSync()) {
      return;
    }
    if(!tracklistFile.existsSync()) {
      tracklistFile.createSync();
    }

    Directory songsParentDirectory = Directory(path.join(collection.directory.parent.parent.path, 'songs'));
    if(!songsParentDirectory.existsSync()) {
      songsParentDirectory.createSync();
    }
    List<String> songDirectories = [];
    for(FileSystemEntity item in songsParentDirectory.listSync()) {
      if(item is Directory) {
        songDirectories.add(path.basename(item.path));
      }
    }

    bool rewriteTracklist = false;
    for(String line in tracklistFile.readAsLinesSync()) {
      if(songDirectories.contains(line)) {
        Track track = Track(line, collection.artistName, collection, Directory(path.join(songsParentDirectory.path, line)));
        track.settings!.read();
        track.hasDemo = track.settings!.get<String>('demo', '') != '';
        track.hasFinal = track.settings!.get<String>('final', '') != '';
        
        newTracklist.add(track);
      }
      else {
        rewriteTracklist = true;
      }
    }

    if(rewriteTracklist) {
      tracklistFile.writeAsStringSync(Utilities.listToString(newTracklist));
    }

    setState(() {
      tracklist = newTracklist;
    });
  }

  void updateUncategorized(Collection collection) {
    List<String> usedSongs = [];
    for(FileSystemEntity item in Directory(path.join(collection.directory.parent.parent.path, 'collections')).listSync()) {
      if(item is Directory && path.basename(item.path) != 'Uncategorized') {
        for(String track in File(path.join(item.path, 'tracklist.txt')).readAsLinesSync()) {
          if(!usedSongs.contains(track)) usedSongs.add(track);
        }
      }
    }

    List<Track> unusedSongs = [];
    for(FileSystemEntity item in Directory(path.join(collection.directory.parent.parent.path, 'songs')).listSync()) {
      String songName = path.basename(item.path);
      Track track = Track(songName, collection.artistName, collection, Directory(item.path));
      track.settings!.read();
      track.hasDemo = track.settings!.get<String>('demo', '') != '';
      track.hasFinal = track.settings!.get<String>('final', '') != '';
      if(!usedSongs.contains(songName)) unusedSongs.add(track);
    }

    setState(() {
      tracklist = unusedSongs;
    });
  }

  List<Content> getQueue(int startIndex) {
    List<Content> queue = [];

    for(int i = startIndex; i < tracklist.length; i++) {
      if(tracklist[i].hasFinal || tracklist[i].hasDemo) {
        if(!tracklist[i].hasFinal) {
          final demoName = tracklist[i].settings!.get<String>('demo', '');
          Content content = Content(demoName.split('.').first, tracklist[i], File(path.join(tracklist[i].directory.path, demoName)), SongContentType.audio);
          content.isDemo = true;
          queue.add(content);
        }
        else {
          final finalName = tracklist[i].settings!.get<String>('final', '');
          Content content = Content(finalName.split('.').first, tracklist[i], File(path.join(tracklist[i].directory.path, finalName)), SongContentType.audio);
          content.isFinal = true;
          queue.add(content);
        }
      }
    }
    return queue;
  }
}

class TracklistItem extends StatefulWidget {
  final int trackNumber;
  final Track track;
  final bool isUncategorized;

  final Function(String item) deleteItem;
  final Function(int index, bool up) moveItem;
  final List<Content> Function(int startIndex) getQueue;

  const TracklistItem(this.track, this.trackNumber, this.isUncategorized, {required this.deleteItem, required this.moveItem, required this.getQueue, super.key});

  @override
  State<TracklistItem> createState() => _TracklistItemState();
}

class _TracklistItemState extends State<TracklistItem> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState appState = context.watch<AppState>();

    return SizedBox(
      height: 40,
      child: GestureDetector(
        onTap: () {
          if(!widget.track.hasDemo && !widget.track.hasFinal) {
            appState.selectedTrack = widget.track;
            appState.goToPage(3);
          }
          else {
            appState.currentContentQueue = widget.getQueue(widget.trackNumber - 1);
            appState.selectedContent = appState.currentContentQueue!.first;
            appState.goToPage(4);
          }

        },
        child: MouseRegion(
          onEnter: (event) => setState(() => isHovering = true),
          onExit: (event) => setState(() => isHovering = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              color: widget.trackNumber % 2 == 0 ? theme.colorScheme.tertiaryContainer : theme.colorScheme.primaryContainer,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '${widget.trackNumber}.   ', style: AppStyles.largeText.copyWith(fontWeight: FontWeight.w100)),
                          TextSpan(
                            text: widget.track.settings!.get<bool>('workingTitle', false) ? '[${widget.track.name}]' : widget.track.name, 
                            style: AppStyles.largeText.copyWith(fontWeight: widget.track.hasDemo || widget.track.hasFinal ? FontWeight.normal : FontWeight.w300)
                          ),
                          TextSpan(text: widget.track.hasDemo && !widget.track.hasFinal ? ' (Demo)' : '', style: AppStyles.largeText.copyWith(fontWeight: FontWeight.w200))
                        ]
                      )
                    )
                  ),
                  const Spacer(),
                  // Open content
                  Visibility(
                    visible: widget.isUncategorized ? false : isHovering,
                    child: IconButton(
                      onPressed: () {
                        appState.selectedTrack = widget.track;
                        appState.goToPage(3);
                      },
                      icon: Icon(Icons.more_horiz, color: theme.colorScheme.secondaryContainer),
                      tooltip: 'Open content',
                    )
                  ),
                  // Move up
                  Visibility(
                    visible: widget.isUncategorized ? false : isHovering,
                    child: IconButton(
                      onPressed: () {
                        widget.moveItem(widget.trackNumber - 1, true);
                      },
                      icon: Icon(Icons.arrow_upward, color: theme.colorScheme.secondaryContainer),
                      tooltip: 'Move up',
                    )
                  ),
                  // Move down
                  Visibility(
                    visible: widget.isUncategorized ? false : isHovering,
                    child: IconButton(
                      onPressed: () {
                        widget.moveItem(widget.trackNumber - 1, false);
                      },
                      icon: Icon(Icons.arrow_downward, color: theme.colorScheme.secondaryContainer), 
                      tooltip: 'Move down',
                    )
                  ),
                  // Delete
                  Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Visibility(
                      visible: isHovering,
                      child: IconButton(
                        onPressed: () {
                          widget.deleteItem(widget.track.name);
                        },
                        icon: Icon(widget.isUncategorized ? Icons.delete : Icons.highlight_remove, color: theme.colorScheme.secondaryContainer),
                        tooltip: 'Remove',
                      )
                    ),
                  )
                ],
              )
            ),
          ),
        ),
      ),
    );
  }
}

class AddTrackChooseDialog extends StatelessWidget {
  const AddTrackChooseDialog({super.key, required this.updatePage});

  final Function updatePage;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('Add a Track', style: AppStyles.titleText),
          ),
          // Add existing or create new
          const Spacer(),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(context: context, builder: (context) {
                    return AddTrackExistingDialog(updatePage: updatePage);
                  });
                },
                child: Text('Add Existing Song', style: AppStyles.largeTextSecondary)
              ),
              const Spacer(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('or', style: AppStyles.largeText),
          ),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(context: context, builder: (context) {
                    return AddTrackNewDialog(updatePage: updatePage);
                  });
                },
                child: Text('Create New Song', style: AppStyles.largeTextSecondary)
              ),
              const Spacer()
            ],
          ),
          // Cancel
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                    onPressed: () {
                      Navigator.pop(context);
                    }, 
                    child: Text('Cancel', style: AppStyles.mediumTextSecondary)
                  ),
                )
              )
            ],
          )
        ]
      ),
    );
  }
}

class AddTrackExistingDialog extends StatefulWidget {
  const AddTrackExistingDialog({super.key, required this.updatePage});

  final Function updatePage;

  @override
  State<AddTrackExistingDialog> createState() => _AddTrackExistingDialogState();
}

class _AddTrackExistingDialogState extends State<AddTrackExistingDialog> {
  TextEditingController searchController = TextEditingController(text: '');

  List<String> alreadyAddedSongs = [];
  Map<String, Settings> allSongs = {};
  Map<String, Settings> filteredSongs = {};

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState appState = context.watch<AppState>();

    updateSongs(appState.selectedCollection.directory);
    if(searchController.text == '') {
      filteredSongs = allSongs;
    }

    return Dialog(
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Text('Add Existing Song', style: AppStyles.titleText),
          ),
          // Search box
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  filteredSongs = {
                    for (final key in allSongs.keys)
                      if (key.toLowerCase().contains(value.toLowerCase())) key: allSongs[key]!
                  };
                });
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.colorScheme.secondaryContainer,
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search for songs',
              ),
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: filteredSongs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: ListTile(
                    title: Text(
                      (filteredSongs.values.elementAt(index).get<bool>('workingTitle', false) ? '[${filteredSongs.keys.elementAt(index)}]' : filteredSongs.keys.elementAt(index)) 
                      + (filteredSongs.values.elementAt(index).get('demo', '') != '' && filteredSongs.values.elementAt(index).get('final', '') == '' ? ' (Demo)' : '')
                    ),
                    tileColor: theme.colorScheme.secondaryContainer,
                    onTap: () {
                      List<String> newTracklist = alreadyAddedSongs;
                      newTracklist.add(filteredSongs.keys.toList()[index]);

                      File tracklistFile = File(path.join(appState.selectedCollection.directory.path, 'tracklist.txt'));
                      tracklistFile.writeAsStringSync(Utilities.listToString(newTracklist));

                      widget.updatePage();

                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          // Cancel
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel', style: AppStyles.mediumTextSecondary),
                  ),
                )
              )
            ],
          )
        ],
      )
    );
  }

  void updateSongs(Directory collectionDirectory) {
    Map<String, Settings> updatedSongs = {};

    setState(() {
      alreadyAddedSongs = File(path.join(collectionDirectory.path, 'tracklist.txt')).readAsLinesSync();
    });

    for(FileSystemEntity item in Directory(path.join(collectionDirectory.parent.parent.path, 'songs')).listSync()) {
      if(item is Directory) {
        String songName = path.basename(item.path);
        if(!alreadyAddedSongs.contains(songName)) {
          Settings settings = Settings(Directory(item.path));
          settings.read();
          updatedSongs[songName] = settings;
        }
      }
    }

    setState(() {
      allSongs = updatedSongs;
    });
  }
}

class AddTrackNewDialog extends StatefulWidget {
  const AddTrackNewDialog({required this.updatePage, this.isEditing = false, this.track, super.key});

  final Function updatePage;
  final bool isEditing;
  final Track? track;

  @override
  State<AddTrackNewDialog> createState() => _AddTrackNewDialogState();
}

class _AddTrackNewDialogState extends State<AddTrackNewDialog> {
  TextEditingController nameController = TextEditingController();
  String currentTrackName = '';
  String currentCreateTrackError = '';
  bool currentTrackIsWorkingTitle = false;

  @override
  void initState() {
    if(widget.isEditing) {
      setState(() {
        nameController.value = TextEditingValue(text: widget.track!.name);
        currentTrackName = widget.track!.name;
        currentTrackIsWorkingTitle = widget.track!.settings!.get('workingTitle', false);
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState appState = context.watch<AppState>();

    return StatefulBuilder(builder: (stfContext, stfSetState) {
      return Dialog(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Text(widget.isEditing ? 'Edit ${appState.selectedTrack.name}' : 'Create New Song', style: AppStyles.titleText),
            ),
            // Name field
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.secondaryContainer,
                  hintText: 'Enter song name here',
                ),
                controller: nameController,
                
                onChanged: (value) => {
                  stfSetState(() {
                    currentTrackName = value;
                  })
                },
              ),
            ),
            // Is working title
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: 250,
                  child: CheckboxListTile(
                    value: currentTrackIsWorkingTitle, 
                    title: DefaultTextStyle(
                      style: AppStyles.largeText,
                      child: const Text('Working Title')
                    ),       
                    onChanged: (value) {
                      setState(() => currentTrackIsWorkingTitle = value!);
                    }
                  ),
                ),
                const Spacer()
              ],
            ),
            // Cancel and confirm buttons
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Text(currentCreateTrackError, style: AppStyles.titleText.copyWith(color: const Color.fromARGB(255, 202, 13, 0), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                          onPressed: () {
                            Navigator.pop(context);
                          }, 
                          child: Text('Cancel', style: AppStyles.mediumTextSecondary)
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        flex: 5,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                          onPressed: () {
                            if(currentTrackName == '') {
                              setState(() {
                                currentCreateTrackError = 'The song needs a name!';
                              });
                              return;
                            }

                            List<String> songs = [];
                            Directory songsDirectory = Directory(path.join(appState.selectedCollection.directory.parent.parent.path, 'songs'));
                            for(FileSystemEntity item in songsDirectory.listSync()) {
                              if(item is Directory) songs.add(path.basename(item.path));
                            }

                            if(songs.contains(currentTrackName) && (widget.track!.name != currentTrackName)) {
                              setState(() {
                                currentCreateTrackError = 'A song with this name already exists!';
                              });
                              return;
                            }

                            Directory newSongDirectory = Directory(path.join(songsDirectory.path, currentTrackName));
                            if(widget.isEditing) {
                              File tracklistFile = File(path.join(widget.track!.collection.directory.path, 'tracklist.txt'));
                              List<String> tracklist = tracklistFile.readAsLinesSync();
                              tracklist.remove(path.basename(widget.track!.directory.path));
                              tracklist.add(currentTrackName);
                              tracklistFile.writeAsStringSync(Utilities.listToString(tracklist));

                              Track newTrack = widget.track!;
                              newTrack.name = currentTrackName;
                              newTrack.directory.renameSync(newSongDirectory.path);
                              newTrack.directory = newSongDirectory;
                              newTrack.settings!.set('workingTitle', currentTrackIsWorkingTitle);
                              newTrack.settings!.songDirectory = newSongDirectory;
                              newTrack.settings!.save();
                              appState.selectedTrack = newTrack;
                            }
                            else {
                              newSongDirectory.createSync();
                              Settings settings = Settings(newSongDirectory);
                              settings.set('workingTitle', currentTrackIsWorkingTitle);
                              settings.save();

                              File tracklistFile = File(path.join(appState.selectedCollection.directory.path, 'tracklist.txt'));
                              List<String> tracklist = tracklistFile.readAsLinesSync();
                              tracklist.add(currentTrackName);
                              tracklistFile.writeAsStringSync(Utilities.listToString(tracklist));
                            }

                            widget.updatePage();
                            Navigator.pop(context);
                          },
                          child: Text(widget.isEditing ? 'Edit' : 'Confirm', style: AppStyles.mediumTextSecondary)
                        )
                      )
                    ]
                  )
                ]
              )
            )
          ],
        ),
      );
    });
  }
}