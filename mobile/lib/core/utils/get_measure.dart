extension GetMeasure on int{

  String getMeasure(){
    switch(this){
      case 0: return "kg";
      case 1: return "dona";
      case 2: return "l";
      case 3: return "paket";
      default: return "";
    }
  }

}
