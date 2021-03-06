import 'package:aperturama/utils/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:developer';

enum MediaType {
  photo,
  video
}

class Media {
  late final String id;
  final MediaType type;
  late final String thumbnailURL;
  late final String highresURL;
  late final String localPath;
  late final String filename;

  bool shared = false;
  String sharingCode = "None";
  String sharingLink = "None";
  List<String> sharingUsers = [];

  late bool uploadedSuccessfully;
  DateTime uploadedTimestamp = DateTime.fromMicrosecondsSinceEpoch(0);
  DateTime takenTimestamp = DateTime.fromMicrosecondsSinceEpoch(0);

  Media(this.id, this.type, this.thumbnailURL, this.highresURL);

  Media.uploaded(this.id, this.type, this.thumbnailURL, this.highresURL,
      this.localPath, this.uploadedTimestamp) {
    uploadedSuccessfully = true;
  }

  Media.pendingUpload(this.type, this.localPath) {
    uploadedSuccessfully = false;
  }

  Media.fromJson(Map<String, dynamic> json) :
        id = json['id'],
        type = MediaType.values.byName(json['type']),
        thumbnailURL = json['thumbnailURL'],
        highresURL = json['highresURL'],
        localPath = json['localPath'],
        uploadedSuccessfully = json['uploadedSuccessfully'] == "true" ? true : false,
        uploadedTimestamp = DateTime.parse(json['uploadedTimestamp']);

  Map<String, dynamic> toJson() => {
    'id' : id,
    'type': type.name,
    'thumbnailURL' : thumbnailURL,
    'highresURL' : highresURL,
    'localPath' : localPath,
    'uploadedSuccessfully' : uploadedSuccessfully ? "true" : "false",
    'uploadedTimestamp' : uploadedTimestamp.toIso8601String(),
  };

  Future<bool> regenerateSharedLink() async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.post(Uri.parse(serverAddress + '/api/v1/media/' + id + "/share/link"),
        headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },);

      if(resp.statusCode != 200) {
        log("regenerateSharedLink Non 200 status code: " + resp.statusCode.toString());
        return false;

      } else {
        final data = jsonDecode(resp.body);

        // Success, save info
        sharingLink = serverAddress + "/#/s?media=" + id + "&code=" + data["code"];
        return true;
      }

    } on SocketException {
      log("regenerateSharedLink socket exception");
      return false;
    }
  }

  Future<bool> shareWithUser(String email) async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.post(Uri.parse(serverAddress + '/api/v1/media/' + id + "/share/user"),
        headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
        body: { "email": email }
      );

      if(resp.statusCode != 200) {
        log("shareWithUser Non 200 status code: " + resp.statusCode.toString());
        return false;

      } else {
        // Success, save info
        if(!sharingUsers.contains(email)) {
          sharingUsers.add(email);
        }
        return true;
      }

    } on SocketException {
      log("shareWithUser socket exception");
      return false;
    }
  }

  Future<bool> unshareWithUser(String email) async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.delete(
          Uri.parse(serverAddress + '/api/v1/media/' + id + "/share/user"),
          headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt},
          body: { "email": email}
      );

      if (resp.statusCode != 200) {
        log("unshareWithUser Non 200 status code: " +
            resp.statusCode.toString());
        return false;
      } else {
        // Success, save info
        sharingUsers.remove(email);
        return true;
      }
    } on SocketException {
      log("unshareWithUser socket exception");
      return false;
    }
  }

  Future<bool> delete() async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.delete(Uri.parse(serverAddress + '/api/v1/media/' + id),
          headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
      );

      if(resp.statusCode != 200) {
        log("delete Non 200 status code: " + resp.statusCode.toString());
        return false;
      } else {
        return true;
      }

    } on SocketException {
      log("delete socket exception");
      return false;
    }
  }
}

class Collection {
  String name;
  String information;
  final String id;

  bool shared = false;
  String sharingCode = "None";
  String sharingLink = "None";
  List<String> sharingUsers = [];

  List<Media> media = []; // may also be previewImages and the rest gathered
  // in collection_viewer, which is probably better. new field needed though

  Collection(this.name, this.information, this.id, this.shared, this.media);

  Future<bool> updateName(String n) async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.put(Uri.parse(serverAddress + '/api/v1/collections/' + id),
        headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
        body: { "name": n }
      );

      if(resp.statusCode != 200) {
        log("updateName Non 200 status code: " + resp.statusCode.toString());
        return false;

      } else {
        // Success, save info
        name = n;
        return true;
      }

    } on SocketException {
      log("updateName socket exception");
      return false;
    }
  }

  Future<bool> updateSharing(bool s) async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      if(s) {
        resp = await http.post(Uri.parse(serverAddress + '/api/v1/collections/' + id + "/share/link"),
          headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
        );
      } else {
        resp = await http.delete(Uri.parse(serverAddress + '/api/v1/collections/' + id + "/share/link/" + sharingCode),
          headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
        );
      }

      if(resp.statusCode != 200) {
        log("updateSharing Non 200 status code: " + resp.statusCode.toString());
        return false;

      } else {
        // Success, save info
        shared = s;
        if(s) {
          final data = jsonDecode(resp.body);
          sharingCode = data["code"];
          sharingLink = serverAddress + "/#/s?collection=" + id + "&code=" + sharingCode;
        } else {
          sharingCode = "";
        }
        return true;
      }

    } on SocketException {
      log("updateSharing socket exception");
      return false;
    }
  }


  Future<bool> regenerateSharedLink() async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.post(Uri.parse(serverAddress + '/api/v1/collections/' + id + "/share/link"),
        headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },);

      if(resp.statusCode != 200) {
        log("regenerateSharedLink Non 200 status code: " + resp.statusCode.toString());
        return false;

      } else {
        // Success, save info
        final data = jsonDecode(resp.body);
        sharingCode = data["code"];
        sharingLink = serverAddress + "/#/s?collection=" + id + "&code=" + sharingCode;
        return true;
      }

    } on SocketException {
      log("regenerateSharedLink socket exception");
      return false;
    }
  }

  Future<bool> shareWithUser(String email, bool editable) async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.post(Uri.parse(serverAddress + '/api/v1/collections/' + id + "/share/user"),
          headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
          body: { "email": email, "canAdd": editable.toString(), "canRemove": editable.toString() }
      );

      if(resp.statusCode != 200) {
        log("shareWithUser Non 200 status code: " + resp.statusCode.toString());
        return false;

      } else {
        // Success, save info
        if(!sharingUsers.contains(email)) {
          sharingUsers.add(email);
        }
        return true;
      }

    } on SocketException {
      log("shareWithUser socket exception");
      return false;
    }
  }

  Future<bool> unshareWithUser(String email) async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.delete(
          Uri.parse(serverAddress + '/api/v1/collections/' + id + "/share/user"),
          headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt},
          body: { "email": email}
      );

      if (resp.statusCode != 200) {
        log("unshareWithUser Non 200 status code: " +
            resp.statusCode.toString());
        return false;
      } else {
        // Success, save info
        sharingUsers.remove(email);
        return true;
      }
    } on SocketException {
      log("unshareWithUser socket exception");
      return false;
    }
  }

  Future<bool> delete() async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.delete(Uri.parse(serverAddress + '/api/v1/collections/' + id),
        headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
      );

      if(resp.statusCode != 200) {
        log("delete Non 200 status code: " + resp.statusCode.toString());
        return false;
      } else {
        return true;
      }

    } on SocketException {
      log("delete socket exception");
      return false;
    }
  }

  Future<bool> addMedia(List<Media> newMedia) async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    for (int i = 0; i < newMedia.length; i++) {
      try {
        resp = await http.post(Uri.parse(serverAddress + '/api/v1/collections/' + id),
            headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt},
            body: { "media_id": newMedia[i].id }
        );

        if (resp.statusCode != 200 && resp.statusCode != 304) {
          log("addMedia Non 200/304 status code: " + resp.statusCode.toString());
          return false;
        }
        // else continue to the rest of the media
        media.add(newMedia[i]);

      } on SocketException {
        log("addMedia socket exception");
        return false;
      }
    }
    return true;
  }

  Future<bool> removeMedia(List<Media> mediaToDelete) async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    for (int i = 0; i < mediaToDelete.length; i++) {
      try {
        resp = await http.delete(Uri.parse(serverAddress + '/api/v1/collections/' + id + "/media/" + mediaToDelete[i].id),
            headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt},
        );

        if (resp.statusCode != 200 && resp.statusCode != 304) {
          log("removeMedia Non 200/304 status code: " + resp.statusCode.toString());
          return false;
        }
        // else continue to the rest of the media
        media.remove(mediaToDelete[i]);

      } on SocketException {
        log("removeMedia socket exception");
        return false;
      }
    }
    return true;
  }
}


class MediaCollectionsLists {
  final List<Collection> collections;
  final List<Media> media;

  MediaCollectionsLists(this.collections, this.media);
}

class MediaFolder {
  String path;
  int itemCount;

  MediaFolder(this.path, this.itemCount);

  MediaFolder.fromJson(Map<String, dynamic> json)
      : path = json['path'],
        itemCount = json['itemCount'];

  Map<String, dynamic> toJson() => {
    'path' : path,
    'itemCount' : itemCount
  };
}

class MediaFolderList {
  List<MediaFolder>? mediaFolders;

  MediaFolderList(this.mediaFolders);

  MediaFolderList.fromJson(Map<String, dynamic> json)
      : mediaFolders = json['mediaFolders'] != null ? List<MediaFolder>.from(json['mediaFolders']) : null;

  Map<String, dynamic> toJson() => {
    'mediaFolders' : mediaFolders,
  };
}
