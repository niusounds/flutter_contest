import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_resonance_audio/flutter_resonance_audio.dart';

const name = 'Fluttone';
const rows = 16;
const cols = 5;

String assetForNote(int n) => 'sound/note$n.ogg';

final audioEngine = FlutterResonanceAudio();

void main() async {
  await audioEngine.init(renderingMode: RenderingMode.STEREO_PANNING);

  for (int i = 1; i <= 5; i++) {
    await audioEngine.preloadSoundFile(assetForNote(i));
  }

  runApp(MaterialApp(title: name, theme: ThemeData.dark(), home: App()));
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  List<List<bool>> _notes;
  AnimationController _anim;
  int _beat = 0;
  bool get _playing => _anim.isAnimating;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _anim.addListener(() {
      setState(() {
        _beat = (_anim.value * rows).floor();
      });
    });

    _randomize();
  }

  void _randomize() => _notes = List.generate(
      rows, (i) => List.generate(cols, (i) => Random().nextInt(i + 2) < 1));

  void _clear() =>
      _notes = List.generate(rows, (i) => List.filled(cols, false));

  void _playPause() {
    if (_playing) {
      _anim.stop();
      _anim.reset();
    } else {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(name),
        actions: <Widget>[
          IconButton(
            tooltip: 'Random',
            onPressed: () => setState(_randomize),
            icon: Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: () => setState(_clear),
            icon: Icon(Icons.delete),
          ),
          IconButton(
            tooltip: _playing ? 'Pause' : 'Play',
            onPressed: () => setState(_playPause),
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: GridView.builder(
              reverse: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 4 / 5,
                crossAxisCount: rows,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: rows * cols,
              itemBuilder: _buildBox,
            ),
          ),
          Bar(beat: _anim.value * rows),
        ],
      ),
    );
  }

  Widget _buildBox(BuildContext context, int i) {
    int beat = i % rows;
    int note = i ~/ rows;
    bool enable = _notes[beat][note];
    return Box(
      enable: enable,
      noteOn: enable && _playing && beat == _beat,
      onTap: () => setState(() => _toggle(beat, note)),
      onPlay: () => _play(note + 1),
    );
  }

  void _toggle(int beat, int note) {
    _notes[beat][note] = !_notes[beat][note];
  }

  _play(int note) async {
    int id = await audioEngine.createSoundObject(assetForNote(note));
    audioEngine.playSound(id);
  }
}

class Bar extends StatelessWidget {
  final double beat;

  Bar({this.beat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: beat / rows * MediaQuery.of(context).size.width),
      child: SizedBox(
        width: 4,
        child: Container(decoration: BoxDecoration(color: Colors.black)),
      ),
    );
  }
}

class Box extends StatefulWidget {
  final bool enable;
  final bool noteOn;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  Box({this.enable, this.noteOn, this.onTap, this.onPlay});

  @override
  _BoxState createState() => _BoxState();
}

class _BoxState extends State<Box> {
  @override
  void didUpdateWidget(Box oldWidget) {
    if (!oldWidget.noteOn && widget.noteOn) {
      widget.onPlay();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _color,
        ),
        margin: EdgeInsets.all(widget.noteOn ? 2 : 4),
      ),
    );
  }

  Color get _color => widget.enable
      ? widget.noteOn ? Colors.yellowAccent : Colors.green
      : Colors.white;
}
