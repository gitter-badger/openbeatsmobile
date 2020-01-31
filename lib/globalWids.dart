import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:openbeatsmobile/pages/addSongsToPlaylistPage.dart';

import './globalVars.dart' as globalVars;
import './globalFun.dart' as globalFun;

// snackBar to show network error
SnackBar networkErrorSBar = new SnackBar(
  content: Text(
    "Not able to connect to the internet",
    style: TextStyle(color: Colors.white),
  ),
  backgroundColor: Colors.orange,
  duration: Duration(hours: 10),
);

Widget noInternetView(refreshFunction) {
  return Container(
      margin: EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              child: Icon(
                FontAwesomeIcons.redo,
                size: 40.0,
                color: globalVars.accentRed,
              ),
              onPressed: () {
                refreshFunction();
              },
              color: Colors.transparent,
              textColor: globalVars.accentBlue,
            ),
            SizedBox(
              height: 20.0,
            ),
            Text("Not able to connect to\nserver",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 22.0)),
          ],
        ),
      ));
}

// used to fade transition to search page
class FadeRouteBuilder<T> extends PageRouteBuilder<T> {
  final Widget page;
  FadeRouteBuilder({@required this.page})
      : super(
          pageBuilder: (context, animation1, animation2) => page,
          transitionsBuilder: (context, animation1, animation2, child) {
            return FadeTransition(opacity: animation1, child: child);
          },
        );
}

// holds the flutterActor for showing the current playing media
Widget nowPlayingFlutterActor(bool isPlaying) {
  return FlareActor(
    'assets/flareAssets/analysis_new.flr',
    animation: isPlaying
        ? null
        : 'ana'
            'lysis'
            '',
    fit: BoxFit.scaleDown,
  );
}

// holds the loadingAnimation for the current playing media file
Widget nowPlayingLoadingAnimation() {
  return Container(
      margin: EdgeInsets.all(20.0),
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(globalVars.accentWhite),
      ));
}

// shows the actual thumbnail of the media
Widget showActualThumbnail(String thumbnail) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(globalVars.borderRadius),
    child: CachedNetworkImage(
      imageUrl: thumbnail,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        margin: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(globalVars.accentRed),
        ),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    ),
  );
}

// widget to hold each container of video results
Widget homePageVidResultContainerW(context, videosResponseItem, index,
    getMp3URL, settingModalBottomSheet, videosResponseListLength) {
  return InkWell(
      onTap: () async {
        if (AudioService.playbackState != null &&
            AudioService.currentMediaItem != null &&
            AudioService.currentMediaItem.artUri ==
                videosResponseItem["thumbnail"] &&
            (AudioService.playbackState.basicState ==
                    BasicPlaybackState.playing ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.buffering ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.paused) &&
            AudioService.queue.length == 0) {
          settingModalBottomSheet(context);
        } else {
          await getMp3URL(videosResponseItem["videoId"], index);
        }
      },
      child: Container(
        margin: EdgeInsets.only(
            bottom: (index < videosResponseListLength - 1) ? 10.0 : 70.0,
            left: 10.0,
            right: 10.0,
            top: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            vidResultThumbnail(context, videosResponseItem["thumbnail"], 1),
            SizedBox(
              width: 15.0,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  vidResultVidDetails(context, videosResponseItem["title"],
                      videosResponseItem["duration"]),
                  homePageVidResultExtraOptions(context, videosResponseItem)
                ],
              ),
            ),
          ],
        ),
      ));
}

// holds the extra options of video result list
Widget homePageVidResultExtraOptions(context, videosResponseItem) {
  return Container(
    alignment: Alignment.centerRight,
    width: MediaQuery.of(context).size.width * 0.1,
    child: PopupMenuButton<String>(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(globalVars.borderRadius)),
        icon: Icon(
          Icons.more_vert,
          size: 30.0,
        ),
        onSelected: (choice) {
          if (globalVars.loginInfo["loginStatus"] == true) {
            if (choice == "addToPlayList") {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddSongsToPlaylistPage(videosResponseItem),
                  ));
            } else if (choice == "addToPlaylist") {
              globalFun.showUnderDevToast();
            } else if (choice == "favorite") {
              globalFun.showUnderDevToast();
            }
          } else {
            globalFun.showToastMessage(
                "Please login to use feature", Colors.black, Colors.white);
            Navigator.pushNamed(context, '/authPage');
          }
        },
        itemBuilder: (context) => [
              PopupMenuItem(
                  value: "download",
                  child: ListTile(
                    title: Text("Download"),
                    leading: Icon(Icons.file_download),
                  )),
              PopupMenuItem(
                  value: "addToPlayList",
                  child: ListTile(
                    title: Text("Add to Playlist"),
                    leading: Icon(Icons.playlist_add),
                  )),
              PopupMenuItem(
                  value: "favorite",
                  child: ListTile(
                    title: Text("Favorite"),
                    leading: Icon(Icons.favorite_border),
                  ))
            ]),
  );
}

// widget to hold each container of video results
Widget playlistPageVidResultContainerW(context, videosResponseItem, index,
    startPlaylistFromMusic, showRemoveSongConfirmationBox) {
  return InkWell(
      onTap: () async {
        startPlaylistFromMusic(index);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20.0, left: 10.0, right: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            vidResultThumbnail(context, videosResponseItem["thumbnail"], 2),
            SizedBox(
              width: 15.0,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  vidResultVidDetails(context, videosResponseItem["title"],
                      videosResponseItem["duration"]),
                  playlistPageVidResultExtraOptions(context, videosResponseItem,
                      index, showRemoveSongConfirmationBox)
                ],
              ),
            ),
          ],
        ),
      ));
}

// holds the extra options of video result list
Widget playlistPageVidResultExtraOptions(
    context, videosResponseItem, index, showRemoveSongConfirmationBox) {
  return Container(
    alignment: Alignment.centerRight,
    width: MediaQuery.of(context).size.width * 0.1,
    child: PopupMenuButton<String>(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(globalVars.borderRadius)),
        elevation: 30.0,
        icon: Icon(
          Icons.more_vert,
          size: 30.0,
        ),
        onSelected: (choice) {
          if (choice == "deleteSong") {
            showRemoveSongConfirmationBox(index);
          } else if (choice == "favorite") {
            globalFun.showUnderDevToast();
          }
        },
        itemBuilder: (context) => [
              PopupMenuItem(
                  value: "deleteSong",
                  child: ListTile(
                    title: Text("Delete"),
                    leading: Icon(Icons.delete),
                  )),
              PopupMenuItem(
                  value: "favorite",
                  child: ListTile(
                    title: Text("Favorite"),
                    leading: Icon(Icons.favorite_border),
                  ))
            ]),
  );
}

// holds the thumbnail of results list
// page mode 1 - homePage / 2 - playlistPage
Widget vidResultThumbnail(context, thumbnail, pageMode) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.15,
      height: MediaQuery.of(context).size.width * 0.15,
      decoration: BoxDecoration(boxShadow: [
        new BoxShadow(
          color: Colors.black,
          blurRadius: 2.0,
          offset: new Offset(1.0, 1.0),
        ),
      ], borderRadius: BorderRadius.circular(globalVars.borderRadius)),
      child: StreamBuilder(
          stream: AudioService.playbackStateStream,
          builder: (context, snapshot) {
            PlaybackState state = snapshot.data;
            if (state != null) {
              if (AudioService.currentMediaItem != null &&
                  AudioService.currentMediaItem.artUri == thumbnail &&
                  ((AudioService.queue != null) &&
                          (pageMode == 2 && AudioService.queue.length > 0) ||
                      (pageMode == 1 && AudioService.queue.length == 0))) {
                if (state.basicState == BasicPlaybackState.connecting ||
                    state.basicState == BasicPlaybackState.buffering) {
                  return nowPlayingLoadingAnimation();
                } else if (state.basicState == BasicPlaybackState.playing) {
                  return nowPlayingFlutterActor(false);
                } else if (state.basicState == BasicPlaybackState.paused) {
                  return nowPlayingFlutterActor(true);
                }
              }
            }
            return showActualThumbnail(thumbnail);
          }));
}

// holds the video details of video list
Widget vidResultVidDetails(context, title, duration) {
  return Column(
    children: <Widget>[
      Container(
        width: MediaQuery.of(context).size.width * 0.60,
        child: Text(
          title,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 18.0,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
      SizedBox(
        height: 5.0,
      ),
      Text(
        duration,
        style: TextStyle(color: Colors.grey, fontSize: 12.0),
      )
    ],
    crossAxisAlignment: CrossAxisAlignment.start,
  );
}

// holds the background for the bottom sheet
Widget bottomSheetBGW(audioThumbnail) {
  return Opacity(
    child: Container(
        height: 300.0,
        color: Colors.black,
        child: ClipRRect(
          borderRadius: new BorderRadius.only(topRight: Radius.circular(globalVars.borderRadius), topLeft: Radius.circular(globalVars.borderRadius),),
          child: CachedNetworkImage(
            imageUrl: audioThumbnail,
            fit: BoxFit.cover,
            placeholder: (context, url) => null,
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
        )),
    opacity: 0.3,
  );
}

// holds the title for the bottomSheet
Widget bottomSheetTitleW(audioTitle) {
  return Container(
    alignment: Alignment.centerLeft,
    margin: EdgeInsets.all(10.0),
    child: Text(
      audioTitle,
      style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}

// holds the playback control buttons
Widget bNavPlayControlsW(context, state) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      bNavSkipPrevious(),
      SizedBox(
        width: 10.0,
      ),
      bNavPlayBtn(state),
      SizedBox(
        width: 10.0,
      ),
      bNavStopBtn(context, state),
      SizedBox(
        width: 10.0,
      ),
      bNavSkipNext()
    ],
  );
}

// button to hold the play and pause Button
// mode 1 - music stopped, 2 - music playing
Widget bNavPlayBtn(state) {
  return Container(
    child: (AudioService.playbackState != null)
        ? (AudioService.playbackState.basicState ==
                    BasicPlaybackState.playing ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.paused ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.skippingToNext ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.skippingToPrevious)
            ? IconButton(
                onPressed: () {
                  if (AudioService.playbackState != null &&
                      AudioService.playbackState.basicState !=
                          BasicPlaybackState.playing)
                    AudioService.play();
                  else
                    AudioService.pause();
                },
                iconSize: 45.0,
                icon: (AudioService.playbackState.basicState !=
                        BasicPlaybackState.playing)
                    ? Icon(FontAwesomeIcons.solidPlayCircle)
                    : Icon(FontAwesomeIcons.solidPauseCircle),
              )
            : null
        : null,
  );
}

// holds the skip previous
Widget bNavSkipPrevious() {
  return Container(
    child: (AudioService.playbackState != null && AudioService.queue.length > 0)
        ? (AudioService.playbackState.basicState ==
                    BasicPlaybackState.playing ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.paused ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.skippingToNext ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.skippingToPrevious)
            ? IconButton(
                onPressed: () {
                  AudioService.skipToPrevious();
                },
                iconSize: 30.0,
                icon: Icon(FontAwesomeIcons.stepBackward))
            : null
        : null,
  );
}

// holds the skip previous
Widget bNavSkipNext() {
  return Container(
    child: (AudioService.playbackState != null && AudioService.queue.length > 0)
        ? (AudioService.playbackState.basicState ==
                    BasicPlaybackState.playing ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.paused ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.skippingToNext ||
                AudioService.playbackState.basicState ==
                    BasicPlaybackState.skippingToPrevious)
            ? IconButton(
                onPressed: () {
                  AudioService.skipToNext();
                },
                iconSize: 30.0,
                icon: Icon(FontAwesomeIcons.stepForward))
            : null
        : null,
  );
}

// holds the buffering indicator
Widget bufferingIndicator() {
  return SizedBox(
    height: 20.0,
    child: Container(
      child: (AudioService.playbackState != null)
          ? (AudioService.playbackState.basicState ==
                  BasicPlaybackState.buffering)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 10.0,
                      width: 10.0,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(globalVars.accentRed),
                      ),
                    ),
                    SizedBox(
                      width: 5.0,
                    ),
                    Text(
                      "Buffering...",
                      style: TextStyle(color: Colors.grey),
                    )
                  ],
                )
              : null
          : null,
    ),
  );
}

// button to hold the stopButton
Widget bNavStopBtn(context, state) {
  return Container(
      child: (state != null)
          ? IconButton(
              onPressed: () {
                AudioService.stop();
                Navigator.pop(context);
              },
              icon: Icon(FontAwesomeIcons.stop),
            )
          : null);
}

// holds the media timing widgets
Widget mediaTimingW(state, getCurrentTimeStamp, context, audioDurationMin) {
  return Container(
    margin: EdgeInsets.only(left: 10.0, right: 10.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Container(
          child: Text(
              (state != null)
                  ? getCurrentTimeStamp(state.currentPosition / 1000)
                  : "00:00",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.start),
          width: MediaQuery.of(context).size.width * 0.5,
        ),
        Container(
          child: Text(
            audioDurationMin,
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.end,
          ),
          width: MediaQuery.of(context).size.width * 0.3,
        )
      ],
    ),
  );
}

Widget fabView(settingModalBottomSheet, scaffoldKey) {
  return StreamBuilder(
      stream: AudioService.playbackStateStream,
      builder: (context, snapshot) {
        PlaybackState state = snapshot.data;
        if (state != null && state.basicState == BasicPlaybackState.error) {
          // stopping audio playback if an error has been detected
          AudioService.stop();
        }

        return (state != null &&
                (state.basicState == BasicPlaybackState.connecting ||
                    state.basicState == BasicPlaybackState.playing ||
                    state.basicState == BasicPlaybackState.buffering ||
                    state.basicState == BasicPlaybackState.skippingToNext ||
                    state.basicState == BasicPlaybackState.skippingToPrevious ||
                    state.basicState == BasicPlaybackState.paused))
            ? (state.basicState == BasicPlaybackState.buffering ||
                    state.basicState == BasicPlaybackState.connecting ||
                    state.basicState == BasicPlaybackState.skippingToNext ||
                    state.basicState == BasicPlaybackState.skippingToPrevious)
                ? fabBtnW(
                    settingModalBottomSheet, context, false, false, scaffoldKey)
                : (state.basicState == BasicPlaybackState.paused)
                    ? fabBtnW(settingModalBottomSheet, context, true, true,
                        scaffoldKey)
                    : fabBtnW(settingModalBottomSheet, context, true, false,
                        scaffoldKey)
            : Container();
      });
}

// holds the floating action button
Widget fabBtnW(settingModalBottomSheet, context, bool isPlaying, bool isPaused,
    scaffoldKey) {
  return FloatingActionButton(
    onPressed: () {
      settingModalBottomSheet(context);
    },
    child: (isPlaying)
        ? FlareActor(
            'assets/flareAssets/analysis_new.flr',
            animation: (isPaused)
                ? null
                : 'ana'
                    'lysis'
                    '',
            fit: BoxFit.scaleDown,
          )
        : CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
          ),
    backgroundColor: Color(0xFFFF5C5C),
    foregroundColor: Colors.white,
  );
}
