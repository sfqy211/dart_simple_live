
import 'package:tars_dart/tars/codec/tars_displayer.dart';
import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';
import 'package:tars_dart/tars/codec/tars_struct.dart';

import 'huya_user_id.dart';

class GetCdnTokenExReq extends TarsStruct {
  String sFlvUrl = ""; //tag 0
  String sStreamName = ""; //tag 1
  int iLoopTime = 0; //tag 2
  HuyaUserId tId = HuyaUserId(); //tag 3
  int iAppId = 66; //tag 4

  @override
  void readFrom(TarsInputStream input) {
    sFlvUrl = input.read(sFlvUrl, 0, false);
    sStreamName = input.read(sStreamName, 1, false);
    iLoopTime = input.read(iLoopTime, 2, false);
    tId = input.read(tId, 3, false);
    iAppId = input.read(iAppId, 4, false);
  }

  @override
  void writeTo(TarsOutputStream output) {
    output.write(sFlvUrl, 0);
    output.write(sStreamName, 1);
    output.write(iLoopTime, 2);
    output.write(tId, 3);
    output.write(iAppId, 4);
  }

  @override
  TarsStruct deepCopy() {
    return GetCdnTokenExReq()
      ..sFlvUrl = sFlvUrl
      ..sStreamName = sStreamName
      ..iLoopTime = iLoopTime
      ..tId = tId
      ..iAppId = iAppId;
  }

  @override
  displayAsString(StringBuffer sb, int level) {
    TarsDisplayer displayer = TarsDisplayer(sb, level: level);
    displayer.DisplayString(sFlvUrl, "sFlvUrl");
    displayer.DisplayString(sStreamName, "sStreamName");
    displayer.DisplayInt(iLoopTime, "iLoopTime");
    displayer.DisplayTarsStruct(tId, "tId");
    displayer.DisplayInt(iAppId, "iAppId");
  }
}
