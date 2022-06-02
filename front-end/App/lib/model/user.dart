class User {
  final String google_id;
  final String name;
  final String profile_image;
  final String about_me;
  final bool is_disabled;
  final bool is_moderator;

  User(this.google_id, this.name, this.profile_image, this.about_me,
      this.is_disabled, this.is_moderator);

  factory User.fromJson(dynamic json) {
    try {
      final google_id = json['googleID'] as String;
      final name = json['name'] as String;
      final profile_image = json['profileImage'] as String;
      final about_me = json['aboutMe'] as String;
      final is_disabled = json['isDisabled'] as bool;
      final is_moderator = json['isModerator'] as bool;

      return User(
          google_id, name, profile_image, about_me, is_disabled, is_moderator);
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  Map<String, dynamic> toJson() => {
        'googleID': google_id,
        'name': name,
        'profileImage': profile_image,
        'aboutMe': about_me,
        'isDisabled': is_disabled,
        'isModerator': is_moderator
      };
}
