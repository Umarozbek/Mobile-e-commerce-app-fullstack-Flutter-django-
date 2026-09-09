
import 'package:flutter/cupertino.dart';

double dWith(BuildContext context){
  double dWith=0;
  dWith=MediaQuery.sizeOf(context).width;
  return dWith;
}





double dHeight(BuildContext context){
  double dHeight=0;
  dHeight=MediaQuery.sizeOf(context).height;
  return dHeight;
}