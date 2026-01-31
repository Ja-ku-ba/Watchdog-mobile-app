class NotificationSettingsModel {
  bool notificationNewVideo;
  bool notificationIntruder;
  bool notificationFriend;

  NotificationSettingsModel({
    this.notificationNewVideo = false,
    this.notificationIntruder = false,
    this.notificationFriend = false,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      notificationNewVideo: json['notification_new_video'] ?? false,
      notificationIntruder: json['notification_intruder'] ?? false,
      notificationFriend: json['notification_friend'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_new_video': notificationNewVideo,
      'notification_intruder': notificationIntruder,
      'notification_friend': notificationFriend,
    };
  }
}