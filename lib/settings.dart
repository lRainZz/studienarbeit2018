import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'globals.dart' as globals;

class SettingsView extends StatefulWidget {
  @override
  createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool _useImperialUnits;

  Widget _buildContent() {
    return new Column(
      children: <Widget>[
        new Padding(
          padding: new EdgeInsets.only(top: 10.0, bottom: 10.0),
          child:new SwitchListTile(
              value: _useImperialUnits,
              onChanged: (value) => _setUseImperial(value),
              title: new Text(
                  'Use imperial units',
                  style: new TextStyle(
                      color: Colors.black45,
                      fontSize: 20.0
                  )
              )
          ),
        ),
        new Expanded(
          child: new Padding(
              padding: new EdgeInsets.all(20.0),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Text(
                          'Weather data provided by',
                          style: new TextStyle(
                              color: Colors.black54
                          )
                      ),
                      new InkWell(
                        child: new Text(
                            ' apixu.com',
                            style: new TextStyle(
                                color: Colors.blueAccent
                            )
                        ),
                        onTap: () => launch('https://www.apixu.com/'),
                      )
                    ],
                  ),
                ],
              )
          ),
        ),
      ],
    );
  }

  _setUseImperial(bool value) {
    globals.useImperial = value;

    setState(() {
      _useImperialUnits = value;
    });

    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(
          content: new Text('Preferences updated'),
        )
    );
  }

  _goBack() {
    // update possible changed options
    globals.navRefresh = true;
    Navigator.of(context).pop();
  }

  SettingsViewState() {
    _useImperialUnits = globals.useImperial;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          backgroundColor: Colors.white,
          leading: new IconButton(
            icon: new Icon(
                Icons.arrow_back,
                color: Colors.black54
            ),
            onPressed: () => _goBack(),
          ),
          title: new Text(
            'Settings',
            style: new TextStyle(
                color: Colors.black54
            ),
          ),
        ),
        body: _buildContent()
    );
  }
}