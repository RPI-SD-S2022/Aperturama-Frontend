import 'package:flutter/material.dart';
import 'package:aperturama/utils/main_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/main_drawer.dart';

class Photos extends StatefulWidget {
  const Photos({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<Photos> createState() => _PhotosState();
}

class _PhotosState extends State<Photos> {
  int _gridSize = 4;
  final int _gridSizeMax = 8;

  void _changeGridSize(int amount) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      if (amount < 0) {
        if (_gridSize + amount <= 0) {
          _gridSize = 1;
        } else {
          _gridSize += amount;
        }
      } else if (amount > 0) {
        if (_gridSize + amount >= _gridSizeMax) {
          _gridSize = _gridSizeMax;
        } else {
          _gridSize += amount;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Aperturama"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                _changeGridSize(1);
              },
              tooltip: 'Decrease Image Size',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                _changeGridSize(-1);
              },
              tooltip: 'Increase Image Size',
            ),
          ],
        ),
        body: GridView.count(
          // Create a grid with 2 columns. If you change the scrollDirection to
          // horizontal, this produces 2 rows.
          crossAxisCount: _gridSize,
          // Generate 100 widgets that display their index in the List.
          children: List.generate(400, (index) {
            return Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: 'https://picsum.photos/250?random=' +
                            index.toString(),
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                    value: downloadProgress.progress),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        drawer: const MainDrawer());
  }
}
