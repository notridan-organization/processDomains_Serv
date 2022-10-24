import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:console_bars/console_bars.dart';
import 'package:web_scraper/web_scraper.dart';

var pathFiles = "${Directory.current.path}\\domains\\";

void start() {
  sleep(Duration(seconds: 5));
  readData();
}

void readData() async {
  for (var i = 1; i <= 4; i++) {
    var localFile = "${pathFiles}serv_$i.txt";
    var fileData = File(localFile);
    Stream<String> lines =
        fileData.openRead().transform(utf8.decoder).transform(LineSplitter());

    String server = "";
    List<String> domainsDataList = [];
    await for (var line in lines) {
      if (line.contains('server-')) {
        server = line;
      } else {
        domainsDataList.add(line);
      }
    }
    generateDataFileProcessed(domainsDataList, server);
  }
}

void generateDataFileProcessed(List data, String server) async {
  Map<String, List> processedData = {
    'activated': [],
    'desactivated': [],
    'expired': []
  };
  List<String> expireds = [];
  List<String> desactiveds = [];
  List<String> activeds = [];
  var progressBar = FillingBar(total: data.length, desc: server, percentage: true);

  for (var domain in data) {
    await gettingDataDomain(domain).then((resp) {
      progressBar.increment();
      if (resp.contains('For Sale Domain:')) {
        expireds.add('$domain - $resp');
      } else {
        switch (resp) {
          case 'expired':
            expireds.add('$domain - $resp');
            break;

          case 'Service Unavailable':
            desactiveds.add('$domain - $resp');
            break;

          case 'DESATIVADO':
            desactiveds.add('$domain - $resp');
            break;

          default:
            activeds.add('$domain - $resp');
        }
      }
    });
  }

  processedData['activated'] = activeds;
  processedData['desactivated'] = desactiveds;
  processedData['expired'] = expireds;

  writeFiles(server, processedData);
}

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

void writeFiles(String server, Map data) {
  var processedFiles = '${pathFiles}processedFiles';
  for (var key in data.keys) {
    String domainListAsString =
        "#COUNT - DOMAIN - TITLE DOAMIN - STATE | SERVER\n\n";
    int i = 0;
    for (var domain in data[key]) {
      domainListAsString += '#$i - $domain - $key\n';
      i++;
    }
    File('$processedFiles\\$server\\${key}_len_$i.txt')
        .writeAsString(domainListAsString);
  }
}
