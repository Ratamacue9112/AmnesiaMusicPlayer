import 'package:amnesia_music_player/globals.dart';

class ContentPlayerPage extends StatefulWidget {
  const ContentPlayerPage({super.key});

  @override
  State<ContentPlayerPage> createState() => _ContentPlayerPageState();
}

class _ContentPlayerPageState extends State<ContentPlayerPage> {
  Player? videoPlayer;

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();
    
    Widget bodyWidget;
    switch(appState.selectedContent.type) {
      case SongContentType.image:
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
      case SongContentType.video:
        videoPlayer = Player(id: 0);
        videoPlayer!.open(Media.file(appState.selectedContent.file));
        bodyWidget = Video(
          player: videoPlayer,
          showControls: true, 
        );
        break;
      case SongContentType.audio:
        bodyWidget = Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Image(image: appState.selectedContent.track.collection.icon, fit: BoxFit.fill),
                  )),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: appState.selectedContent.track.settings!.get<bool>('workingTitle', false) ? '[${appState.selectedContent.track.name}]' : appState.selectedContent.track.name, style: AppStyles.titleText),
                        TextSpan(text: appState.selectedContent.isDemo ? ' (Demo)' : !appState.selectedContent.isFinal ? ' - ${appState.selectedContent.name}' : '', style: AppStyles.titleText.copyWith(fontWeight: FontWeight.w200)),
                      ],
                    )
                  ),
                  Text('${appState.selectedContent.track.artistName} - ${appState.selectedContent.track.collection.name}', style: AppStyles.largeText.copyWith(fontSize: 20)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: AudioPlayerWidget(
                content: appState.currentContentQueue == null ? [appState.selectedContent] : appState.currentContentQueue!,
                updatePage: () => setState(() {}),
              ),
            ),
          ],
        );
        break;
      default:
        bodyWidget = Center(
          child: Text('You have not selected any song content.', style: AppStyles.largeText)
        );
        break;
    }

    return Scaffold(
      body: Center(
        child: bodyWidget
      )
    );
  }

  @override
  void dispose() {
    if(videoPlayer != null) {
      videoPlayer!.dispose();
    }

    super.dispose();
  }
}