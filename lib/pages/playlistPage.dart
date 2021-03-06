import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';
import '../widgets/playlistPageW.dart' as playlistPageW;
import '../globalVars.dart' as globalVars;
import '../globalFun.dart' as globalFun;
import '../globalWids.dart' as globalWids;
import '../audioServiceGlobalFun.dart' as audioServiceGlobalFun;

MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_action_play_arrow',
  label: 'Play',
  action: MediaAction.play,
);
MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_action_pause',
  label: 'Pause',
  action: MediaAction.pause,
);
MediaControl skipToNextControl = MediaControl(
  androidIcon: 'drawable/ic_action_skip_next',
  label: 'Next',
  action: MediaAction.skipToNext,
);
MediaControl skipToPreviousControl = MediaControl(
  androidIcon: 'drawable/ic_action_skip_previous',
  label: 'Previous',
  action: MediaAction.skipToPrevious,
);
MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/ic_action_stop',
  label: 'Stop',
  action: MediaAction.stop,
);

class PlaylistPage extends StatefulWidget {
  String playlistName, playlistId, playlistThumbnail;
  PlaylistPage(this.playlistName, this.playlistId, this.playlistThumbnail);

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final GlobalKey<ScaffoldState> _playlistsPageScaffoldKey =
      new GlobalKey<ScaffoldState>();
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);

  // holds the flag to mark the page as loading or loaded
  bool _isLoading = true, _noInternet = false;
  // holds the response data from playlist songs request
  var dataResponse;

  // function that calls the bottomSheet
  void settingModalBottomSheet(context) async {
    if (AudioService.currentMediaItem != null) {
      // bottomSheet definition
      showModalBottomSheet(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
            topLeft: Radius.circular(globalVars.borderRadius),
            topRight: Radius.circular(globalVars.borderRadius),
          )),
          context: context,
          elevation: 10.0,
          builder: (BuildContext bc) {
            return globalWids.bottomSheet(context, _dragPositionSubject);
          });
    }
  }

  // gets all the music in the playlist
  void getPlaylistContents() async {
    setState(() {
      _isLoading = true;
      _noInternet = false;
    });
    try {
      var response = await http.get(
          "https://api.openbeats.live/playlist/userplaylist/getplaylist/" +
              widget.playlistId);
      dataResponse = json.decode(response.body);
      if (dataResponse["status"] == true) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (err) {
      setState(() {
        _noInternet = true;
      });
      print(err);
      globalFun.showToastMessage(
          "Not able to connect to server", Colors.red, Colors.white, false);
    }
    setState(() {
      _isLoading = false;
    });
  }

  // shows the delete playlists confirmation dialog
  void showRemoveSongConfirmationBox(int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              backgroundColor: globalVars.primaryDark,
              title: Text("Are you sure?"),
              content:
                  Text("This action will remove the song from this playlist"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(globalVars.borderRadius)),
              actions: <Widget>[
                FlatButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  color: Colors.transparent,
                  textColor: globalVars.accentGreen,
                ),
                FlatButton(
                  child: Text("Remove Song"),
                  onPressed: () {
                    removeSongFromPlaylist(index);
                    Navigator.pop(context);
                  },
                  color: Colors.transparent,
                  textColor: globalVars.accentRed,
                ),
              ],
            ));
  }

  void removeSongFromPlaylist(index) async {
    setState(() {
      _isLoading = true;
      _noInternet = false;
    });
    try {
      var response = await http.post(
          "https://api.openbeats.live/playlist/userplaylist/deletesong",
          body: {
            "playlistId": widget.playlistId,
            "songId": dataResponse["data"]["songs"][index]["_id"],
          });
      dataResponse = json.decode(response.body);
      if (dataResponse["status"] == true) {
        getPlaylistContents();
      } else {
        globalFun.showToastMessage(
            "Response error from server", Colors.red, Colors.white, false);
      }
    } catch (err) {
      setState(() {
        _noInternet = true;
      });
      print(err);
      globalFun.showToastMessage(
          "Not able to connect to server", Colors.red, Colors.white, false);
    }
  }

  Future startAudioService() async {
    print("REached");
    await AudioService.start(
      backgroundTaskEntrypoint: _audioPlayerTaskEntrypoint,
      resumeOnClick: true,
      androidStopOnRemoveTask: true,
      androidNotificationChannelName: 'OpenBeats Notification Channel',
      notificationColor: 0xFF000000,
      enableQueue: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_stat_logoicon2',
    );
  }

  // function to start selected music and add the rest to playlist
  // index is the index of the clicked item
  Future startPlaylistFromMusic(index) async {
    setState(() {
      // setting the page that is handling the audio service
      globalVars.audioServicePage = "playlist";
    });
    if (AudioService.playbackState != null) {
      await AudioService.stop();
      Timer(Duration(milliseconds: 500), () async {
        await startAudioService();
        var parameters = {
          "currIndex": index,
          "allSongs": dataResponse["data"]["songs"]
        };
        await AudioService.customAction(
            "startMusicPlaybackAndCreateQueue", parameters);
      });
    } else {
      await startAudioService();
      var parameters = {
        "currIndex": index,
        "allSongs": dataResponse["data"]["songs"]
      };
      await AudioService.customAction(
          "startMusicPlaybackAndCreateQueue", parameters);
    }
  }

  void connect() async {
    await AudioService.connect();
  }

  void disconnect() {
    AudioService.disconnect();
  }

  @override
  void initState() {
    super.initState();
    connect();
    getPlaylistContents();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _playlistsPageScaffoldKey,
        floatingActionButton: globalWids.fabView(
            settingModalBottomSheet, _playlistsPageScaffoldKey),
        backgroundColor: globalVars.primaryDark,
        body: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowGlow();
          },
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                playlistPageW.appBarW(context, _playlistsPageScaffoldKey,
                    widget.playlistName, widget.playlistThumbnail),
              ];
            },
            body: Container(
                child: (_noInternet)
                    ? globalWids.noInternetView(getPlaylistContents)
                    : (_isLoading)
                        ? playlistPageW.playlistsLoading()
                        : (dataResponse != null &&
                                dataResponse["data"]["songs"].length != 0)
                            ? playlistPageBody()
                            : playlistPageW.noSongsMessage()),
          ),
        ),
      ),
    );
  }

  Widget playlistPageBody() {
    return ListView(
      physics: ClampingScrollPhysics(),
      children: <Widget>[
        SizedBox(
          height: 20.0,
        ),
        playAllButtons(),
        SizedBox(
          height: 30.0,
        ),
        playlistPageListViewBody(),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.1,
        ),
      ],
    );
  }

  Widget playlistPageListViewBody() {
    return ListView.builder(
      physics: ClampingScrollPhysics(),
      shrinkWrap: true,
      itemCount: dataResponse["data"]["songs"].length,
      itemBuilder: (context, index) {
        return globalWids.playlistPageVidResultContainerW(
            context,
            dataResponse["data"]["songs"][index],
            index,
            startPlaylistFromMusic,
            showRemoveSongConfirmationBox);
      },
    );
  }

  Widget playAllButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        playAllBtnsW(1),
        playAllBtnsW(2),
      ],
    );
  }

  // mode : 1 - shuffleAll , 2 - addToQueue
  Widget playAllBtnsW(mode) {
    return Container(
      // margin: EdgeInsets.symmetric(horizontal: 10.0),
      width: MediaQuery.of(context).size.width * 0.4,
      child: OutlineButton(
        borderSide: BorderSide(
            color: (mode == 1) ? globalVars.accentGreen : globalVars.accentBlue,
            width: 2.0),
        onPressed: () async {
          try {
            final result = await InternetAddress.lookup('example.com');
            if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
              if (mode == 1) {
                if (AudioService.playbackState != null) {
                  await AudioService.stop();
                  Timer(Duration(milliseconds: 500), () async {
                    await startAudioService();
                    // calling method to add songs to the background list
                    await AudioService.customAction(
                        "addSongsToList", dataResponse["data"]["songs"]);
                  });
                } else {
                  await startAudioService();
                  // calling method to add songs to the background list
                  await AudioService.customAction(
                      "addSongsToList", dataResponse["data"]["songs"]);
                }
              } else {
                // showing Toast
                globalFun.showToastMessage(
                    "Adding Songs to queue...", Colors.orange, Colors.white, false);
                if ((AudioService.playbackState != null) &&
                    (AudioService.playbackState.basicState ==
                            BasicPlaybackState.stopped ||
                        AudioService.playbackState.basicState ==
                            BasicPlaybackState.none)) {
                  await startAudioService();
                  // calling method to add songs to the background list
                  await AudioService.customAction(
                      "addSongListToQueue", dataResponse["data"]["songs"]);
                } else {
                  // calling method to add songs to the background list
                  await AudioService.customAction(
                      "addSongListToQueue", dataResponse["data"]["songs"]);
                }
              }
            }
          } on SocketException catch (_) {
            globalFun.showNoInternetToast();
          }
        },
        padding: EdgeInsets.all(10.0),
        shape: StadiumBorder(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (mode == 1)
                ? Icon(
                    Icons.shuffle,
                    size: 25.0,
                  )
                : Icon(
                    Icons.queue,
                    size: 25.0,
                  ),
            SizedBox(width: 10.0),
            (mode == 1)
                ? Text(
                    "SHUFFLE ALL",
                  )
                : Text(
                    "ADD TO QUEUE",
                  )
          ],
        ),
        textColor: globalVars.accentWhite,
      ),
    );
  }
}

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class AudioPlayerTask extends BackgroundAudioTask {
  final _queue = <MediaItem>[];
  // holds one attribute of the contents of MediaItems in _queue
  var _queueMeta = <String>[];
  int _queueIndex = -1;
  AudioPlayer _audioPlayer = new AudioPlayer();
  Completer _completer = Completer();
  BasicPlaybackState _skipState;
  bool _playing;
  bool _isPaused = true;

  bool get hasNext => _queueIndex + 1 < _queue.length;

  bool get hasPrevious => _queueIndex > 0;

  MediaItem get mediaItem => _queue[_queueIndex];

  BasicPlaybackState _stateToBasicState(AudioPlaybackState state) {
    switch (state) {
      case AudioPlaybackState.none:
        return BasicPlaybackState.none;
      case AudioPlaybackState.stopped:
        return BasicPlaybackState.stopped;
      case AudioPlaybackState.paused:
        return BasicPlaybackState.paused;
      case AudioPlaybackState.playing:
        return BasicPlaybackState.playing;
      case AudioPlaybackState.buffering:
        return BasicPlaybackState.buffering;
      case AudioPlaybackState.connecting:
        return _skipState ?? BasicPlaybackState.connecting;
      case AudioPlaybackState.completed:
        return BasicPlaybackState.stopped;
      default:
        throw Exception("Illegal state");
    }
  }

  @override
  Future<void> onStart() async {
    var playerStateSubscription = _audioPlayer.playbackStateStream
        .where((state) => state == AudioPlaybackState.completed)
        .listen((state) {
      _handlePlaybackCompleted();
    });
    var eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      final state = _stateToBasicState(event.state);
      if (state != BasicPlaybackState.stopped) {
        _setState(
          state: state,
          position: event.position.inMilliseconds,
        );
      }
    });

    // AudioServiceBackground.setQueue(_queue);
    // await onSkipToNext();
    await _completer.future;
    playerStateSubscription.cancel();
    eventSubscription.cancel();
  }

  @override
  void onSeekTo(int position) {
    _audioPlayer.seek(Duration(milliseconds: position));
  }

  @override
  void onClick(MediaButton button) {
    playPause();
  }

  @override
  void onStop() {
    _audioPlayer.stop();
    _setState(state: BasicPlaybackState.stopped);
    _completer.complete();
  }

  void _handlePlaybackCompleted() {
    if (hasNext) {
      onSkipToNext();
    } else {
      _queueIndex = -1;
      onSkipToNext();
      // onStop();
    }
  }

  void playPause() {
    if (AudioServiceBackground.state.basicState == BasicPlaybackState.playing)
      onPause();
    else
      onPlay();
  }

  @override
  Future<void> onSkipToNext() => _skip(1);

  @override
  Future<void> onSkipToPrevious() => _skip(-1);

  Future<void> _skip(int offset) async {
    if (_queueIndex == (_queue.length - 1) && offset == 1) {
      _queueIndex = -1;
    } else if (_queueIndex == 0 && offset == -1) {
      _queueIndex = _queue.length;
    }
    final newPos = _queueIndex + offset;
    if (!(newPos >= 0 && newPos < _queue.length)) return;
    if (_playing == null) {
      // First time, we want to start playing
      _playing = true;
    } else if (_playing) {
      // Stop current item
      await _audioPlayer.stop();
    }
    // Load next item
    _queueIndex = newPos;
    AudioServiceBackground.setMediaItem(mediaItem);
    _skipState = offset > 0
        ? BasicPlaybackState.skippingToNext
        : BasicPlaybackState.skippingToPrevious;
    await _audioPlayer.setUrl(mediaItem.id);
    _skipState = null;
    // Resume playback if we were playing
    if (_playing) {
      onPlay();
    } else {
      _setState(state: BasicPlaybackState.paused);
    }
  }

  @override
  void onPlay() {
    if (_skipState == null) {
      _playing = true;
      _isPaused = false;
      _audioPlayer.play();
    }
  }

  @override
  void onPause() {
    if (_skipState == null) {
      _playing = false;
      _isPaused = true;
      _audioPlayer.pause();
    }
  }

  void onPauseAudioFocus() {
    if (_skipState == null) {
      _playing = false;
      _audioPlayer.pause();
    }
  }

  @override
  void onAudioFocusLost() async {
    onPauseAudioFocus();
  }

  @override
  void onAudioBecomingNoisy() {
    onPauseAudioFocus();
  }

  @override
  void onAudioFocusLostTransient() async {
    onPauseAudioFocus();
  }

  @override
  void onAudioFocusLostTransientCanDuck() async {
    _audioPlayer.setVolume(0);
  }

  @override
  void onAudioFocusGained() async {
    _audioPlayer.setVolume(1.0);
    if (!_isPaused) onPlay();
  }

  List<MediaControl> getControls(BasicPlaybackState state) {
    if (_queue.length == 1) {
      if (_playing != null && _playing) {
        return [
          pauseControl,
          stopControl,
        ];
      } else {
        return [
          playControl,
          stopControl,
        ];
      }
    } else {
      if (_playing != null && _playing) {
        return [
          skipToPreviousControl,
          pauseControl,
          skipToNextControl,
          stopControl,
        ];
      } else {
        return [
          skipToPreviousControl,
          playControl,
          skipToNextControl,
          stopControl,
        ];
      }
    }
  }

  @override
  void onCustomAction(String action, var parameters) async {
    // if condition to add all songs to the list and start playback
    if (action == "addSongsToList") {
      var state = BasicPlaybackState.connecting;
      var position = 0;
      AudioServiceBackground.setState(
          controls: getControls(state), basicState: state, position: position);
      audioServiceGlobalFun.addSongsToList(parameters, getMp3URL);
    } else if (action == "startMusicPlaybackAndCreateQueue") {
      var state = BasicPlaybackState.connecting;
      var position = 0;
      AudioServiceBackground.setState(
          controls: getControls(state), basicState: state, position: position);
      startMusicPlaybackAndCreateQueue(parameters);
    } else if (action == "addItemToQueue") {
      addItemToQueue(parameters);
    } else if (action == "removeItemFromQueue") {
      removeItemFromQueue(parameters);
    } else if (action == "updateQueueOrder") {
      updateQueryOrder(parameters);
    } else if (action == "addItemToQueueFront") {
      // false cause this is not repeating single song
      // last parameter is if the song should be make now playing in queue
      getMp3URLToQueue(parameters["song"], true);
    } else if (action == "addSongListToQueue") {
      addSongListToQueue(parameters);
    } else if (action == "jumpToQueueItem") {
      jumpToQueueItem(parameters);
    }
  }

  void startMusicPlaybackAndCreateQueue(parameters) async {
    var passedParameters = parameters;
    // current index to identify which song to start playing with
    int currIndex = passedParameters["currIndex"];
    await getMp3URL(
        passedParameters["allSongs"][passedParameters["currIndex"]], true);
    currIndex += 1;
    for (int i = 0; i < passedParameters["allSongs"].length - 1; i++) {
      if (currIndex >= passedParameters["allSongs"].length) currIndex = 0;
      await getMp3URL(passedParameters["allSongs"][currIndex], false);
      currIndex += 1;
    }
  }

  void addItemToQueue(parameters) {
    bool alreadyExists = false;
    // ckecking if song already Exists in queue
    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].artUri == parameters["song"]["thumbnail"])
        alreadyExists = true;
    }
    // if song does not exsist in queue
    if (!alreadyExists)
      getMp3URLToQueue(parameters["song"], false);
    else
      globalFun.showToastMessage(
          "Song already Exists in queue", Colors.red, Colors.white, false);
  }

  void removeItemFromQueue(parameters) async {
    // checking if queue length is just one
    if (_queue.length == 1) {
      onStop();
    } else {
      // checking if the item to be removed is the current playing item
      if (parameters["currentArtURI"] == _queue[parameters["index"]].artUri) {
        // correcting the queue index of the current playing song
        for (int i = 0; i < _queue.length; i++) {
          if (parameters["currentArtURI"] == _queue[i].artUri) {
            _queueIndex = i;
          }
        }
        await onSkipToNext();
        _queueMeta.remove(_queue[parameters["index"]].artUri);
        _queue.removeAt(parameters["index"]);
        AudioServiceBackground.setQueue(_queue);
      } else {
        _queueMeta.remove(_queue[parameters["index"]].artUri);
        _queue.removeAt(parameters["index"]);
        AudioServiceBackground.setQueue(_queue);
        var state = AudioServiceBackground.state.basicState;
        var position = _audioPlayer.playbackEvent.position.inMilliseconds;
        AudioServiceBackground.setState(
            controls: getControls(state),
            basicState: state,
            position: position);
      }
      // correcting the queue index of the current playing song
      for (int i = 0; i < _queue.length; i++) {
        if (parameters["currentArtURI"] == _queue[i].artUri) {
          _queueIndex = i;
        }
      }
    }
  }

  void updateQueryOrder(parameters) {
    // checks if the rearrangement is upqueue or downqueue
    if (parameters["newIndex"] < parameters["oldIndex"]) {
      _queue.insert(parameters["newIndex"], _queue[parameters["oldIndex"]]);
      _queue.removeAt(parameters["oldIndex"] + 1);
    } else if (parameters["newIndex"] > parameters["oldIndex"]) {
      _queue.insert(parameters["newIndex"], _queue[parameters["oldIndex"]]);
      _queue.removeAt(parameters["oldIndex"]);
    }

    // correcting the queue index of the current playing song
    for (int i = 0; i < _queue.length; i++) {
      if (parameters["currentArtURI"] == _queue[i].artUri) {
        print("New Queue Index: " + i.toString());
        _queueIndex = i;
      }
    }
    AudioServiceBackground.setQueue(_queue);
    // refreshing the audioService state
    var state = AudioServiceBackground.state.basicState;
    var position = _audioPlayer.playbackEvent.position.inMilliseconds;
    AudioServiceBackground.setState(
        controls: getControls(state), basicState: state, position: position);
  }

  void addSongListToQueue(parameters) {
    // checking if queue is empty
    if (_queue.length == 0) {
      var state = BasicPlaybackState.connecting;
      var position = 0;
      AudioServiceBackground.setState(
          controls: getControls(state), basicState: state, position: position);
    }
    audioServiceGlobalFun.addSongListToQueue(parameters, getMp3URL, _queue);
  }

  void jumpToQueueItem(parameters) async {
    int index = parameters["index"];
    if (index == _queue.length)
      _queueIndex = index - 1;
    else if (index == 0)
      _queueIndex = _queue.length - 1;
    else
      _queueIndex = index - 1;

    await onSkipToNext();
  }

  void _setState({@required BasicPlaybackState state, int position}) {
    if (position == null) {
      position = _audioPlayer.playbackEvent.position.inMilliseconds;
    }
    AudioServiceBackground.setState(
      controls: getControls(state),
      systemActions: [MediaAction.seekTo],
      basicState: state,
      position: position,
    );
  }

  // gets the mp3URL using videoID and i parameter to start playback on true
  Future getMp3URL(parameter, bool shouldPlay) async {
    // holds the responseJSON for checking link validity
    var responseJSON;
    // getting the mp3URL
    try {
      // checking for link validity
      String url = "https://api.openbeats.live/opencc/" +
          parameter["videoId"].toString();
      // sending GET request
      responseJSON = await Dio().get(url);
    } catch (e) {
      // catching dio error
      if (e is DioError) {
        globalFun.showToastMessage(
            "Cannot connect to the server", Colors.red, Colors.white, false);
        return;
      }
    }
    if (responseJSON.data["status"] == true &&
        responseJSON.data["link"] != null) {
      MediaItem mediaItem = MediaItem(
        id: responseJSON.data["link"],
        album: "OpenBeats Music",
        title: parameter['title'],
        duration: globalFun.getDurationMillis(parameter["duration"]),
        artist: parameter['channelName'],
        artUri: parameter['thumbnail'],
      );
      _queue.add(mediaItem);
      // adding song thumbnail to the queueMeta list
      _queueMeta.add(parameter['thumbnail']);
      AudioServiceBackground.setQueue(_queue);

      if (shouldPlay) {
        await onSkipToNext();
      }
    } else {
      onStop();
    }
    if (_audioPlayer.playbackEvent != null) {
      // refreshing the audioService state
      var state = AudioServiceBackground.state.basicState;
      var position = _audioPlayer.playbackEvent.position.inMilliseconds;
      AudioServiceBackground.setState(
          controls: getControls(state), basicState: state, position: position);
    }
  }

  // gets the mp3URL using videoID and add to the queue
  void getMp3URLToQueue(parameter, bool shouldBeNowPlaying) async {
    // checking if media is present in the queueMeta list
    if (!_queueMeta.contains(parameter["thumbnail"])) {
      // holds the responseJSON for checking link validity
      // adding song thumbnail to the queueMeta list
      _queueMeta.add(parameter['thumbnail']);
      var responseJSON;
      // pausing current playing media to provide instant feedback
      if(shouldBeNowPlaying) onPause();
      // getting the mp3URL
      try {
        // checking for link validity
        String url =
            "https://api.openbeats.live/opencc/" + parameter["videoId"];
        // sending GET request
        responseJSON = await Dio().get(url);
      } catch (e) {
        // catching dio error
        if (e is DioError) {
          globalFun.showToastMessage(
              "Cannot connect to the server", Colors.red, Colors.white, false);
          onStop();
          return;
        }
      }
      if (responseJSON.data["status"] == true &&
          responseJSON.data["link"] != null) {
        // setting the current mediaItem
        MediaItem temp = MediaItem(
          id: responseJSON.data["link"],
          album: "OpenBeats Music",
          title: parameter['title'],
          artist: parameter['channelName'],
          duration: globalFun.getDurationMillis(parameter['duration']),
          artUri: parameter['thumbnail'],
        );
        (shouldBeNowPlaying)
            ? _queue.insert(_queueIndex, temp)
            : _queue.add(temp);
        
        AudioServiceBackground.setQueue(_queue);
        if (shouldBeNowPlaying) {
          // starting playback again 
          onPlay();
          int indexOfItem;
          // finding the index of the element to play
          for (int i = 0; i < _queue.length; i++) {
            if (_queue[i].id == temp.id) indexOfItem = i;
          }
          _queueIndex = indexOfItem + 1;
          onSkipToPrevious();
        }
        var state = AudioServiceBackground.state.basicState;
        var position = _audioPlayer.playbackEvent.position.inMilliseconds;
        AudioServiceBackground.setState(
            controls: getControls(state),
            basicState: state,
            position: position);
        globalFun.showQueueBasedToasts(1);
      } else {
        onStop();
      }
    } else {
// index buffer to prevent modifying the _queueIndex value
      int tempIndex = -1;
      // finding index of the song clicked
      for (int i = 0; i < _queue.length; i++) {
        if (parameter["thumbnail"] == _queue[i].artUri) {
          tempIndex = i;
        }
      }
      // checking if song exists in queue
      if (tempIndex != -1) {
        _queueIndex = tempIndex + 1;
        onSkipToPrevious();
      }
    }
  }
}
