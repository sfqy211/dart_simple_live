import 'package:tars_dart/tars/codec/tars_displayer.dart';
import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';
import 'package:tars_dart/tars/codec/tars_struct.dart';

class GetCdnTokenExResp extends TarsStruct {
  String sFlvToken = ""; //tag 0
  int iExpireTime = 0; //tag 1

  @override
  void readFrom(TarsInputStream input) {
    sFlvToken = input.read(sFlvToken, 0, false);
    iExpireTime = input.read(iExpireTime, 1, false);
  }

  @override
  void writeTo(TarsOutputStream output) {
    output.write(sFlvToken, 0);
    output.write(iExpireTime, 1);
  }

  @override
  TarsStruct deepCopy() {
    return GetCdnTokenExResp()
      ..sFlvToken = sFlvToken
      ..iExpireTime = iExpireTime;
  }

  @override
  displayAsString(StringBuffer sb, int level) {
    TarsDisplayer displayer = TarsDisplayer(sb, level: level);
    displayer.DisplayString(sFlvToken, "sFlvToken");
    displayer.DisplayInt(iExpireTime, "iExpireTime");
  }
}
