import 'package:aperturama/routes/photo_settings.dart';
import 'package:aperturama/utils/media.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


class PhotoViewer extends StatefulWidget {
  const PhotoViewer({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  double _maxScale = 1;

  @override
  Widget build(BuildContext context) {
    // Take in information about the current photo given as args,
    // or set it to no photo if the args are invalid for some reason
    final Photo photo;
    if(ModalRoute.of(context)!.settings.arguments != null) {
      photo = ModalRoute.of(context)!.settings.arguments as Photo;
    } else {
      photo = Photo("", "", "");
      // Todo: Probably navigate back to the /photos page
    }

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Photo Viewer"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    barrierDismissible: true,
                    opaque: false,
                    pageBuilder: (_, anim1, anim2) =>
                        PhotoSettings(photo: photo),
                  ),
                );
              },
              tooltip: 'Image Information and Settings',
            ),
          ],
        ),
        body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: _maxScale,
              child: CachedNetworkImage(
                imageUrl: photo.highresURL,
                // Make the image fit the width
                imageBuilder: (context, imageProvider) {
                  WidgetsBinding.instance?.addPostFrameCallback((_) => setState(() {
                        _maxScale = 16;
                      }));
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  );
                },
                // Show the low res thumbnail while waiting for the high res to load
                progressIndicatorBuilder: (context, url, downloadProgress) => Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Low-res thumbnail
                    CachedNetworkImage(
                      imageUrl: photo.thumbnailURL,
                      progressIndicatorBuilder: (context, url, downloadProgress) =>
                          CircularProgressIndicator(
                              value: downloadProgress.progress),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                      // Make the image fit the width
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                    // Show the progress indicator on top of the low-res pic
                    CircularProgressIndicator(value: downloadProgress.progress),
                  ],
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            )
        )
    );
  }
}
