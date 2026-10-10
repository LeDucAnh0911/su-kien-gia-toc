import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

Future<Database> openLocalDatabase() =>
    databaseFactoryWeb.openDatabase('su_kien_gia_toc');
