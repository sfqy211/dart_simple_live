import 'package:tars_dart/tars/codec/tars_displayer.dart';
import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';
import 'package:tars_dart/tars/codec/tars_struct.dart';

class HuyaUserId extends TarsStruct {
  int lUid = 0;
  String sGuid = "";
  String sToken = "";
  String sHuYaUA = "";
  String sCookie = "";
  int iTokenType = 0;
  String sDeviceInfo = "";
  String sQIMEI = "";

  @override
  void readFrom(TarsInputStream input) {
    lUid = input.read(lUid, 0, false);
    sGuid = input.read(sGuid, 1, false);
    sToken = input.read(sToken, 2, false);
    sHuYaUA = input.read(sHuYaUA, 3, false);
    sCookie = input.read(sCookie, 4, false);
    iTokenType = input.read(iTokenType, 5, false);
    sDeviceInfo = input.read(sDeviceInfo, 6, false);
    sQIMEI = input.read(sQIMEI, 7, false);
  }

  @override
  void writeTo(TarsOutputStream output) {
    output.write(lUid, 0);
    output.write(sGuid, 1);
    output.write(sToken, 2);
    output.write(sHuYaUA, 3);
    output.write(sCookie, 4);
    output.write(iTokenType, 5);
    output.write(sDeviceInfo, 6);
    output.write(sQIMEI, 7);
  }

  @override
  Object deepCopy() {
    return HuyaUserId()
      ..lUid = lUid
      ..sGuid = sGuid
      ..sToken = sToken
      ..sHuYaUA = sHuYaUA
      ..sCookie = sCookie
      ..iTokenType = iTokenType
      ..sDeviceInfo = sDeviceInfo
      ..sQIMEI = sQIMEI;
  }

  @override
  void displayAsString(StringBuffer sb, int level) {
    TarsDisplayer displayer = TarsDisplayer(sb, level: level);
    displayer.DisplayInt(lUid, "lUid");
    displayer.DisplayString(sGuid, "sGuid");
    displayer.DisplayString(sToken, "sToken");
    displayer.DisplayString(sHuYaUA, "sHuYaUA");
    displayer.DisplayString(sCookie, "sCookie");
    displayer.DisplayInt(iTokenType, "iTokenType");
    displayer.DisplayString(sDeviceInfo, "sDeviceInfo");
    displayer.DisplayString(sQIMEI, "sQIMEI");
  }
}
