import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class LinkedAccount extends HiveObject {
  @HiveField(0)
  final String email;
  @HiveField(1)
  final String displayName;
  @HiveField(2)
  final String? photoUrl;
  @HiveField(3)
  final bool isActive;

  LinkedAccount({
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isActive = true,
  });
}

class LinkedAccountAdapter extends TypeAdapter<LinkedAccount> {
  @override
  final int typeId = 2;

  @override
  LinkedAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LinkedAccount(
      email: fields[0] as String,
      displayName: fields[1] as String,
      photoUrl: fields[2] as String?,
      isActive: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LinkedAccount obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.photoUrl)
      ..writeByte(3)
      ..write(obj.isActive);
  }
}
