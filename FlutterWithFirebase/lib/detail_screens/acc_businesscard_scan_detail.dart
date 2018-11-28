import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:mlkit/mlkit.dart';
import 'package:flutfire/utils/acc_app_constants.dart' as AppConstants;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutfire/utils/widget_utility.dart';
import 'package:flutfire/data/acc_businesscard_data_helper.dart';

class AccBusinessCardScanDetail extends StatefulWidget {
  final File _file;

  AccBusinessCardScanDetail(this._file);

  @override
  State<StatefulWidget> createState() {
    return _AccScanDetailState();
  }
}

class _AccScanDetailState extends State<AccBusinessCardScanDetail> {
  final myController = TextEditingController();
  FirebaseVisionTextDetector textDetector = FirebaseVisionTextDetector.instance;

  List<VisionText> _currentTextLabels = <VisionText>[];

  Stream sub;
  StreamSubscription<dynamic> subscription;

  @override
  void initState() {
    super.initState();
    sub = new Stream.empty();
    subscription = sub.listen((_) => _getImageSize)..onDone(analyzeLabels);
  }

  void analyzeLabels() async {
    try {
      var currentLabels;
      currentLabels = await textDetector.detectFromPath(widget._file.path);
      if (this.mounted) {
        setState(() {
          _currentTextLabels = currentLabels;
        });
      }
    } catch (e) {
      print("MyEx: " + e.toString());
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(AppConstants.BUSINESS_CARD_SCANNER_SCREEN_TITLE),
        ),
        body: Column(
          children: <Widget>[
            buildTextList(_currentTextLabels),
            TextField(
              controller: myController,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Please enter a name to save the business card'),
            ),
            RaisedButton(
                onPressed: () => AccBusinessCardDataHelper.saveBusinessCard(
                    myController.text, getStringArray()),
                color: Colors.green,
                textColor: Colors.white,
                shape: WidgetUtility.getShape(5.0),
                child: new Text("Save"))
          ],
        ));
  }

  Widget buildTextList(List<VisionText> texts) {
    if (texts.length == 0) {
      return Expanded(
          flex: 1,
          child: Center(
            child: Text('No text detected',
                style: Theme.of(context).textTheme.subhead),
          ));
    }
    return Expanded(
        flex: 1,
        child: Container(
          child: ListView.builder(
              padding: const EdgeInsets.all(1.0),
              itemCount: texts.length,
              itemBuilder: (context, i) {
                return _buildTextRow(texts[i].text);
              }),
        ));
  }

  Widget _buildTextRow(text) {
    return ListTile(
      title: Text(
        "$text",
      ),
      dense: true,
    );
  }

  getStringArray() {
    List<String> arr = <String>[];
    for (int i = 0; i < _currentTextLabels.length; i++) {
      arr.add(_currentTextLabels[i].text);
    }
    return arr;
  }

  Future<Size> _getImageSize(Image image) {
    Completer<Size> completer = Completer<Size>();
    image.image.resolve(ImageConfiguration()).addListener(
        (ImageInfo info, bool _) => completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble())));
    return completer.future;
  }
}
