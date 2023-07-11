import 'package:amnesia_music_player/packages/file_picker.dart';
import 'package:amnesia_music_player/packages/context_menus.dart';
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
    final theme = Theme.of(context);
  
    updateArtists();

    return ContextMenuOverlay(
      buttonStyle: AppStyles.contextMenuStyle,
      child: Scaffold(
        body: GridView.extent(
          maxCrossAxisExtent: 200.0,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          padding: const EdgeInsets.all(12.0),
          children: [
            for(MapEntry<String, ImageProvider> item in artists.entries)
              ContextMenuRegion(
                contextMenu: ArtistProfileContextMenu(item.key, updatePage: () {
                  updateArtists();
                }),
                child: ArtistProfile(item.key, item.value)
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(context: context, builder: (context) {
              return CreateArtistDialog(updatePage: () {
                updateArtists();
              });
            });
          },
          tooltip: 'Add Artist',
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: const Icon(Icons.add))
        ),
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

  const ArtistProfile(this.name, this.image, {super.key});

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
                fit: BoxFit.contain
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

class ArtistProfileContextMenu extends StatelessWidget {
  final String artistName;
  final Function() updatePage;

  const ArtistProfileContextMenu(this.artistName, {required this.updatePage, super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig('Edit', 
          onPressed: () {
            showDialog(context: context, builder: (context) {
              return CreateArtistDialog(updatePage: updatePage, artistName: artistName);
            });
          }
        ),
        ContextMenuButtonConfig('Delete', 
          onPressed: () async {
            Directory dir = Directory(path.join(Globals.appDataPath, '--$artistName--'));
            if(dir.existsSync()) {
              await showDialog(context: context, builder: (context) {
                return AlertDialog(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  content: Text('Are you sure want to delete?\nThis will delete all related songs and collections and cannot be undone.', textAlign: TextAlign.center, style: AppStyles.largeText),
                  actions: [
                    TextButton(
                      onPressed: () {
                        dir.deleteSync(recursive: true);
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
            updatePage();
          }
        ),
      ]
    );
  }
}

class CreateArtistDialog extends StatefulWidget {
  final Function() updatePage;
  final String artistName;

  const CreateArtistDialog({required this.updatePage, this.artistName = '', super.key});

  @override
  State<CreateArtistDialog> createState() => _CreateArtistDialogState();
}

class _CreateArtistDialogState extends State<CreateArtistDialog> {
  String currentIconFilePath = '-';
  String currentCreateArtistError = '';
  String currentArtistName = '';
  ImageProvider artistImage = const AssetImage('assets/images/default_artist_icon.png');

  TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isEditing = widget.artistName != '';
    if(isEditing) {
      nameController = TextEditingController(text: widget.artistName);
      setState(() {
        currentArtistName = widget.artistName;
        File icon = File(path.join(Globals.appDataPath, '--${widget.artistName}--', 'icon.png'));
        if(icon.existsSync()) { 
          artistImage = FileImage(icon);
        }
      });
    }

    return StatefulBuilder(builder: (stfContext, stfSetState) {
      return Dialog(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Column(
          children: [
            //Title
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Text(isEditing ? 'Edit Artist' : 'Add Artist', style: AppStyles.titleText),
            ),
            //Name text field
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.secondaryContainer,
                  hintText: 'Enter artist name here',
                ),
                controller: nameController,
                
                onChanged: (value) => {
                  stfSetState(() {
                    currentArtistName = value;
                  })
                },
              ),
            ),
            //Select icon
            Center(
              child: Column(
                children: [
                  Text(currentIconFilePath == '-' ? 'No path selected' : currentIconFilePath, style: AppStyles.largeText),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            dialogTitle: 'Select artist icon',
                            type: FileType.image
                          );
                          if(result != null) {
                            stfSetState(() {
                              currentIconFilePath = result.files.single.path!;
                              artistImage = FileImage(File(currentIconFilePath));
                            });
                          }
                        }, 
                        child: Text('Select Icon', style: AppStyles.mediumTextSecondary)
                      ),
                      const SizedBox(width: 7),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                        onPressed: () {
                          stfSetState(() {
                            currentIconFilePath = '-';
                            artistImage = const AssetImage('assets/images/default_artist_icon.png');
                          });
                        }, 
                        child: Text('Clear Icon', style: AppStyles.mediumTextSecondary)
                      ),
                    ],
                  )
                ],
              ),
            ),
            //Artist profile preview
            const Spacer(),
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: ArtistProfile(currentArtistName == '' ? 'Artist name here' : currentArtistName, artistImage)
              ),
            ),
            //Cancel or confirm
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Text(currentCreateArtistError, style: AppStyles.titleText.copyWith(color: const Color.fromARGB(255, 202, 13, 0), fontWeight: FontWeight.w700)),
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
                            if(currentArtistName == '') {
                              stfSetState(() {
                                currentCreateArtistError = 'You need to give the artist a name!';
                              });
                              return;
                            }

                            Directory dir = Directory(path.join(Globals.appDataPath, '--$currentArtistName--'));
                            Directory oldDir = Directory('');
                            if(isEditing) {
                              oldDir = Directory(path.join(Globals.appDataPath, '--${widget.artistName}--'));
                            }

                            if(dir.existsSync() && (!isEditing || (isEditing && currentArtistName != widget.artistName))) {
                              stfSetState(() {
                                currentCreateArtistError = 'There is already an artist of this name!';
                              });
                              return;
                            }
                            else if(!oldDir.existsSync() && isEditing) {
                              stfSetState(() {
                                currentCreateArtistError = 'Original artist not found!';
                              });
                              return;
                            }

                            if(isEditing) {
                              oldDir.renameSync(dir.path);
                              File iconFile = File(path.join(dir.path, 'icon.png'));
                              if(iconFile.existsSync()) {
                                iconFile.deleteSync();
                              }
                            }
                            else {
                              dir.createSync();
                            }

                            if(currentIconFilePath != '-') {
                              File(currentIconFilePath).copySync(path.join(dir.path, 'icon.png'));
                            }

                            Directory(path.join(dir.path, 'songs')).createSync();
                            Directory(path.join(dir.path, 'collections')).createSync();

                            widget.updatePage();
                            Navigator.pop(context);
                          }, 
                          child: Text('Confirm', style: AppStyles.mediumTextSecondary)
                        ),
                      )
                    ],
                  )
                ],
              )
            )
          ]
        ),
      );
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}