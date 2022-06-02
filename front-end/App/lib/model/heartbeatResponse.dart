class HeartbeatResponse {
  final String google_id;
  final bool is_moderator;

  HeartbeatResponse(this.google_id, this.is_moderator);

  factory HeartbeatResponse.fromJson(dynamic json) {
    try {
      final google_id = json['google_id'] as String;
      final is_moderator = json['moderator_status'] as bool;

      return HeartbeatResponse(
          google_id, is_moderator);
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }
}
