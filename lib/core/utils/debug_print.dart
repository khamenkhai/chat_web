import 'package:flutter/foundation.dart';


void kCustomPrint(String message){
  if(kDebugMode){
    print(message);
  }
}