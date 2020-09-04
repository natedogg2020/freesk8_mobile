
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:freesk8_mobile/globalUtilities.dart';

import 'package:multiselect_formfield/multiselect_formfield.dart';

class RobogotchiConfiguration {
  int logAutoStopIdleTime;
  double logAutoStopLowVoltage;
  double logAutoStartDutyCycle;
  int logIntervalHz;
  int multiESCMode;
  List<int> multiESCIDs;
  int gpsBaudRate;
  int cfgVersion;
  RobogotchiConfiguration({
    this.logAutoStopIdleTime,
    this.logAutoStopLowVoltage,
    this.logAutoStartDutyCycle,
    this.logIntervalHz,
    this.multiESCMode,
    this.multiESCIDs,
    this.gpsBaudRate,
    this.cfgVersion
  });
}

class RobogotchiCfgEditorArguments {
  final BluetoothCharacteristic txLoggerCharacteristic;
  final RobogotchiConfiguration currentConfiguration;
  final List<int> discoveredCANDevices;
  RobogotchiCfgEditorArguments({this.txLoggerCharacteristic, this.currentConfiguration, this.discoveredCANDevices});
}

class ListItem {
  int value;
  String name;

  ListItem(this.value, this.name);
}

class RobogotchiCfgEditor extends StatefulWidget {
  @override
  RobogotchiCfgEditorState createState() => RobogotchiCfgEditorState();

  static const String routeName = "/gotchicfgedit";
}


class RobogotchiCfgEditorState extends State<RobogotchiCfgEditor> {

  List<ListItem> _dropdownItems = [
    ListItem(1290240, "4800 baud"),
    ListItem(2576384, "9600 baud"),
    ListItem(5152768, "19200 baud"),
    ListItem(10289152,"38400 baud"),
    ListItem(15400960,"57600 baud"),
    ListItem(30801920,"115200 baud"),
    ListItem(61865984,"230400 baud"),
  ];

  List<DropdownMenuItem<ListItem>> _dropdownMenuItems;
  ListItem _selectedItem;

  List _escCANIDsSelected;
  List _escCANIDs = [];

  bool _multiESCMode;
  bool _multiESCModeQuad;
  TextEditingController tecLogAutoStopIdleTime = TextEditingController();
  TextEditingController tecLogAutoStopLowVoltage = TextEditingController();
  TextEditingController tecLogAutoStartDutyCycle = TextEditingController();

  List<DropdownMenuItem<ListItem>> buildDropDownMenuItems(List listItems) {
    List<DropdownMenuItem<ListItem>> items = List();
    for (ListItem listItem in listItems) {
      items.add(
        DropdownMenuItem(
          child: Text(listItem.name),
          value: listItem,
        ),
      );
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _dropdownMenuItems = buildDropDownMenuItems(_dropdownItems);
  }

  @override
  void dispose() {
    _selectedItem = null;
    tecLogAutoStopIdleTime.dispose();
    tecLogAutoStopLowVoltage.dispose();
    tecLogAutoStartDutyCycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building RobogotchiCfgEditor");

    // Check for valid arguments while building this widget
    RobogotchiCfgEditorArguments myArguments = ModalRoute.of(context).settings.arguments;
    if(myArguments == null){
      return Container(child:Text("No arguments. BUG BUG."));
    }
    if (_multiESCMode == null) {
      // Assign value received from gotchi
      _multiESCMode = myArguments.currentConfiguration.multiESCMode == 2 || myArguments.currentConfiguration.multiESCMode == 4 ? true : false;
    }
    if (_multiESCModeQuad == null) {
      _multiESCModeQuad = myArguments.currentConfiguration.multiESCMode == 4;
    }
    if (myArguments.discoveredCANDevices.length > 0) {
      _escCANIDs.clear();
      for (int i=0; i<myArguments.discoveredCANDevices.length; ++i) {
        _escCANIDs.add({
          "display": "ID ${myArguments.discoveredCANDevices[i]}",
          "value": "${myArguments.discoveredCANDevices[i]}",
        });
      }
    }
    //TODO: Select currently configured ESC CAN IDs; causes MultiSelect to break
    //TODO: Replace MultiSelect with a better solution
    if (_escCANIDsSelected == null) {
      //_escCANIDsSelected = new List();
      myArguments.currentConfiguration.multiESCIDs.forEach((element) {
        if (element != 0) {
          //print("Adding user selected CAN ID: $element");
          //_escCANIDsSelected.add(element);
        }
      });
    }
    // Select GPS Baud
    if (_selectedItem == null) {
      _dropdownItems.forEach((item) {
        if (item.value == myArguments.currentConfiguration.gpsBaudRate) {
          _selectedItem = item;
        }
      });
    }



    // Add listeners to text editing controllers for value validation
    tecLogAutoStopIdleTime.addListener(() {
      myArguments.currentConfiguration.logAutoStopIdleTime = int.tryParse(tecLogAutoStopIdleTime.text).abs();
      if (myArguments.currentConfiguration.logAutoStopIdleTime > 65534) {
        setState(() {
          myArguments.currentConfiguration.logAutoStopIdleTime = 65534;
        });
      }
    });
    tecLogAutoStopLowVoltage.addListener(() {
      myArguments.currentConfiguration.logAutoStopLowVoltage = double.tryParse(tecLogAutoStopLowVoltage.text).abs();
      if (myArguments.currentConfiguration.logAutoStopLowVoltage > 128.0) {
        setState(() {
          myArguments.currentConfiguration.logAutoStopLowVoltage = 128.0;
        });
      }
    });
    // Set text editing controller values to arguments received
    tecLogAutoStopIdleTime.text = myArguments.currentConfiguration.logAutoStopIdleTime.toString();
    tecLogAutoStopLowVoltage.text = myArguments.currentConfiguration.logAutoStopLowVoltage.toString();


    return Scaffold(
        appBar: AppBar(
          title: Row(children: <Widget>[
            Icon( Icons.perm_data_setting,
              size: 35.0,
              color: Theme.of(context).accentColor,
            ),
            Text("Config Editor"),
          ],),
        ),
        body: GestureDetector(
            onTap: () {
              // Hide the keyboard
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: ListView(
              padding: EdgeInsets.all(10),
              children: <Widget>[
                Icon(
                  Icons.settings,
                  size: 60.0,
                  color: Colors.blue,
                ),

                TextField(
                  controller: tecLogAutoStopIdleTime,
                  decoration: new InputDecoration(labelText: "Log Auto Stop/Idle Board Timeout (Seconds)"),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    WhitelistingTextInputFormatter.digitsOnly
                  ]
                ),
                TextField(
                  controller: tecLogAutoStopLowVoltage,
                  decoration: new InputDecoration(labelText: "Log Auto Stop Low Voltage Threshold (Volts)"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    WhitelistingTextInputFormatter(RegExp(r'^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'))
                  ]
                ),


                Divider(thickness: 3),
                Text("Log Auto Start Sensitivity (Duty Cycle ${myArguments.currentConfiguration.logAutoStartDutyCycle})"),
                Slider(
                  onChanged: (newValue){ setState(() {
                    myArguments.currentConfiguration.logAutoStartDutyCycle = doublePrecision(0.2 - newValue, 2);
                  }); },
                  value: 0.2 - myArguments.currentConfiguration.logAutoStartDutyCycle,
                  min: 0.01,
                  max: 0.19,
                ),


                Divider(thickness: 3),
                Text("Log Entries per Second (${myArguments.currentConfiguration.logIntervalHz}Hz)"),
                Slider(
                  onChanged: (newValue){ setState(() {
                    myArguments.currentConfiguration.logIntervalHz = newValue.toInt();
                  }); },
                  value: myArguments.currentConfiguration.logIntervalHz.toDouble(),
                  min: 1,
                  max: 5,
                ),


                Divider(thickness: 3),
                Text("GPS Baud Rate"),
                Center(child:
                  DropdownButton<ListItem>(
                    value: _selectedItem,
                    items: _dropdownMenuItems,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedItem = newValue;
                        myArguments.currentConfiguration.gpsBaudRate = newValue.value;
                      });
                    },
                  )
                ),


                Divider(thickness: 3),
                SwitchListTile(
                  title: Text("Multiple ESC Mode"),
                  value: _multiESCMode,
                  onChanged: (bool newValue) { setState((){ _multiESCMode = newValue;}); },
                  secondary: const Icon(Icons.all_out),
                ),

                _multiESCMode ? SwitchListTile(
                  title: Text(_multiESCModeQuad ? "Quad ESC Mode" : "Dual ESC Mode"),
                  value: _multiESCModeQuad,
                  onChanged: (bool newValue) { setState((){ _multiESCModeQuad = newValue;}); },
                  secondary: _multiESCModeQuad ? const Icon(Icons.looks_4) : const Icon(Icons.looks_two),
                ) : Container(),

                _multiESCMode ? MultiSelectFormField(
                  autovalidate: false,
                  titleText: _multiESCModeQuad ? "Select CAN IDs" : "Select CAN ID",
                  validator: (value) {
                    if (value == null || value.length != (_multiESCModeQuad ? 3 : 1)) {
                      if(_multiESCModeQuad) {
                        return "Please select 3 ESC CAN IDs";
                      } else {
                        return "Please select 1 ESC CAN ID";
                      }
                    }
                    return null;
                  },
                  dataSource: _escCANIDs,
                  textField: 'display',
                  valueField: 'value',
                  okButtonLabel: 'OK',
                  cancelButtonLabel: 'CANCEL',
                  // required: true,
                  hintText: _multiESCModeQuad ? "Select 3 ESC CAN IDs" : "Select 1 ESC CAN ID",
                  initialValue: _escCANIDsSelected,
                  onSaved: (value) {
                    if (value == null) return;
                    setState(() {
                      _escCANIDsSelected = value;
                    });
                  },
                ) : Container(),


                Divider(thickness: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(child:
                    Row(mainAxisAlignment: MainAxisAlignment.center , children: <Widget>[Icon(Icons.cancel),Text("Cancel"),],),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }),

                    SizedBox(width: 10,),
                    RaisedButton(child:
                    Row(mainAxisAlignment: MainAxisAlignment.center , children: <Widget>[Text("Save"),Icon(Icons.save),],),
                        onPressed: () async {
                          // Validate user input
                          if (_multiESCMode && _multiESCModeQuad && _escCANIDsSelected?.length != 3) {
                            genericAlert(context, "CAN IDs required", Text("Please select 3 CAN IDs before saving"), "OK");
                            return;
                          }
                          if (_multiESCMode && !_multiESCModeQuad && _escCANIDsSelected?.length != 1) {
                            genericAlert(context, "CAN ID required", Text("Please select 1 CAN ID before saving"), "OK");
                            return;
                          }

                          // Convert settings to robogotchi command
                          int multiESCMode = 0;
                          if (_multiESCMode && _multiESCModeQuad) {
                            multiESCMode = 4;
                          } else if (_multiESCMode) {
                            multiESCMode = 2;
                          }
                          String newConfigCMD = "setcfg,${myArguments.currentConfiguration.logAutoStopIdleTime}"
                              ",${myArguments.currentConfiguration.logAutoStopLowVoltage}"
                              ",${myArguments.currentConfiguration.logAutoStartDutyCycle}"
                              ",${myArguments.currentConfiguration.logIntervalHz}"
                              ",$multiESCMode"
                              ",${_escCANIDsSelected != null && _escCANIDsSelected.length > 0 ? _escCANIDsSelected[0] : 0}"
                              ",${_escCANIDsSelected != null && _escCANIDsSelected.length > 1 ? _escCANIDsSelected[1] : 0}"
                              ",${_escCANIDsSelected != null && _escCANIDsSelected.length > 2 ? _escCANIDsSelected[2] : 0}"
                              ",0"
                              ",${myArguments.currentConfiguration.gpsBaudRate}"
                              ",${myArguments.currentConfiguration.cfgVersion}~";

                          // Save
                          print("Sending $newConfigCMD");
                          await myArguments.txLoggerCharacteristic.write(utf8.encode(newConfigCMD)).whenComplete((){
                            // Pop away the config page
                            Navigator.of(context).pop();
                          });
                        })
                  ],)
              ],
            )
        )
    );
  }
}