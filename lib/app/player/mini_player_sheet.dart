import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:tube_sync/app/player/expanded_player_sheet.dart';
import 'package:tube_sync/model/media.dart';
import 'package:tube_sync/model/playlist.dart';
import 'package:tube_sync/provider/player_provider.dart';

class MiniPlayerSheet extends StatelessWidget {
  const MiniPlayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: const Key("MiniPlayer"),
      confirmDismiss: (direction) {
        switch (direction) {
          case DismissDirection.startToEnd:
            context.read<PlayerProvider>().previousTrack();
            return Future.value(false);

          case DismissDirection.endToStart:
            context.read<PlayerProvider>().nextTrack();
            return Future.value(false);

          default:
            return Future.value(false);
        }
      },
      direction: DismissDirection.horizontal,
      background: const Row(
        children: [
          SizedBox(width: 18),
          Icon(Icons.skip_previous_rounded),
        ],
      ),
      secondaryBackground: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.skip_next_rounded),
          SizedBox(width: 18),
        ],
      ),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.2,
        DismissDirection.endToStart: 0.2,
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: context.read<PlayerProvider>().nowPlaying,
            builder: (context, media, child) => ListTile(
              onTap: () => openPlayerSheet(context),
              contentPadding: const EdgeInsets.only(left: 8, right: 4),
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: CachedNetworkImageProvider(
                  media.thumbnail.low,
                ),
              ),
              titleTextStyle: Theme.of(context).textTheme.bodyMedium,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    media.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    "${positionInPlaylist(context, media)} \u2022 ${playlistInfo(context)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              //Player Actions
              trailing: StreamBuilder(
                stream: player(context).playerStateStream,
                initialData: player(context).playerState,
                builder: actions,
              ),
            ),
          ),
          // Progress Indicator
          StreamBuilder<Duration>(
            stream: player(context).positionStream,
            initialData: player(context).position,
            builder: (context, snapshot) => LinearProgressIndicator(
              minHeight: 1,
              value: playerProgress(context, snapshot),
            ),
          )
        ],
      ),
    );
  }

  Widget actions(BuildContext context, AsyncSnapshot<PlayerState> snapshot) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (snapshot.requireData.playing)
          IconButton(
            onPressed: () => player(context).pause(),
            icon: const Icon(Icons.pause_rounded),
          )
        else ...{
          switch (snapshot.requireData.processingState) {
            ProcessingState.loading => SizedBox(),
            ProcessingState.buffering => CircularProgressIndicator(),
            _ => IconButton(
                onPressed: () => player(context).play(),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
          }
        },
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  void openPlayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (_) => Provider<PlayerProvider>.value(
        value: context.read<PlayerProvider>(),
        child: ExpandedPlayerSheet(),
      ),
    );
  }

  double? playerProgress(
    BuildContext context,
    AsyncSnapshot<Duration> snapshot,
  ) {
    switch (player(context).playerState.processingState) {
      case ProcessingState.buffering:
      case ProcessingState.loading:
        return null;

      default:
        break;
    }

    final vid = context.read<PlayerProvider>().nowPlaying.value;
    if (vid.durationMs == null) return null;
    return snapshot.requireData.inMilliseconds / vid.durationMs!;
  }

  String playlistInfo(BuildContext context) =>
      "${playlist(context).title} by ${playlist(context).author}";

  String positionInPlaylist(BuildContext context, Media media) {
    return "${videos(context).indexOf(media) + 1}/${playlist(context).videoCount}";
  }

  Playlist playlist(BuildContext context) =>
      context.read<PlayerProvider>().playlist.playlist;

  List<Media> videos(BuildContext context) =>
      context.read<PlayerProvider>().playlist.medias;

  AudioPlayer player(BuildContext context) =>
      context.read<PlayerProvider>().player;
}
