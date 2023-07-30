import 'package:amnesia_music_player/globals.dart';

class ContentPlayerPage extends StatefulWidget {
  const ContentPlayerPage({super.key});

  @override
  State<ContentPlayerPage> createState() => _ContentPlayerPageState();
}

class _ContentPlayerPageState extends State<ContentPlayerPage> {
  Player? videoPlayer;
  AudioPlayer? audioPlayer;

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();
    
    Widget bodyWidget;
    switch(appState.selectedContent.type) {
      case FileType.image:
        bodyWidget = Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(appState.selectedContent.file),
              alignment: Alignment.center,
              fit: BoxFit.contain
            ),
          ),
        );
        break;
      case FileType.video:
        videoPlayer = Player(id: 0);
        videoPlayer!.open(Media.file(appState.selectedContent.file));
        bodyWidget = Video(
          player: videoPlayer,
          showControls: true, 
        );
        break;
      case FileType.audio:
        audioPlayer = AudioPlayer();
        bodyWidget = Column(
          children: [
            //const Spacer(),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Image(image: appState.selectedCollection.icon, fit: BoxFit.fill),
                  )),
                  const SizedBox(height: 20),
                  Text((appState.selectedContent.track.settings!.get<bool>('workingTitle', false) ? '[${appState.selectedContent.track.name}]' : appState.selectedContent.track.name)
                    + (appState.selectedContent.isDemo ? ' (Demo)' : !appState.selectedContent.isFinal ? ' - ${appState.selectedContent.name}' : ''),
                    style: AppStyles.titleText
                  ),
                  Text('${appState.selectedContent.track.artistName} - ${appState.selectedContent.track.collection.name}', style: AppStyles.largeText.copyWith(fontSize: 20)),
                ],
              ),
            ),
            //const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: AudioPlayerWidget(player: audioPlayer!),
            ),
          ],
        );
        audioPlayer!.play(DeviceFileSource(appState.selectedContent.file.path));
        break;
      default:
        bodyWidget = Center(
          child: Text('You have not selected any song content.', style: AppStyles.largeText)
        );
        break;
    }

    return Scaffold(
      body: Center(
        child: Expanded(child: bodyWidget)
      )
    );
  }

  @override
  void dispose() {
    if(videoPlayer != null) {
      videoPlayer!.stop();
    }
    else if(audioPlayer != null) {
      audioPlayer!.stop();
    }
    super.dispose();
  }
}