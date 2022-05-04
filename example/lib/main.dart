import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:onetrust_publishers_native_cmp/onetrust_publishers_native_cmp.dart';
import 'package:onetrust_publishers_native_cmp_example/homePage.dart';

import 'debugMenu.dart';

void main() {
  runApp(const MaterialApp(title: "OneTrust Flutter Demo", home: HomePage()));
}
