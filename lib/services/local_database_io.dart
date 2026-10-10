import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openLocalDatabase() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final path = '${directory.path}${Platform.pathSeparator}su_kien_gia_toc.db';
  return databaseFactoryIo.openDatabase(path);
}
