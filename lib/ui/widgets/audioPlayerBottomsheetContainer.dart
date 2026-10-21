import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:eschool_saas_staff/data/models/studyMaterial.dart';
import 'package:eschool_saas_staff/ui/widgets/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/customRoundedButton.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

/// Streams an audio attachment (e.g. a student's assignment submission)
/// inside the app.
///
/// Pops with `true` when the user asks to download the file instead.
class AudioPlayerBottomsheetContainer extends StatefulWidget {
  final StudyMaterial studyMaterial;

  const AudioPlayerBottomsheetContainer({
    super.key,
    required this.studyMaterial,
  });

  /// Formats a playback position as `m:ss`, or `h:mm:ss` from one hour on.
  static String formatPlaybackTime(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours;
    final minutes = safeDuration.inMinutes.remainder(60);
    final seconds =
        safeDuration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return "$hours:${minutes.toString().padLeft(2, '0')}:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  State<AudioPlayerBottomsheetContainer> createState() =>
      _AudioPlayerBottomsheetContainerState();
}

class _AudioPlayerBottomsheetContainerState
    extends State<AudioPlayerBottomsheetContainer> with WidgetsBindingObserver {
  static const Duration _seekStep = Duration(seconds: 10);

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;

  bool _hasError = false;

  //While the user drags the slider we show the drag position instead of the
  //player position, so the thumb doesn't jump back until the seek completes
  double? _draggedPositionInMilliseconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    //just_audio 0.9.x reports playback errors (e.g. a dropped connection)
    //through the playback event stream
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object _, StackTrace __) => _showError(),
    );
    _loadAudio();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //There is no media notification to control playback from outside the
    //app, so don't keep playing once the app is backgrounded
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _audioPlayer.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playbackEventSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAudio() async {
    try {
      //Speech playback keeps playing when the iOS silent switch is on
      final audioSession = await AudioSession.instance;
      await audioSession.configure(const AudioSessionConfiguration.speech());
    } catch (_) {
      //Playback still works with the default session
    }

    try {
      await _audioPlayer.setUrl(widget.studyMaterial.fileUrl);
      if (!mounted) return;
      unawaited(_audioPlayer.play());
    } on PlayerInterruptedException {
      //Loading was cut short because the sheet was closed
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    if (!mounted || _hasError) return;
    setState(() {
      _hasError = true;
    });
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _draggedPositionInMilliseconds = null;
    });
    _loadAudio();
  }

  void _togglePlayback(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.completed) {
      //The player stays in playing mode after completing, so seeking back to
      //the start is enough to play it again
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
      return;
    }

    if (playerState.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _seekBy(Duration offset) {
    final duration = _audioPlayer.duration;
    if (duration == null) return;

    var position = _audioPlayer.position + offset;
    if (position < Duration.zero) {
      position = Duration.zero;
    } else if (position > duration) {
      position = duration;
    }
    _audioPlayer.seek(position);
  }

  Widget _buildDownloadButton() {
    return IconButton(
      tooltip: Utils.getTranslatedLabel(downloadKey),
      onPressed: () => Get.back(result: true),
      icon: Icon(
        Icons.download_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildFileNameContainer() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.audiotrack_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomTextContainer(
            textKey: widget.studyMaterial.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final timeTextStyle = TextStyle(
      fontSize: 12.0,
      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.76),
    );

    return StreamBuilder<Duration?>(
      stream: _audioPlayer.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        final durationInMilliseconds = duration.inMilliseconds.toDouble();
        final canSeek = durationInMilliseconds > 0;

        return StreamBuilder<Duration>(
          stream: _audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            final positionInMilliseconds = (_draggedPositionInMilliseconds ??
                    (positionSnapshot.data ?? Duration.zero)
                        .inMilliseconds
                        .toDouble())
                .clamp(0.0, durationInMilliseconds);
            final bufferedInMilliseconds = _audioPlayer
                .bufferedPosition.inMilliseconds
                .toDouble()
                .clamp(0.0, durationInMilliseconds);

            return Column(
              children: [
                SliderTheme(
                  data: Theme.of(context).sliderTheme.copyWith(
                        trackHeight: 4.0,
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14.0),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                      ),
                  child: Slider(
                    value: positionInMilliseconds,
                    secondaryTrackValue: bufferedInMilliseconds,
                    max: durationInMilliseconds,
                    activeColor: Theme.of(context).colorScheme.primary,
                    secondaryActiveColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    inactiveColor: Theme.of(context).colorScheme.tertiary,
                    onChanged: canSeek
                        ? (value) {
                            setState(() {
                              _draggedPositionInMilliseconds = value;
                            });
                          }
                        : null,
                    onChangeEnd: canSeek
                        ? (value) async {
                            await _audioPlayer.seek(
                              Duration(milliseconds: value.round()),
                            );
                            if (mounted) {
                              setState(() {
                                _draggedPositionInMilliseconds = null;
                              });
                            }
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Text(
                        AudioPlayerBottomsheetContainer.formatPlaybackTime(
                          Duration(
                            milliseconds: positionInMilliseconds.round(),
                          ),
                        ),
                        style: timeTextStyle,
                      ),
                      const Spacer(),
                      Text(
                        AudioPlayerBottomsheetContainer.formatPlaybackTime(
                          duration,
                        ),
                        style: timeTextStyle,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSeekButton({required IconData icon, required Duration offset}) {
    return IconButton(
      onPressed: () => _seekBy(offset),
      iconSize: 30,
      color: Theme.of(context).colorScheme.secondary,
      icon: Icon(icon),
    );
  }

  Widget _buildPlaybackControls() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data ?? _audioPlayer.playerState;
        final processingState = playerState.processingState;
        final isLoading = processingState == ProcessingState.idle ||
            processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering;
        final isCompleted = processingState == ProcessingState.completed;

        final IconData playPauseIcon;
        if (isCompleted) {
          playPauseIcon = Icons.replay_rounded;
        } else if (playerState.playing) {
          playPauseIcon = Icons.pause_rounded;
        } else {
          playPauseIcon = Icons.play_arrow_rounded;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSeekButton(
              icon: Icons.replay_10_rounded,
              offset: -_seekStep,
            ),
            const SizedBox(width: 20),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: isLoading ? null : () => _togglePlayback(playerState),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                    : Icon(
                        playPauseIcon,
                        size: 34,
                        color: Theme.of(context).colorScheme.surface,
                      ),
              ),
            ),
            const SizedBox(width: 20),
            _buildSeekButton(
              icon: Icons.forward_10_rounded,
              offset: _seekStep,
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorContainer() {
    return Column(
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 40,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 10),
        CustomTextContainer(
          textKey: unableToPlayAudioKey,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14.0),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomRoundedButton(
                widthPercentage: 0.4,
                height: 45,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                showBorder: true,
                borderColor: Theme.of(context).colorScheme.primary,
                titleColor: Theme.of(context).colorScheme.primary,
                textSize: 15,
                buttonTitle: retryKey,
                onTap: _retry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomRoundedButton(
                widthPercentage: 0.4,
                height: 45,
                backgroundColor: Theme.of(context).colorScheme.primary,
                titleColor: Theme.of(context).scaffoldBackgroundColor,
                showBorder: false,
                textSize: 15,
                buttonTitle: downloadKey,
                onTap: () => Get.back(result: true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
      titleLabelKey: audioPlayerKey,
      trailing: _buildDownloadButton(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: appContentHorizontalPadding,
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFileNameContainer(),
            const SizedBox(height: 20),
            if (_hasError)
              _buildErrorContainer()
            else ...[
              _buildProgressBar(),
              const SizedBox(height: 10),
              _buildPlaybackControls(),
            ],
          ],
        ),
      ),
    );
  }
}
