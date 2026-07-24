import 'package:cloud_firestore/cloud_firestore.dart';

class StaffInvite {
  final String id;
  final String tenantId;
  final String email;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;
  final DateTime? usedAt;

  StaffInvite({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.inviteCode,
    required this.createdAt,
    required this.expiresAt,
    this.used = false,
    this.usedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'email': email,
      'inviteCode': inviteCode,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'used': used,
      'usedAt': usedAt,
    };
  }

  factory StaffInvite.fromMap(Map<String, dynamic> map, String id) {
    return StaffInvite(
      id: id,
      tenantId: map['tenantId'] as String,
      email: map['email'] as String,
      inviteCode: map['inviteCode'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      used: map['used'] as bool? ?? false,
      usedAt: map['usedAt'] != null
          ? (map['usedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory StaffInvite.fromSnapshot(DocumentSnapshot doc) {
    return StaffInvite.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
