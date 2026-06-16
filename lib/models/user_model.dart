class UserModel {
  final String uid;
  final String phone;
  final String displayName;
  final String? avatarUrl;
  final String? status;
  final DateTime lastSeen;
  final bool isOnline;

  const UserModel({
    required this.uid,
    required this.phone,
    required this.displayName,
    this.avatarUrl,
    this.status,
    required this.lastSeen,
    this.isOnline = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] as String,
        phone: map['phone'] as String,
        displayName: map['displayName'] as String,
        avatarUrl: map['avatarUrl'] as String?,
        status: map['status'] as String?,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] as int? ?? 0),
        isOnline: map['isOnline'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'phone': phone,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'status': status,
        'lastSeen': lastSeen.millisecondsSinceEpoch,
        'isOnline': isOnline,
      };
}
