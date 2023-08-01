import 'package:amnesia_music_player/globals.dart';
import 'package:path/path.dart' as path;
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({required this.content, required this.updatePage, super.key});

  final List<Content> content;
  final Function() updatePage;

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  int playlistIndex = 0;
  late AudioPlayer player;

  Stream<PositionData> get positionDataStream =>
    Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      player.positionStream, 
      player.bufferedPositionStream, 
      player.durationStream, 
      (position, bufferedPosition, duration) => PositionData(
        position, 
        bufferedPosition, 
        duration ?? Duration.zero
      ),
    );

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    player.setAudioSource(ConcatenatingAudioSource(children: [
      for(Content content in widget.content)
        AudioSource.file(content.file.path)
    ]));
    player.play();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  // I should really dispose the player but whenever I do it crashes so I guess I'm just going to have to deal with this
  void _dispose() async {
    await player.pause();
  }
  
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState appState = context.watch<AppState>();

    const double iconSize = 60.0;
    File lyricsFile = File(path.join(appState.selectedContent.track.directory.path, 'lyrics.txt'));
    String lyrics = '';
    if(lyricsFile.existsSync()) lyrics = lyricsFile.readAsStringSync();

    // Previous and next button don't work half the time but oh well
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: IconButton(
                onPressed: () async {
                  await player.seekToPrevious();
                },
                iconSize: iconSize,
                color: theme.colorScheme.secondaryContainer,
                icon: const Icon(Icons.skip_previous)
              ),
            ),
            // Play or pause
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final player = playerState?.playing;

                if(!(player ?? false)) {
                  return IconButton(
                    onPressed: this.player.play,
                    iconSize: iconSize,
                    color: theme.colorScheme.secondaryContainer,
                    icon: const Icon(Icons.play_arrow)
                  );
                } else if(processingState != ProcessingState.completed) {
                  return IconButton(
                    onPressed:this.player.pause,
                    iconSize: iconSize,
                    color: theme.colorScheme.secondaryContainer,
                    icon: const Icon(Icons.pause)
                  );
                }
                return Icon(
                  Icons.play_arrow,
                  size: iconSize,
                  color: theme.colorScheme.secondaryContainer
                );
              },
            ),
            // Skip to next
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: IconButton(
                onPressed: () async {
                  await player.seekToNext();
                  await player.seek(Duration.zero);
                },
                iconSize: iconSize,
                color: playlistIndex == widget.content.length - 1 ? theme.colorScheme.tertiaryContainer : theme.colorScheme.secondaryContainer,
                icon: const Icon(Icons.skip_next)
              ),
            ),
          ],
        ),
        // Show lyrics
        Visibility(
          visible: lyrics.isNotEmpty,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                showDialog(context: context, builder: (context) {
                  return Dialog(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          children: [
                            // Title
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Text('${appState.selectedContent.track.name} - Lyrics', style:  AppStyles.largeText.copyWith(fontSize: 50)),
                            ),
                            // Lyrics
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: SizedBox(
                                width: constraints.maxWidth - 50,
                                height: constraints.maxHeight - 160,
                                child: SingleChildScrollView(
                                  child: Text(lyrics, style: AppStyles.largeText.copyWith(fontSize: 20))
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Close
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    }, 
                                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                                    child: Text('Close', style: AppStyles.mediumTextSecondary)
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      }
                    )
                  );
                });
              },
              iconSize: iconSize,
              color: theme.colorScheme.secondaryContainer,
              icon: const Icon(Icons.lyrics)
            ),
          )
        ),
        ElevatedButton.icon(
          onPressed: () {
            player.setLoopMode(LoopMode.values[(LoopMode.values.indexOf(player.loopMode) + 1) % LoopMode.values.length]);
            setState(() {});
          }, 
          icon: Icon(Icons.loop, color: theme.colorScheme.onSecondary),
          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
          label: Text(
            player.loopMode == LoopMode.one ? 'Loop One' 
            : player.loopMode == LoopMode.all ? 'Loop All' : 'Loop Off',
            style: AppStyles.largeTextSecondary,
          )
        ),
        const SizedBox(height: 10),
        StreamBuilder<PositionData>(
          stream: positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data;
            if(player.currentIndex != null && player.currentIndex != playlistIndex) {
              Future.delayed(Duration.zero, () {
                setState(() {
                  playlistIndex = player.currentIndex!;
                });
                appState.selectedContent = widget.content[playlistIndex];
                widget.updatePage();
              });
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ProgressBar(
                progress: positionData?.position ?? Duration.zero,
                buffered: positionData?.bufferedPosition ?? Duration.zero,
                total: positionData?.duration ?? Duration.zero,
                onSeek: player.seek,
            
                timeLabelTextStyle: AppStyles.largeText,
                thumbColor: theme.colorScheme.secondaryContainer,
                thumbGlowColor: Colors.transparent,
                baseBarColor: theme.colorScheme.primaryContainer,
                bufferedBarColor: theme.colorScheme.tertiaryContainer,
                progressBarColor: theme.colorScheme.secondaryContainer,
              ),
            );
          },
        )
      ],
    );
  }
}

class PositionData {
  const PositionData(this.position, this.bufferedPosition, this.duration);

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}