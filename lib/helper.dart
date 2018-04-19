import 'package:flutter/material.dart';
import 'globals.dart' as globals;

// class for defining a new simple type
class CityData {
  final int    id;
  final String name;
  final int    zip;

  const CityData(
      this.id,
      this.name,
      this.zip
  );
}

int getNewId() {
  int id = globals.currentId;
  globals.currentId = id + 1;
  return id;
}