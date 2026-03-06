import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:simple_live_core/src/common/convert_helper.dart';
import 'package:simple_live_core/src/common/http_client.dart';
import 'package:simple_live_core/src/danmaku/bilibili_danmaku.dart';
import 'package:simple_live_core/src/interface/live_danmaku.dart';
import 'package:simple_live_core/src/interface/live_site.dart';
import 'package:simple_live_core/src/model/live_anchor_item.dart';
import 'package:simple_live_core/src/model/live_category.dart';
import 'package:simple_live_core/src/model/live_message.dart';
import 'package:simple_live_core/src/model/live_play_url.dart';
import 'package:simple_live_core/src/model/live_room_item.dart';
import 'package:simple_live_core/src/model/live_search_result.dart';
import 'package:simple_live_core/src/model/live_room_detail.dart';
import 'package:simple_live_core/src/model/live_play_quality.dart';
import 'package:simple_live_core/src/model/live_category_result.dart';

class BiliBiliSite implements LiveSite {
  @override
  String id = "bilibili";

  @override
  String name = "哔哩哔哩直播";

  String cookie = "";
  int userId = 0;

  @override
  LiveDanmaku getDanmaku() => BiliBiliDanmaku();

  static const String kDefaultUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36 Edg/126.0.0.0";
  static const String kDefaultReferer = "https://live.bilibili.com/";

  String buvid3 = "";
  String buvid4 = "";
  String accessId = "";
  Future<Map<String, String>> getHeader() async {
    if (buvid3.isEmpty) {
      var buvidInfo = await getBuvid();
      buvid3 = buvidInfo["b_3"] ?? "";
      buvid4 = buvidInfo["b_4"] ?? "";
    }
    return cookie.isEmpty
        ? {
            "user-agent": kDefaultUserAgent,
            "referer": kDefaultReferer,
            "cookie": 'buvid3=$buvid3;buvid4=$buvid4;',
          }
        : {
            "cookie": cookie.contains("buvid3")
                ? cookie
                : "$cookie;buvid3=$buvid3;buvid4=$buvid4;",
            "user-agent": kDefaultUserAgent,
            "referer": kDefaultReferer,
          };
  }

  @override
  Future<List<LiveCategory>> getCategores() async {
    List<LiveCategory> categories = [];
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/room/v1/Area/getList",
      queryParameters: {"need_entrance": 1, "parent_id": 0},
      header: await getHeader(),
    );
    for (var item in result["data"]) {
      List<LiveSubCategory> subs = [];
      for (var subItem in item["list"]) {
        var subCategory = LiveSubCategory(
          id: subItem["id"].toString(),
          name: asT<String?>(subItem["name"]) ?? "",
          parentId: asT<String?>(subItem["parent_id"]) ?? "",
          pic: "${asT<String?>(subItem["pic"]) ?? ""}@100w.png",
        );
        subs.add(subCategory);
      }
      var category = LiveCategory(
        children: subs,
        id: item["id"].toString(),
        name: asT<String?>(item["name"]) ?? "",
      );
      categories.add(category);
    }
    return categories;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(
    LiveSubCategory category, {
    int page = 1,
  }) async {
    const baseUrl =
        "https://api.live.bilibili.com/xlive/web-interface/v1/second/getList";

    var url =
        "$baseUrl?platform=web&parent_area_id=${category.parentId}&area_id=${category.id}&sort_type=&page=$page&w_webid=${await getAccessId()}";

    var queryParams = await getWbiSign(url);

    var result = await HttpClient.instance.getJson(
      baseUrl,
      queryParameters: queryParams,
      header: await getHeader(),
    );

    var hasMore = result["data"]["has_more"] == 1;
    var items = <LiveRoomItem>[];
    for (var item in result["data"]["list"]) {
      var roomItem = LiveRoomItem(
        roomId: item["roomid"].toString(),
        title: item["title"].toString(),
        cover: "${item["cover"]}@400w.jpg",
        userName: item["uname"].toString(),
        online: int.tryParse(item["online"].toString()) ?? 0,
      );
      items.add(roomItem);
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({
    required LiveRoomDetail detail,
  }) async {
    List<LivePlayQuality> qualities = [];
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo",
      queryParameters: {
        "room_id": detail.roomId,
        "protocol": "0,1",
        "format": "0,1,2",
        "codec": "0,1",
        "platform": "web",
      },
      header: await getHeader(),
    );
    var qualitiesMap = <int, String>{};
    for (var item in result["data"]["playurl_info"]["playurl"]["g_qn_desc"]) {
      qualitiesMap[int.tryParse(item["qn"].toString()) ?? 0] = item["desc"]
          .toString();
    }

    for (var item
        in result["data"]["playurl_info"]["playurl"]["stream"][0]["format"][0]["codec"][0]["accept_qn"]) {
      var qualityItem = LivePlayQuality(
        quality: qualitiesMap[item] ?? "未知清晰度",
        data: item,
      );
      qualities.add(qualityItem);
    }
    return qualities;
  }

  @override
  Future<LivePlayUrl> getPlayUrls({
    required LiveRoomDetail detail,
    required LivePlayQuality quality,
  }) async {
    List<String> urls = [];
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo",
      queryParameters: {
        "room_id": detail.roomId,
        "protocol": "0,1",
        "format": "0,2",
        "codec": "0",
        "platform": "web",
        "qn": quality.data,
      },
      header: await getHeader(),
    );
    var streamList = result["data"]["playurl_info"]["playurl"]["stream"];
    for (var streamItem in streamList) {
      var formatList = streamItem["format"];
      for (var formatItem in formatList) {
        var codecList = formatItem["codec"];
        for (var codecItem in codecList) {
          var urlList = codecItem["url_info"];
          var baseUrl = codecItem["base_url"].toString();
          for (var urlItem in urlList) {
            urls.add("${urlItem["host"]}$baseUrl${urlItem["extra"]}");
          }
        }
      }
    }
    // 对链接进行排序，包含mcdn的在后
    urls.sort((a, b) {
      if (a.contains("mcdn")) {
        return 1;
      } else {
        return -1;
      }
    });
    return LivePlayUrl(
      urls: urls,
      headers: {
        "referer": "https://live.bilibili.com",
        "user-agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36 Edg/115.0.1901.188",
      },
    );
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
    const baseUrl =
        "https://api.live.bilibili.com/xlive/web-interface/v1/second/getListByArea";
    var url = "$baseUrl?platform=web&sort=online&page_size=30&page=$page";

    var queryParams = await getWbiSign(url);

    var result = await HttpClient.instance.getJson(
      baseUrl,
      queryParameters: queryParams,
      header: await getHeader(),
    );

    var hasMore = (result["data"]["list"] as List).isNotEmpty;
    var items = <LiveRoomItem>[];
    for (var item in result["data"]["list"]) {
      var roomItem = LiveRoomItem(
        roomId: item["roomid"].toString(),
        title: item["title"].toString(),
        cover: "${item["cover"]}@400w.jpg",
        userName: item["uname"].toString(),
        online: int.tryParse(item["online"].toString()) ?? 0,
      );
      items.add(roomItem);
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    var roomInfo = await getRoomInfo(roomId: roomId);
    var realRoomId = roomInfo["room_info"]["room_id"].toString();

    const danmuInfoBaseUrl =
        "https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo";
    var danmuInfoUrl = "$danmuInfoBaseUrl?id=$realRoomId";
    var queryParams = await getWbiSign(danmuInfoUrl);
    var roomDanmakuResult = await HttpClient.instance.getJson(
      danmuInfoBaseUrl,
      queryParameters: queryParams,
      header: await getHeader(),
    );
    final hostList = roomDanmakuResult["data"]["host_list"] as List;
    String serverHost = "broadcastlv.chat.bilibili.com";
    if (hostList.isNotEmpty) {
      final hostItem = hostList.first as Map;
      final host = hostItem["host"]?.toString() ?? serverHost;
      final wssPort = hostItem["wss_port"]?.toString();
      final port = hostItem["port"]?.toString();
      final portValue = (wssPort != null && wssPort.isNotEmpty)
          ? wssPort
          : port;
      serverHost = portValue != null && portValue.isNotEmpty
          ? "$host:$portValue"
          : host;
    }

    //var buvid = await getBuvid();
    // 从 roomInfo 中提取 live_start_time
    String? liveStartTime = roomInfo["room_info"]?["live_start_time"]
        ?.toString();

    // 计算开播时长并打印到控制台 (参考斗鱼的实现)
    if (liveStartTime != null &&
        liveStartTime.isNotEmpty &&
        liveStartTime != "0") {
      // 检查是否为0，0可能表示未开播或无此信息
      try {
        int startTimeStamp = int.parse(liveStartTime);
        int currentTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        int durationInSeconds = currentTimeStamp - startTimeStamp;

        int hours = durationInSeconds ~/ 3600;
        int minutes = (durationInSeconds % 3600) ~/ 60;
        int seconds = durationInSeconds % 60;

        String formattedDuration =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        print('Bilibili直播间 $roomId 开播时长: $formattedDuration');
      } catch (e) {
        print('计算 Bilibili 开播时长出错: $e');
      }
    }

    return LiveRoomDetail(
      roomId: realRoomId,
      title: roomInfo["room_info"]["title"].toString(),
      cover: roomInfo["room_info"]["cover"].toString(),
      userName: roomInfo["anchor_info"]["base_info"]["uname"].toString(),
      userAvatar: "${roomInfo["anchor_info"]["base_info"]["face"]}@100w.jpg",
      online: asT<int?>(roomInfo["room_info"]["online"]) ?? 0,
      status: (asT<int?>(roomInfo["room_info"]["live_status"]) ?? 0) == 1,
      url: "https://live.bilibili.com/$roomId",
      introduction: roomInfo["room_info"]["description"].toString(),
      notice: "",
      danmakuData: BiliBiliDanmakuArgs(
        roomId: int.tryParse(realRoomId) ?? 0,
        uid: userId,
        token: roomDanmakuResult["data"]["token"].toString(),
        serverHost: serverHost,
        buvid: buvid3,
        cookie: cookie,
      ),
      showTime: liveStartTime, // 将 liveStartTime 赋值给 showTime 字段
    );
  }

  Future<Map<String, dynamic>> getRoomInfo({required String roomId}) async {
    var url =
        "https://api.live.bilibili.com/xlive/web-room/v1/index/getInfoByRoom?room_id=$roomId";
    var queryParams = await getWbiSign(url);
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-room/v1/index/getInfoByRoom",
      queryParameters: queryParams,
      header: await getHeader(),
    );
    print("【B站接口返回】roomId=$roomId, result=$result");
    return result["data"];
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(
    String keyword, {
    int page = 1,
  }) async {
    var result = await HttpClient.instance.getJson(
      "https://api.bilibili.com/x/web-interface/search/type?context=&search_type=live&cover_type=user_cover",
      queryParameters: {
        "order": "",
        "keyword": keyword,
        "category_id": "",
        "__refresh__": "",
        "_extra": "",
        "highlight": 0,
        "single_column": 0,
        "page": page,
      },
      header: await getHeader(),
    );

    var items = <LiveRoomItem>[];
    for (var item in result["data"]["result"]["live_room"] ?? []) {
      var title = item["title"].toString();
      //移除title中的<em></em>标签
      title = title.replaceAll(RegExp(r"<.*?em.*?>"), "");
      var roomItem = LiveRoomItem(
        roomId: item["roomid"].toString(),
        title: title,
        cover: "https:${item["cover"]}@400w.jpg",
        userName: item["uname"].toString(),
        online: int.tryParse(item["online"].toString()) ?? 0,
      );
      items.add(roomItem);
    }
    return LiveSearchRoomResult(hasMore: items.length >= 40, items: items);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(
    String keyword, {
    int page = 1,
  }) async {
    var result = await HttpClient.instance.getJson(
      "https://api.bilibili.com/x/web-interface/search/type?context=&search_type=live_user&cover_type=user_cover",
      queryParameters: {
        "order": "",
        "keyword": keyword,
        "category_id": "",
        "__refresh__": "",
        "_extra": "",
        "highlight": 0,
        "single_column": 0,
        "page": page,
      },
      header: await getHeader(),
    );

    var items = <LiveAnchorItem>[];
    for (var item in result["data"]["result"] ?? []) {
      var uname = item["uname"].toString();
      //移除title中的<em></em>标签
      uname = uname.replaceAll(RegExp(r"<.*?em.*?>"), "");
      var anchorItem = LiveAnchorItem(
        roomId: item["roomid"].toString(),
        avatar: "https:${item["uface"]}@400w.jpg",
        userName: uname,
        liveStatus: item["is_live"],
      );
      items.add(anchorItem);
    }
    return LiveSearchAnchorResult(hasMore: items.length >= 40, items: items);
  }

  @override
  Future<bool> getLiveStatus({required String roomId}) async {
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/room/v1/Room/get_info",
      queryParameters: {"room_id": roomId},
      header: await getHeader(),
    );
    return (asT<int?>(result["data"]["live_status"]) ?? 0) == 1;
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({
    required String roomId,
  }) async {
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/av/v1/SuperChat/getMessageList",
      queryParameters: {"room_id": roomId},
      header: await getHeader(),
    );
    List<LiveSuperChatMessage> ls = [];
    for (var item in result["data"]?["list"] ?? []) {
      var message = LiveSuperChatMessage(
        backgroundBottomColor: item["background_bottom_color"].toString(),
        backgroundColor: item["background_color"].toString(),
        endTime: DateTime.fromMillisecondsSinceEpoch(item["end_time"] * 1000),
        face: "${item["user_info"]["face"]}@200w.jpg",
        message: item["message"].toString(),
        price: item["price"],
        startTime: DateTime.fromMillisecondsSinceEpoch(
          item["start_time"] * 1000,
        ),
        userName: item["user_info"]["uname"].toString(),
      );
      ls.add(message);
    }
    return ls;
  }

  /// 获取 buvid3 和 buvid4
  /// 返回buvid3和buvid4
  /// ``` json
  /// {
  ///   "b_3": "buvid3",
  ///   "b_4": "buvid4",
  /// }
  /// ```
  Future<Map> getBuvid() async {
    try {
      if (cookie.contains("buvid3")) {
        return {
          "b_3": RegExp(r"buvid3=(.*?);").firstMatch(cookie)?.group(1) ?? "",
          "b_4": RegExp(r"buvid4=(.*?);").firstMatch(cookie)?.group(1) ?? "",
        };
      }

      var result = await HttpClient.instance.getJson(
        "https://api.bilibili.com/x/frontend/finger/spi",
        queryParameters: {},
        header: {
          "user-agent": kDefaultUserAgent,
          "referer": kDefaultReferer,
          "cookie": cookie,
        },
      );
      return result["data"];
    } catch (e) {
      return {"b_3": "", "b_4": ""};
    }
  }

  static String kImgKey = '';
  static String kSubKey = '';
  static const List<int> mixinKeyEncTab = [
    46,
    47,
    18,
    2,
    53,
    8,
    23,
    32,
    15,
    50,
    10,
    31,
    58,
    3,
    45,
    35,
    27,
    43,
    5,
    49,
    33,
    9,
    42,
    19,
    29,
    28,
    14,
    39,
    12,
    38,
    41,
    13,
    37,
    48,
    7,
    16,
    24,
    55,
    40,
    61,
    26,
    17,
    0,
    1,
    60,
    51,
    30,
    4,
    22,
    25,
    54,
    21,
    56,
    59,
    6,
    63,
    57,
    62,
    11,
    36,
    20,
    34,
    44,
    52,
  ];
  Future<(String, String)> getWbiKeys() async {
    if (kImgKey.isNotEmpty && kSubKey.isNotEmpty) {
      return (kImgKey, kSubKey);
    }
    // 获取最新的 img_key 和 sub_key
    var resp = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/web-interface/nav',
      header: await getHeader(),
    );

    var imgUrl = resp["data"]["wbi_img"]["img_url"].toString();
    var subUrl = resp["data"]["wbi_img"]["sub_url"].toString();
    var imgKey = imgUrl.substring(imgUrl.lastIndexOf('/') + 1).split('.').first;
    var subKey = subUrl.substring(subUrl.lastIndexOf('/') + 1).split('.').first;

    kImgKey = imgKey;
    kSubKey = subKey;

    return (imgKey, subKey);
  }

  String getMixinKey(String origin) {
    // 对 imgKey 和 subKey 进行字符顺序打乱编码
    return mixinKeyEncTab.fold("", (s, i) => s + origin[i]).substring(0, 32);
  }

  Future<Map<String, String>> getWbiSign(String url) async {
    var (imgKey, subKey) = await getWbiKeys();

    // 为请求参数进行 wbi 签名
    var mixinKey = getMixinKey(imgKey + subKey);
    var currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var queryParams = Map<String, String>.from(Uri.parse(url).queryParameters);

    queryParams["wts"] = currentTime.toString(); // 添加 wts 字段

    //按照 key 重排参数
    Map<String, String> map = {};
    var sortedKeys = queryParams.keys.toList()..sort();
    for (var key in sortedKeys) {
      var value = queryParams[key]!;
      // 过滤 value 中的 "!'()*" 字符
      map[key] = value
          .toString()
          .split('')
          .where((c) => "!'()*".contains(c) == false)
          .join('');
    }

    var query = map.keys
        .map((key) => "$key=${Uri.encodeQueryComponent(map[key]!)}")
        .join("&");
    var wbiSign = md5.convert(utf8.encode("$query$mixinKey")).toString();
    queryParams["w_rid"] = wbiSign;
    return queryParams;
  }

  Future<String> getAccessId() async {
    if (accessId.isNotEmpty) {
      return accessId;
    }

    // 获取 access_id
    var resp = await HttpClient.instance.getText(
      "https://live.bilibili.com/lol",
      queryParameters: {},
      header: await getHeader(),
    );
    var id = RegExp(
      r'"access_id":"(.*?)"',
    ).firstMatch(resp)?.group(1)?.replaceAll("\\", "");
    accessId = id ?? "";
    return accessId;
  }

  /// 发送弹幕到 B 站直播间
  /// [roomId] 直播间真实 ID
  /// [msg] 弹幕内容
  /// [csrf] CSRF Token (bili_jct)
  Future<bool> sendDanmaku({
    required String roomId,
    required String msg,
    required String csrf,
  }) async {
    try {
      var headers = await getHeader();
      var formData = {
        'roomid': roomId,
        'msg': msg,
        'csrf': csrf,
        'csrf_token': csrf,
        'rnd': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
        'color': '16777215',
        'fontsize': '25',
        'mode': '1',
        'bubble': '0',
        'room_type': '0',
        'jumpfrom': '0',
        'reply_mid': '0',
        'reply_attr': '0',
        'replay_dmid': '0',
        'statistics': '{"appId":100,"platform":5}',
      };

      var result = await HttpClient.instance.postJson(
        "https://api.live.bilibili.com/msg/send",
        data: formData,
        header: headers,
        formUrlEncoded: true,
      );

      return result['code'] == 0;
    } catch (e) {
      print('发送弹幕失败: $e');
      return false;
    }
  }

  /// 发送表情包到 B 站直播间
  /// [roomId] 直播间真实 ID
  /// [msg] 表情包代码
  /// [csrf] CSRF Token (bili_jct)
  /// [emoticonOptions] 表情包选项
  Future<bool> sendEmotion({
    required String roomId,
    required String msg,
    required String csrf,
    Map<String, dynamic>? emoticonOptions,
  }) async {
    try {
      var headers = await getHeader();
      var formData = {
        'roomid': roomId,
        'msg': msg,
        'csrf': csrf,
        'csrf_token': csrf,
        'rnd': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
        'color': '16777215',
        'fontsize': '25',
        'mode': '1',
        'bubble': '0',
        'dm_type': '1',
        'emoticon_options': emoticonOptions ?? {},
        'data_extend': '{"trackid":"-99998"}',
      };

      var result = await HttpClient.instance.postJson(
        "https://api.live.bilibili.com/msg/send",
        data: formData,
        header: headers,
        formUrlEncoded: true,
      );

      return result['code'] == 0;
    } catch (e) {
      print('发送表情包失败: $e');
      return false;
    }
  }

  /// 获取直播间可用的表情包列表
  /// [platform] 平台类型，默认 web
  /// [roomId] 直播间 ID
  Future<dynamic> getEmoticons({
    String platform = 'pc', // 尝试使用 pc 平台
    required String roomId,
  }) async {
    try {
      var headers = await getHeader();
      
      // 尝试不同的平台参数
      List<String> platforms = ['pc', 'web', 'android', 'ios'];
      for (var plat in platforms) {
        print('尝试使用平台参数: $plat');
        
        // 构建 URL 并添加 WBI 签名
        var url = "https://api.live.bilibili.com/xlive/web-ucenter/v2/emoticon/GetEmoticons?platform=$plat&room_id=$roomId";
        var queryParams = await getWbiSign(url);
        
        var result = await HttpClient.instance.getJson(
          "https://api.live.bilibili.com/xlive/web-ucenter/v2/emoticon/GetEmoticons",
          queryParameters: queryParams,
          header: headers,
        );

        // 打印原始返回数据，以便调试
        print('表情包 API 返回数据 ($plat): $result');

        // 检查是否返回了表情包数据
        if (result is Map) {
          // 检查正确的数据结构（参考 BLSPAM 项目）
          if (result.containsKey('data')) {
            var data = result['data'];
            print('表情包 data 字段: $data');
            
            if (data is Map) {
              // 检查 BLSPAM 项目使用的数据结构
              if (data.containsKey('data')) {
                var emoticonPackages = data['data'];
                print('表情包 packages 字段: $emoticonPackages');
                
                if (emoticonPackages is List) {
                  print('表情包 packages 数量: ${emoticonPackages.length}');
                  
                  // 提取所有表情包
                  var allEmoticons = [];
                  for (var package in emoticonPackages) {
                    if (package is Map) {
                      print('表情包包: ${package['pkg_name']}');
                      if (package.containsKey('emoticons')) {
                        var packageEmoticons = package['emoticons'];
                        if (packageEmoticons is List) {
                          print('包内表情包数量: ${packageEmoticons.length}');
                          allEmoticons.addAll(packageEmoticons);
                        }
                      }
                    }
                  }
                  
                  print('总表情包数量: ${allEmoticons.length}');
                  if (allEmoticons.isNotEmpty) {
                    // 直接返回提取的表情包列表
                    return allEmoticons;
                  }
                }
              } else if (data.containsKey('emoticons')) {
                // 旧的数据结构
                var emoticons = data['emoticons'];
                if (emoticons is List && emoticons.isNotEmpty) {
                  return emoticons;
                }
              }
            }
          }
        }
      }

      // 如果所有平台都失败，尝试获取用户的默认表情包
      try {
        for (var plat in platforms) {
          print('尝试获取用户默认表情包，平台: $plat');
          
          // 构建 URL 并添加 WBI 签名
          var url = "https://api.live.bilibili.com/xlive/web-ucenter/v2/emoticon/GetEmoticons?platform=$plat&room_id=0";
          var queryParams = await getWbiSign(url);
          
          var userEmoticonsResult = await HttpClient.instance.getJson(
            "https://api.live.bilibili.com/xlive/web-ucenter/v2/emoticon/GetEmoticons",
            queryParameters: queryParams,
            header: headers,
          );

          // 打印原始返回数据，以便调试
          print('用户默认表情包 API 返回数据 ($plat): $userEmoticonsResult');

          if (userEmoticonsResult is Map) {
            if (userEmoticonsResult.containsKey('data')) {
              var data = userEmoticonsResult['data'];
              print('用户默认表情包 data 字段: $data');
              
              if (data is Map) {
                // 检查 BLSPAM 项目使用的数据结构
                if (data.containsKey('data')) {
                  var emoticonPackages = data['data'];
                  print('用户默认表情包 packages 字段: $emoticonPackages');
                  
                  if (emoticonPackages is List) {
                    print('用户默认表情包 packages 数量: ${emoticonPackages.length}');
                    
                    // 提取所有表情包
                    var allEmoticons = [];
                    for (var package in emoticonPackages) {
                      if (package is Map) {
                        print('用户默认表情包包: ${package['pkg_name']}');
                        if (package.containsKey('emoticons')) {
                          var packageEmoticons = package['emoticons'];
                          if (packageEmoticons is List) {
                            print('用户默认包内表情包数量: ${packageEmoticons.length}');
                            allEmoticons.addAll(packageEmoticons);
                          }
                        }
                      }
                    }
                    
                    print('用户默认总表情包数量: ${allEmoticons.length}');
                    if (allEmoticons.isNotEmpty) {
                      // 直接返回提取的表情包列表
                      return allEmoticons;
                    }
                  }
                } else if (data.containsKey('emoticons')) {
                  // 旧的数据结构
                  var emoticons = data['emoticons'];
                  if (emoticons is List && emoticons.isNotEmpty) {
                    return emoticons;
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('获取用户默认表情包失败: $e');
      }

      // 如果都没有表情包，返回一个空的表情包列表
      print('没有找到可用的表情包');
      return [];
    } catch (e) {
      print('获取表情包列表失败: $e');
      return null;
    }
  }
}
