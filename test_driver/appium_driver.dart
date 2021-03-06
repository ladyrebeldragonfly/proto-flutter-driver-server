import 'dart:io';
import 'dart:convert';

import 'package:flutter_driver/flutter_driver.dart';

class AppiumDriver {
  FlutterDriver flutterDriver;
  HttpServer server;

  // The AppiumDriver must handle multiple Element.
  // the hash? should be used for element_id as the return value.
  //
  Element element;

  Future<void> start() async {
    server = await _setupServer();
    await _setupFlutter();

    await for (var request in server) {
      final path = request.uri.toString();

      if (path == '/hub/wd/element') {
        // dummy
        element = findElementByText('You have pushed the button this many times:');
        returnResponse(request.response, json.encode({'value': true}));
      } else if (path == '/hub/wd/element/button') {
        // dummy
        element = findElementByAccessibilityId('add the number');
        returnResponse(request.response, json.encode({'value': true}));
      } else if (path == '/hub/wd/element/text') {
        // dummy
        var text = element != null ? await element.text() : '';


        returnResponse(request.response, json.encode({'value': text}));
      } else if (path == '/hub/wd/element/semanticId') {
        // dummy
        var text = element != null ? await element.semanticId() : '';

        returnResponse(request.response, json.encode({'value': text}));
      } else if (path == '/hub/wd/element/click') {
        // dummy
        if (element.finder != null) {
          await flutterDriver.tap(element.finder);
          returnResponse(request.response, json.encode({'value': true}));
        } else {
          returnResponse(request.response, json.encode({'value': false}));
        }
      } else if (path == '/hub/wd/source') {
        var renderTree = await flutterDriver.getRenderTree();
        returnResponse(request.response, renderTree.tree);
      } else if (path == '/hub/wd/screenshot') {
        var data = await flutterDriver.screenshot();
        var screenshot = new File('screenshot.png');
        await screenshot.writeAsBytes(data);
        returnResponse(request.response, json.encode({'value': 'screenshot.png'}));
      } else {
        returnResponse(request.response, '{"value": false,'
            '"error": "No matched value",'
            '"message": "no url ${request.uri}"}');
      }
    }
  }

  /// Returns a response to the response
  void returnResponse(HttpResponse response, String message) {
    response.headers.contentType
      = new ContentType('application', 'json', charset: 'utf-8');

    response.write(message);
    response.close();
  }

  Future<HttpServer> _setupServer() async {
    return await HttpServer.bind('localhost', 8080);
  }

  Future<void> _setupFlutter() async {
    flutterDriver = await FlutterDriver.connect();

    flutterDriver.setSemantics(true);
    flutterDriver.checkHealth();
  }

  Future<void> close() async {
    if (flutterDriver != null) {
      await flutterDriver.close();
    }
  }

  Element findElementByText(String text) {
    return Element(flutterDriver, find.text(text));
  }

  Element findElementByAccessibilityId(String text) {
    return Element(flutterDriver, find.bySemanticsLabel(text));
  }
}

class Element {
  SerializableFinder finder;
  FlutterDriver driver;

  Element(FlutterDriver driver, SerializableFinder finder) {
    this.driver = driver;
    this.finder = finder;
  }

  Future<String> text() async {
    if (driver != null && finder != null) {
      return await driver.getText(finder);
    }
    return '';
  }

  Future<int> semanticId() async {
    if (driver != null && finder != null) {
      return await driver.getSemanticsId(finder);
    }
    return -1;
  }
}