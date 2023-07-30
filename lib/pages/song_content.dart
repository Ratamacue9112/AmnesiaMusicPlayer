import 'package:amnesia_music_player/globals.dart';
import 'package:path/path.dart' as path;

class SongContentPage extends StatefulWidget {
  const SongContentPage({super.key});

  @override
  State<SongContentPage> createState() => _SongContentPageState();
}

class _SongContentPageState extends State<SongContentPage> {
  List<Content> content = [];

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState appState = context.watch<AppState>();
    
    if(appState.selectedTrack.name == '') {
      return Scaffold(
        body: Center(
          child: Text('You have not selected a track.', style: AppStyles.largeText),
        )
      );
    }

    updateContent(appState.selectedTrack);

    Widget bodyWidget;
    if(content.isEmpty) {
      bodyWidget = Column(
        children: [
          const SizedBox(height: 150),
          Center(
            child: Text('${appState.selectedTrack.name} has no content.', style: AppStyles.largeText)
          ),
        ],
      );
    }
    else {
      bodyWidget = ListView.builder(
        itemCount: content.length,
        itemBuilder: (context, index) {
          return SongContentItem(content[index], index, updatePage: () => updateContent(appState.selectedTrack));
        },
      );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(image: appState.selectedTrack.collection.icon, width: 200, height: 200),
                    const SizedBox(width: 20),
                    SizedBox(
                      height: 200,
                      width: constraints.maxWidth - 300,
                      child: Column(
                        children: [
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              appState.selectedTrack.settings!.get('workingTitle', false) ? '[${appState.selectedTrack.name}]'  : appState.selectedTrack.name, 
                              style: AppStyles.titleText.copyWith(fontSize: 50)
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${appState.selectedTrack.collection.name} - ${appState.selectedTrack.artistName}', 
                              style: AppStyles.titleText.copyWith(fontWeight: FontWeight.w100), 
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: bodyWidget)
            ],
          );
        }
      ),
      floatingActionButton: Wrap(
        children: [
          // Add content
          Container( 
            margin: const EdgeInsets.all(5.0),
            child: FloatingActionButton(
              backgroundColor: theme.colorScheme.secondaryContainer,
              onPressed: () {
                showDialog(context: context, builder: (context) {
                  return AddContentChooseFileTypeDialog(updatePage: () => updateContent(appState.selectedTrack));
                });
              },
              tooltip: 'Add content',
              child: const Icon(Icons.add),
            ),
          ),
          // Edit
          Container( 
            margin: const EdgeInsets.all(5.0),
            child: FloatingActionButton(
              backgroundColor: theme.colorScheme.secondaryContainer,
              onPressed: () {
                showDialog(context: context, builder: (context) {
                  return AddTrackNewDialog(isEditing: true, track: appState.selectedTrack, updatePage: () => setState(() {}));
                });
              },
              tooltip: 'Edit song',
              child: const Icon(Icons.edit),
            ),
          )
        ],
      )
    );
  }

  void updateContent(Track track) {
    List<Content> newContent = [];

    for(FileSystemEntity item in track.directory.listSync()) {
      if(item is File) {
        String fileName = path.basename(item.path).split('.').first;
        String fileExtension = path.basename(item.path).split('.').last;
        FileType fileType = FileType.audio;

        if(FileCategories.images.contains(fileExtension)) {
          fileType = FileType.image;
        }
        else if(FileCategories.videos.contains(fileExtension)) {
          fileType = FileType.video;
        } 
        else if(FileCategories.audio.contains(fileExtension)) {
          fileType = FileType.audio;
        } 
        else {
          continue;
        }

        newContent.add(Content(fileName, track, item, fileType));
      }
    }

    setState(() {
      content = newContent;
    });
  }
}

class SongContentItem extends StatefulWidget {
  const SongContentItem(this.content, this.index, {required this.updatePage, super.key});

  final Content content;
  final int index;

  final Function updatePage;

  @override
  State<SongContentItem> createState() => _SongContentItemState();
}

class _SongContentItemState extends State<SongContentItem> {
  bool isHovering = false;
  String currentContentRename = '';

  TextEditingController renameController = TextEditingController();

  @override 
  void initState() {
    setState(() {
      renameController.value = TextEditingValue(text: widget.content.name);
      currentContentRename = widget.content.name;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState appState = context.watch<AppState>();

    IconData icon;
    switch(widget.content.type) {
      case FileType.image:
        icon = Icons.image;
        break;
      case FileType.video:
        icon = Icons.movie;
        break;
      case FileType.audio:
        icon = Icons.music_note;
        break;
      default:
        icon = Icons.question_mark;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: MouseRegion(
        onEnter: (event) => setState(() => isHovering = true),
        onExit: (event) => setState(() => isHovering = false),
        child: ListTile(
          title: Text(widget.content.name, style: AppStyles.largeText),
          leading: Icon(icon, color: theme.colorScheme.onPrimary),
          tileColor: widget.index % 2 == 0 ? theme.colorScheme.primaryContainer : theme.colorScheme.tertiaryContainer,
          onTap: () {
            appState.selectedContent = widget.content;
            appState.goToPage(4);
          },
          trailing:  Wrap(
            direction: Axis.horizontal,
            children: [
              // Rename
              Visibility(
                visible: isHovering,
                child: IconButton(
                  onPressed: () {
                    showDialog(context: context, builder: (context) {
                      return StatefulBuilder(
                        builder: (stfContext, stfSetState) {
                          return AlertDialog(
                            title: Text('Rename content', style: AppStyles.mediumText),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            content: TextField(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: theme.colorScheme.secondaryContainer,
                                hintText: 'Enter song name here',
                              ),
                              controller: renameController,
                              
                              onChanged: (value) => {
                                stfSetState(() {
                                  currentContentRename = value;
                                })
                              },
                            ),
                            actions: [
                              // Confirm
                              TextButton(
                                onPressed: () {
                                  if(currentContentRename == '') return;
                                  File newFile = File(path.join(widget.content.file.parent.path, '$currentContentRename.${widget.content.file.path.split('.').last}'));

                                  if(newFile.existsSync()) return;

                                  widget.content.file.renameSync(newFile.path);

                                  widget.updatePage();
                                  Navigator.pop(context);
                                },
                                child: const Text('Confirm'),
                              ),
                              // Cancel
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              )
                            ],
                          );
                        }
                      );
                    });
                  },
                  icon: Icon(Icons.edit, color: theme.colorScheme.secondaryContainer),
                  tooltip: 'Rename',
                )
              ),
              // Delete
              Visibility(
                visible: isHovering,
                child: IconButton(
                  onPressed: () {
                    showDialog(context: context, builder: (context) {
                      return AlertDialog(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        content: Text('Are you sure want to delete?', textAlign: TextAlign.center, style: AppStyles.largeText),
                        actions: [
                          TextButton(
                            onPressed: () {
                              widget.content.file.deleteSync(recursive: true);
                              if(appState.selectedContent.name == widget.content.name) {
                                appState.selectedContent = Content.empty;
                              }
                              widget.updatePage();
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
                  }, 
                  icon: Icon(Icons.delete, color: theme.colorScheme.secondaryContainer),
                  tooltip: 'Delete',
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}

class AddContentChooseFileTypeDialog extends StatelessWidget {
  const AddContentChooseFileTypeDialog({required this.updatePage, super.key});

  final Function updatePage;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState appState = context.watch<AppState>();
    
    return Dialog(
      child: Column(
        children: [
          // Choose file type
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Add image
                Expanded(
                  child: Tooltip(
                    message: 'Add image',
                    child: ElevatedButton(
                      onPressed: () async {
                        openFileDialog(FileType.image, appState.selectedTrack.directory);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0),
                        ),
                        backgroundColor: theme.colorScheme.primaryContainer
                      ),
                      child: Icon(Icons.image, size: 100, color: theme.colorScheme.onPrimary)
                    ),
                  )
                ),
                // Add video
                Expanded(
                  child: Tooltip(
                    message: 'Add video',
                    child: ElevatedButton(
                      onPressed: () {
                        openFileDialog(FileType.video, appState.selectedTrack.directory);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0)
                        ),
                        backgroundColor: theme.colorScheme.tertiaryContainer
                      ),
                      child: Icon(Icons.movie, size: 100, color: theme.colorScheme.onPrimary)
                    ),
                  )
                ),
                // Add audio
                Expanded(
                  child: Tooltip(
                    message: 'Add audio',
                    child: ElevatedButton(
                      onPressed: () {
                        openFileDialog(FileType.audio, appState.selectedTrack.directory);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0)
                        ),
                        backgroundColor: theme.colorScheme.primaryContainer
                      ),
                      child: Icon(Icons.music_note, size: 100, color: theme.colorScheme.onPrimary)
                    ),
                  )
                )
              ],
            ),
          ),
          // Cancel
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  }, 
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0.0),
                    ),
                    backgroundColor: theme.colorScheme.secondaryContainer
                  ),
                  child: Text('Cancel', style: AppStyles.mediumTextSecondary)
                ),
              ),
            ],
          )
        ],
      )
    );
  }

  void openFileDialog(FileType type, Directory trackDirectory) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select content',
      type: type
    );

    if(result != null) {
      File(result.files.single.path!).copySync(path.join(trackDirectory.path, path.basename(result.files.single.path!)));
    }

    updatePage();
  }
}