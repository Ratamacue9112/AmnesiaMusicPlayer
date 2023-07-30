import 'package:amnesia_music_player/globals.dart';
import 'package:path/path.dart' as path;

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  List<Collection> collections = [];

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();
    ImageProvider artistIcon;
    ThemeData theme = Theme.of(context);

    if(appState.selectedArtist == '') {
      return Scaffold(
        body: Center(
          child: Text('You have not selected an artist.', style: AppStyles.largeText)
        ),
      );
    }

    updateCollections(appState.selectedArtist);

    File artistIconFile = File(path.join(Globals.appDataPath, appState.selectedArtist, 'icon.png'));
    if(artistIconFile.existsSync()) {
      artistIcon = FileImage(artistIconFile);
    }
    else {
      artistIcon = const AssetImage('assets/images/default_artist_icon.png');
    }

    Widget bodyWidget;
    if(collections.isEmpty) {
      bodyWidget = Column(
        children: [
          const Spacer(),
          Center(
            child: Text('${appState.selectedArtist} has no collections.', style: AppStyles.largeText)
          ),
          const Spacer()
        ]
      );
    }
    else {
      bodyWidget = GridView.extent(
        maxCrossAxisExtent: 300.0,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        padding: const EdgeInsets.all(12.0),
        children: [
          for(Collection collection in collections)
            ContextMenuRegion(
              enableLongPress: false,
              isEnabled: collection.name != 'Uncategorized',
              contextMenu: CollectionProfileContextMenu(collection.name, appState: context.watch<AppState>(), updatePage: () {
                updateCollections(appState.selectedArtist);
              }),
              child: GestureDetector(
                onTap: () {
                  appState.selectedCollection = collection;
                  appState.goToPage(2);
                },
                child: CollectionProfile(collection.name, collection.icon)
              )
            )
        ],
      );
    }

    return ContextMenuOverlay(
      buttonStyle: AppStyles.contextMenuStyle,
      child: Scaffold(
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
            Expanded(child: bodyWidget)
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(context: context, builder: (context) {
              return CreateCollectionDialog(updatePage: () {
                updateCollections(appState.selectedArtist);
              });
            });
          },
          tooltip: 'Add Collection',
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: const Icon(Icons.add)
        )
      ),
    );
  }

  void updateCollections(String selectedArtist) {
    List<Collection> newCollections = [];
    bool foundUncategorized = false;

    for(FileSystemEntity item in Directory(path.join(Globals.appDataPath, selectedArtist, 'collections')).listSync()) {
      if(item is Directory) {
        String collectionName = path.basename(item.path);
        if(collectionName == 'Uncategorized') {
          foundUncategorized = true;
        }
        File imageFile = File(path.join(item.path, 'icon.png'));
        ImageProvider image;
        if(imageFile.existsSync()) {
          image = FileImage(imageFile);
        }
        else {
          if(collectionName == 'Uncategorized') {
            image = const AssetImage('assets/images/uncategorized_collection_icon.png');
          }
          else {
            image = const AssetImage('assets/images/default_collection_icon.png');
          }
        }

        newCollections.add(Collection(collectionName, selectedArtist, image, imageFile.parent));
      }
    }

    if(!foundUncategorized) {
      Directory uncategorizedDirectory = Directory(path.join(Globals.appDataPath, selectedArtist, 'collections', 'Uncategorized'));
      uncategorizedDirectory.createSync();

      newCollections.add(Collection('Uncategorized', selectedArtist, const AssetImage('assets/images/uncategorized_collection_icon.png'), uncategorizedDirectory));
    }

    setState(() {
      collections = newCollections;
    });
  }
}

class CollectionProfile extends StatelessWidget {
  final ImageProvider image;
  final String name;
  final bool interactable;

  const CollectionProfile(this.name, this.image, {this.interactable = true, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(name, style: AppStyles.largeText, textAlign: TextAlign.center), 
        ]
      ),
    );
}
}

class CollectionProfileContextMenu extends StatelessWidget {
  final String collectionName;
  final AppState appState;
  final Function() updatePage;

  const CollectionProfileContextMenu(this.collectionName, {required this.updatePage, required this.appState, super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState appState = context.watch<AppState>();

    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig('Edit', 
          onPressed: () {
            showDialog(context: context, builder: (context) {
              return CreateCollectionDialog(updatePage: updatePage, collectionName: collectionName);
            });
          }
        ),
        ContextMenuButtonConfig('Delete', 
          onPressed: () async {
            Directory dir = Directory(path.join(Globals.appDataPath, appState.selectedArtist, 'collections', collectionName));
            if(dir.existsSync()) {
              await showDialog(context: context, builder: (context) {
                return AlertDialog(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  content: Text('Are you sure want to delete?\nThis cannot be undone.', textAlign: TextAlign.center, style: AppStyles.largeText),
                  actions: [
                    TextButton(
                      onPressed: () {
                        dir.deleteSync(recursive: true);
                        if(collectionName == appState.selectedCollection.name) {
                          appState.selectedCollection = Collection.empty;
                        }
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

class CreateCollectionDialog extends StatefulWidget {
  final Function() updatePage;
  final String collectionName;

  const CreateCollectionDialog({required this.updatePage, this.collectionName = '', super.key});

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  String currentIconFilePath = '-';
  String currentCreateCollectionError = '';
  String currentCollectionName = '';
  ImageProvider collectionImage = const AssetImage('assets/images/default_collection_icon.png');

  TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();

    final theme = Theme.of(context);
    bool isEditing = widget.collectionName != '';
    if(isEditing) {
      nameController = TextEditingController(text: widget.collectionName);
      setState(() {
        currentCollectionName = widget.collectionName;
        File icon = File(path.join(Globals.appDataPath, appState.selectedArtist, 'collections', widget.collectionName, 'icon.png'));
        if(icon.existsSync()) { 
          collectionImage = FileImage(icon);
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
              child: Text(isEditing ? 'Edit Collection' : 'Add Collection', style: AppStyles.titleText),
            ),
            //Name text field
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.secondaryContainer,
                  hintText: 'Enter collection name here',
                ),
                controller: nameController,
                
                onChanged: (value) => {
                  stfSetState(() {
                    currentCollectionName = value;
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
                            dialogTitle: 'Select collection icon',
                            type: FileType.image
                          );
                          if(result != null) {
                            stfSetState(() {
                              currentIconFilePath = result.files.single.path!;
                              collectionImage = FileImage(File(currentIconFilePath));
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
                            collectionImage = const AssetImage('assets/images/default_collection_icon.png');
                          });
                        }, 
                        child: Text('Clear Icon', style: AppStyles.mediumTextSecondary)
                      ),
                    ],
                  )
                ],
              ),
            ),
            //Collection profile preview
            const Spacer(),
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CollectionProfile(
                  currentCollectionName == '' ? 'Collection name here' : currentCollectionName, 
                  collectionImage, 
                  interactable: false
                )
              ),
            ),
            //Cancel or confirm
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Text(currentCreateCollectionError, style: AppStyles.titleText.copyWith(color: const Color.fromARGB(255, 202, 13, 0), fontWeight: FontWeight.w700)),
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
                            if(currentCollectionName == '') {
                              stfSetState(() {
                                currentCreateCollectionError = 'You need to give the collection a name!';
                              });
                              return;
                            }

                            Directory dir = Directory(path.join(Globals.appDataPath, appState.selectedArtist, 'collections', currentCollectionName));
                            Directory oldDir = Directory('');
                            if(isEditing) {
                              oldDir = Directory(path.join(Globals.appDataPath, appState.selectedArtist, 'collections', widget.collectionName));
                            }

                            if(dir.existsSync() && (!isEditing || (isEditing && currentCollectionName != widget.collectionName))) {
                              stfSetState(() {
                                currentCreateCollectionError = 'There is already an collection of this name!';
                              });
                              return;
                            }
                            else if(!oldDir.existsSync() && isEditing) {
                              stfSetState(() {
                                currentCreateCollectionError = 'Original collection not found!';
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

                            File(path.join(dir.path, 'tracklist.txt')).createSync();

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