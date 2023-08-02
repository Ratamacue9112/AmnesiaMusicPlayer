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
      bodyWidget = Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for(Content item in content)
                  SongContentItem(item, content.indexOf(item), updatePage: () => updateContent(appState.selectedTrack)),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(context: context, builder: (context) => EditTextNoteDialog(File(path.join(appState.selectedTrack.directory.path, 'lyrics.txt')), '${appState.selectedTrack.name} - Edit Lyrics'));
                          }, 
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                          child: Text('Edit Lyrics', style: AppStyles.largeTextSecondary)
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
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
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: appState.selectedTrack.settings!.get('workingTitle', false) ? '[${appState.selectedTrack.name}]'  : appState.selectedTrack.name, 
                                    style: AppStyles.titleText.copyWith(fontSize: 50)
                                  ),
                                  TextSpan(
                                    text: appState.selectedTrack.hasDemo && !appState.selectedTrack.hasFinal ? ' (${appState.selectedTrack.demoTitleNote})'  : '', 
                                    style: AppStyles.titleText.copyWith(fontSize: 30, fontWeight: FontWeight.w200)
                                  ),
                                ],
                              ),
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

    String demoName = track.settings!.get<String>('demo', '').split('.').first;
    String finalName = track.settings!.get<String>('final', '').split('.').first;

    for(FileSystemEntity item in track.directory.listSync()) {
      if(item is File) {
        String fileName = path.basename(item.path).split('.').first;
        String fileExtension = path.basename(item.path).split('.').last;
        late SongContentType fileType;

        if(FileCategories.images.contains(fileExtension)) {
          fileType = SongContentType.image;
        }
        else if(FileCategories.videos.contains(fileExtension)) {
          fileType = SongContentType.video;
        } 
        else if(FileCategories.audio.contains(fileExtension)) {
          fileType = SongContentType.audio;
        } 
        else if(fileExtension == 'txt' && !['lyrics', 'settings'].contains(fileName)) {
          fileType = SongContentType.text;
        }
        else {
          continue;
        }

        Content content = Content(fileName, track, item, fileType);
        
        if(finalName != '' && finalName == fileName) {
          content.isFinal = true;
        }
        else if(demoName != '' && demoName == fileName) {
          content.isDemo = true;
        }
        
        newContent.add(content);
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
  String currentTitleNote = '';

  TextEditingController renameController = TextEditingController();
  TextEditingController titleNoteController = TextEditingController();

  @override 
  void initState() {
    setState(() {
      renameController.value = TextEditingValue(text: widget.content.name);
      currentContentRename = widget.content.name;

      titleNoteController.value = TextEditingValue(text: widget.content.track.demoTitleNote);
      currentTitleNote = widget.content.track.demoTitleNote;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState appState = context.watch<AppState>();

    IconData icon;
    switch(widget.content.type) {
      case SongContentType.image:
        icon = Icons.image;
        break;
      case SongContentType.video:
        icon = Icons.movie;
        break;
      case SongContentType.audio:
        icon = Icons.music_note;
        break;
      case SongContentType.text:
        icon = Icons.note_alt;
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
          tileColor: widget.content.isDemo ? const Color.fromARGB(255, 166, 78, 207)
            : widget.content.isFinal ? const Color.fromARGB(255, 223, 98, 98)
            : widget.index % 2 == 0 ? theme.colorScheme.primaryContainer : theme.colorScheme.tertiaryContainer,
          onTap: () {
            if(widget.content.type == SongContentType.text) {
              showDialog(context: context, builder: (context) => EditTextNoteDialog(widget.content.file, widget.content.name));
            }
            else {
              appState.selectedContent = widget.content;
              appState.goToPage(4);
            }
          },
          trailing: Wrap(
            direction: Axis.horizontal,
            children: [
              // Set title note
              Visibility(
                visible: isHovering && widget.content.isDemo,
                child: IconButton(
                  onPressed: () {
                    showDialog(context: context, builder: (context) {
                      return StatefulBuilder(
                        builder: (stfContext, stfSetState) {
                          return AlertDialog(
                            title: Text('Set title note', style: AppStyles.mediumText),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            content: TextField(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: theme.colorScheme.secondaryContainer,
                                hintText: 'Enter title note here',
                              ),
                              controller: titleNoteController,
                              
                              onChanged: (value) => {
                                stfSetState(() {
                                  currentTitleNote = value;
                                })
                              },
                            ),
                            actions: [
                              // Confirm
                              TextButton(
                                onPressed: () {
                                  appState.selectedTrack.settings!.set('demoTitleNote', currentTitleNote);
                                  appState.selectedTrack.settings!.save();
                                  appState.selectedTrack.demoTitleNote = currentTitleNote.isEmpty ? 'Demo' : currentTitleNote;
                                  widget.updatePage();
                                  Navigator.pop(context);
                                },
                                child: const Text('Confirm'),
                              ),
                              // Cancel
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  stfSetState(() {
                                    currentTitleNote = '';
                                    titleNoteController.value = const TextEditingValue(text: '');
                                  });
                                },
                                child: const Text('Cancel'),
                              )
                            ],
                          );
                        }
                      );
                    });
                  },
                  icon: Icon(Icons.short_text, color: theme.colorScheme.secondaryContainer),
                  tooltip: 'Set title note',
                )
              ),
              // Set as final
              Visibility(
                visible: isHovering && widget.content.type == SongContentType.audio,
                child: IconButton(
                  onPressed: () {
                    if(!widget.content.isDemo) {
                      widget.content.isFinal = !widget.content.isFinal;
                      widget.content.track.hasFinal = !widget.content.track.hasFinal;
                      if(!widget.content.isFinal) {
                        widget.content.track.settings!.set('final', '');
                      }
                      else {
                        widget.content.track.settings!.set('final', path.basename(widget.content.file.path));
                      }
                      widget.content.track.settings!.save();

                      widget.updatePage();
                    }
                  },
                  icon: Icon(widget.content.isFinal ? Icons.star : Icons.star_border, color: theme.colorScheme.secondaryContainer),
                  tooltip: 'Set as final',
                )
              ),
              // Set as demo
              Visibility(
                visible: isHovering && widget.content.type == SongContentType.audio,
                child: IconButton(
                  onPressed: () {
                    if(!widget.content.isFinal) {
                      widget.content.isDemo = !widget.content.isDemo;
                      widget.content.track.hasDemo = !widget.content.track.hasDemo;
                      if(!widget.content.isDemo) {
                        widget.content.track.settings!.set('demo', '');
                      }
                      else {
                        widget.content.track.settings!.set('demo', path.basename(widget.content.file.path));
                      }
                      widget.content.track.settings!.set('demoTitleNote', '');
                      widget.content.track.settings!.save();

                      widget.updatePage();
                    }
                  },
                  icon: Icon(widget.content.isDemo ? Icons.check_circle : Icons.check_circle_outline, color: theme.colorScheme.secondaryContainer),
                  tooltip: 'Set as demo',
                )
              ),
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

                                  if(widget.content.isDemo) {
                                    appState.selectedTrack.settings!.set('demo', path.basename(newFile.path));
                                    appState.selectedTrack.settings!.save();
                                  }
                                  else if(widget.content.isFinal) {
                                    appState.selectedTrack.settings!.set('final', path.basename(newFile.path));
                                    appState.selectedTrack.settings!.save();
                                  }

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
                                  stfSetState(() {
                                    currentContentRename = widget.content.name;
                                    renameController.value = TextEditingValue(text: widget.content.name);
                                  });
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

class AddContentChooseFileTypeDialog extends StatefulWidget {
  const AddContentChooseFileTypeDialog({required this.updatePage, super.key});

  final Function updatePage;

  @override
  State<AddContentChooseFileTypeDialog> createState() => _AddContentChooseFileTypeDialogState();
}

class _AddContentChooseFileTypeDialogState extends State<AddContentChooseFileTypeDialog> {
  TextEditingController nameController = TextEditingController();
  String currentTextNoteName = '';

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
                      onPressed: () {
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
              ]
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        backgroundColor: theme.colorScheme.tertiaryContainer
                      ),
                      child: Icon(Icons.music_note, size: 100, color: theme.colorScheme.onPrimary)
                    ),
                  )
                ),
                 // Add text note
                Expanded(
                  child: Tooltip(
                    message: 'Add text note',
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(context: context, builder: (context) {
                          return StatefulBuilder(
                            builder: (stfContext, stfSetState) {
                              return AlertDialog(
                                title: Text('Create text note', style: AppStyles.mediumText),
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                content: TextField(
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: theme.colorScheme.secondaryContainer,
                                    hintText: 'Enter note name here',
                                  ),
                                  controller: nameController,
                                  
                                  onChanged: (value) => {
                                    stfSetState(() {
                                      currentTextNoteName = value;
                                    })
                                  },
                                ),
                                actions: [
                                  // Confirm
                                  TextButton(
                                    onPressed: () {
                                      if(['', 'lyrics', 'settings'].contains(currentTextNoteName)) return;
                                      File file = File(path.join(appState.selectedTrack.directory.path, '$currentTextNoteName.txt'));

                                      if(file.existsSync()) return;

                                      file.createSync();
                                      widget.updatePage();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                  // Cancel
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      stfSetState(() {
                                        currentTextNoteName = '';
                                        nameController.value = const TextEditingValue(text: '');
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  )
                                ],
                              );
                            }
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0)
                        ),
                        backgroundColor: theme.colorScheme.primaryContainer
                      ),
                      child: Icon(Icons.note_alt, size: 100, color: theme.colorScheme.onPrimary)
                    ),
                  )
                ),
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

    widget.updatePage();
  }
}

class EditTextNoteDialog extends StatefulWidget {
  const EditTextNoteDialog(this.file, this.title, {super.key});

  final File file;
  final String title;

  @override
  State<EditTextNoteDialog> createState() => _EditTextNoteDialogState();
}

class _EditTextNoteDialogState extends State<EditTextNoteDialog> {
  TextEditingController noteController = TextEditingController();
  String currentNoteText = '';
  
  @override
  void initState() {
    super.initState();
    if(!widget.file.existsSync()) {
      widget.file.createSync();
    }

    setState(() {
      currentNoteText = widget.file.readAsStringSync();
      noteController.value = TextEditingValue(text: currentNoteText);
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.primaryContainer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(widget.title, style: AppStyles.titleText)
              ),
              // Text field
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: SizedBox(
                  height: constraints.maxHeight - 135,
                  child: TextField(
                    autofocus: true,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.secondaryContainer,
                      hintText: path.basename(widget.file.path) == 'lyrics.txt' ? 'Write lyrics here' : 'Make notes here',
                    ),
                    controller: noteController,
                    
                    onChanged: (value) => {
                      setState(() {
                        currentNoteText = value;
                      })
                    },
                  ),
                ),
              ),
              // Cancel or confirm
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        }, 
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                        child: Text('Cancel', style: AppStyles.mediumTextSecondary)
                      )
                    ),
                    const SizedBox(width: 6.0),
                    // Confirm
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.file.writeAsStringSync(currentNoteText);
                          Navigator.pop(context);
                        }, 
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                        child: Text('Confirm', style: AppStyles.mediumTextSecondary)
                      )
                    )
                  ],
                ),
              )
            ],
          );
        }
      )
    );
  }
}