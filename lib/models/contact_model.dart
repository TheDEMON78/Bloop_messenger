class ContactModel {
  final String uid;
  final String phone;
  final String displayName;
  final String? avatarUrl;

  const ContactModel({
    required this.uid,
    required this.phone,
    required this.displayName,
    this.avatarUrl,
  });

  factory ContactModel.fromMap(Map<String, dynamic> map) => ContactModel(
        uid: map['uid'] as String,
        phone: map['phone'] as String,
        displayName: map['displayName'] as String,
        avatarUrl: map['avatarUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'phone': phone,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
      };
}
