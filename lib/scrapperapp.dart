import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:web_scraper/web_scraper.dart';

var pathFiles = "${Directory.current.path}\\domains\\";

void start() {
  readData().then((data) {
    generateDataFileProcessed(data);
  });
}

Future<Map> readData() async {
  Map<String, List> domainsData = {};
  for (var i = 1; i <= 4; i++) {
    var fileData = File("${pathFiles}serv_$i.txt");
    Stream<String> lines =
        fileData.openRead().transform(utf8.decoder).transform(LineSplitter());

    String server = "";
    List<String> dataDom = [];
    await for (var line in lines) {
      if (line.contains('server-')) {
        server = line;
      } else {
        dataDom.add(line);
      }
    }
    domainsData[server] = dataDom;
    dataDom = [];
  }
  return domainsData;
}

void generateDataFileProcessed(Map data) async {
  Map<String, List> processedData = {
    'activated': [],
    'desactivated': [],
    'expired': []
  };
  List<String> expireds = [];
  List<String> desactiveds = [];
  List<String> activeds = [];

  for (var i in data.keys) {
    for (var domain in data[i]) {
      await gettingDataDomain(domain).then((resp) {
        if (resp.contains('For Sale Domain:')) {
          print('$domain - expired');
          expireds.add('$domain - $resp');
        } else {
          switch (resp) {
            case 'expired':
              print('$domain - expired');
              expireds.add('$domain - $resp');
              break;

            case 'Service Unavailable':
              print('$domain - desactived');
              desactiveds.add('$domain - $resp');
              break;

            default:
              print('$domain - actived');
              activeds.add('$domain - $resp');
          }
        }
      });
    }
  }

  processedData['activated'] = activeds;
  processedData['desactivated'] = desactiveds;
  processedData['expired'] = expireds;

  writeFiles(processedData);
}

// Future<String> gettingDataDomain(domain) async {
Future<String> gettingDataDomain(String domain) async {
  String ret = "";
  try {
    final webScraper = WebScraper('https://$domain');
    if (await webScraper.loadWebPage('/')) {
      List<Map<String, dynamic>> elements =
          webScraper.getElement('title', ['']);
      ret = elements[0]['title'].toString();
    }
  } catch (e) {
    ret = "expired";
  }
  return ret;
}

void writeFiles(Map data) {
  var processedFiles = '${pathFiles}processedFiles';
  for (var key in data.keys) {
    String domainListAsString = "";
    int i = 0;
    for (var domain in data[key]) {
      domainListAsString += '#$i - $domain - $key\n';
      i++;
    }
    File('$processedFiles\\${key}_len_$i.txt')
        .writeAsString(domainListAsString);
  }
}
