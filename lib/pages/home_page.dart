import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radio/model/radio.dart';
import 'package:radio/utils/ai_util.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final url = "https://api.jsonbin.io/b/612d55844fcbee60cee1b515/latest";
  List<MyRadio>? radios;
  MyRadio? _selectedRadio;
  Color? _selectedColor = Vx.blue800;
  bool _isPlaying = false;

  final sugg = [
    "Play",
    "Stop",
    "Play pop music",
    "Next",
    "Previous",
    "Play Uk",
    "Pause",
    "Play Rap Hits"
  ];
  final AudioPlayer _audioPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    setupAlan();
    fetchRadios();

    _audioPlayer.onPlayerCompletion.listen((event) {
      final index = _selectedRadio!.id;
      MyRadio newRadio;
      if (index + 1 > radios!.length) {
        newRadio = radios!.firstWhere((element) => element.id == 1);
        radios!.remove(newRadio);
        radios!.insert(0, newRadio);
      } else {
        newRadio = radios!.firstWhere((element) => element.id == index + 1);
        radios!.remove(newRadio);
        radios!.insert(0, newRadio);
      }
      _playMusic(newRadio.url);
    });
    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.PLAYING) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      setState(() {});
    });
  }

  setupAlan() async {
    AlanVoice.addButton(
        "7c62990180d20fe26465ba1d1ddc5ab42e956eca572e1d8b807a3e2338fdd0dc/prod",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.callbacks.add((command) => _handleCommand(command.data));
  }

  _handleCommand(Map<String, dynamic> response) {
    switch (response["command"]) {
      case "play":
        _playMusic(_selectedRadio!.url);
        break;
      case "play_channel":
        final id = response["id"];

        MyRadio newRadio = radios!.firstWhere((element) => element.id == id);
        radios!.remove(newRadio);
        radios!.insert(0, newRadio);
        _playMusic(newRadio.url);
        break;
      case "stop":
        _audioPlayer.stop();
        break;
      case "next":
        final index = _selectedRadio!.id;
        MyRadio newRadio;
        if (index + 1 > radios!.length) {
          newRadio = radios!.firstWhere((element) => element.id == 1);
          radios!.remove(newRadio);
          radios!.insert(0, newRadio);
        } else {
          newRadio = radios!.firstWhere((element) => element.id == index + 1);
          radios!.remove(newRadio);
          radios!.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;
      case "prev":
        final index = _selectedRadio!.id;
        MyRadio newRadio;
        if (index - 1 <= radios!.length) {
          newRadio = radios!.firstWhere((element) => element.id == 1);
          radios!.remove(newRadio);
          radios!.insert(0, newRadio);
        } else {
          newRadio = radios!.firstWhere((element) => element.id == index - 1);
          radios!.remove(newRadio);
          radios!.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;
      default:
        print("Command was ${response["command"]}");
        break;
    }
  }

  fetchRadios() async {
    final response = await http.get(Uri.parse(url));
    final radioJson = response.body;
    radios = MyRadioList.fromJson(radioJson).radios;
    _selectedRadio = radios![0];
    _selectedColor = Vx.hexToColor(_selectedRadio!.color);
    print(radios);
    setState(() {});
  }

  _playMusic(String url) {
    _audioPlayer.play(url);
    _selectedRadio = radios!.firstWhere((element) => element.url == url);
    print(_selectedRadio!.name);

    setState(() {});
  }

  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: _selectedColor ?? AIColors.primaryColor2,
          child: radios != null
              ? [
                  "All Channels".text.xl.white.semiBold.make().p16(),
                  10.heightBox,
                  ListView(
                    padding: Vx.m0,
                    shrinkWrap: true,
                    children: radios!
                        .map((e) => ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(e.icon),
                            ),
                            title: e.name.text.white.make(),
                            subtitle:
                                e.tagline.text.caption(context).white.make()))
                        .toList(),
                  ),
                  20.heightBox,
                ].vStack()
              : const Offstage(),
        ),
      ),
      body: Stack(
        children: [
          VxAnimatedBox()
              .seconds(sec: 1)
              .size(context.screenWidth, context.screenHeight)
              .withGradient(LinearGradient(
                colors: [
                  AIColors.primaryColor2,
                  _selectedColor ?? AIColors.primaryColor
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
              .make(),
          [
            AppBar(
              title: "AI Radio".text.xl4.bold.white.make().shimmer(
                  primaryColor: Vx.gray500, secondaryColor: Colors.white),
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              centerTitle: true,
            ).h(100.0).px16().py0(),
            "Start with ~ Hey Alan".text.italic.semiBold.white.make(),
            20.heightBox,
            VxSwiper.builder(
                itemCount: sugg.length,
                height: 50.0,
                viewportFraction: 0.35,
                autoPlay: true,
                autoPlayAnimationDuration: 3.seconds,
                enableInfiniteScroll: true,
                autoPlayCurve: Curves.linear,
                itemBuilder: (context, index) {
                  final s = sugg[index];
                  return Chip(
                    label: s.text.make(),
                    backgroundColor: Vx.randomColor,
                  );
                }),
          ].vStack(alignment: MainAxisAlignment.start),
          radios != null
              ? Container(
                  margin: EdgeInsets.only(top: 75),
                  child: VxSwiper.builder(
                    itemCount: radios!.length,
                    aspectRatio: 1.0,
                    enlargeCenterPage: true,
                    onPageChanged: (index) {
                      final colorHex = radios![index].color;
                      _selectedColor = Vx.hexToColor(colorHex);
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final rad = radios![index];
                      return VxBox(
                              child: ZStack(
                        [
                          Positioned(
                              top: 0.0,
                              right: 0.0,
                              child: VxBox(
                                      child: rad.category.text.uppercase.white
                                          .make()
                                          .px16())
                                  .height(40)
                                  .black
                                  .alignCenter
                                  .withRounded(value: 10.0)
                                  .make()),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: VStack(
                              [
                                rad.name.text.xl2.white.bold.make(),
                                5.heightBox,
                                rad.tagline.text.sm.white.semiBold.make().p12()
                              ],
                              crossAlignment: CrossAxisAlignment.center,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: [
                              Icon(CupertinoIcons.play_circle,
                                  color: Colors.white),
                              10.heightBox,
                              "Double tap to play".text.gray300.make()
                            ].vStack(),
                          )
                        ],
                      ))
                          .clip(Clip.antiAlias)
                          .bgImage(
                            DecorationImage(
                                image: NetworkImage(rad.image),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.3),
                                    BlendMode.darken)),
                          )
                          .border(color: Colors.black, width: 5.0)
                          .withRounded(value: 60.0)
                          .make()
                          .onInkDoubleTap(() {
                        _playMusic(rad.url);
                      }).p16();
                    },
                  ),
                )
              : CircularProgressIndicator().centered(),
          Align(
            alignment: Alignment.bottomCenter,
            child: [
              if (_isPlaying)
                "Playing Now - ${_selectedRadio!.name}"
                    .text
                    .white
                    .makeCentered()
                    .py2(),
              Icon(
                _isPlaying
                    ? CupertinoIcons.stop_circle
                    : CupertinoIcons.play_circle,
                color: Colors.white,
                size: 50,
              ).onInkTap(() {
                if (_isPlaying) {
                  _audioPlayer.pause();
                } else {
                  _playMusic(_selectedRadio!.url);
                }
              })
            ].vStack(),
          ).pOnly(bottom: context.percentHeight * 5)
        ],
        fit: StackFit.expand,
      ),
    );
  }
}
