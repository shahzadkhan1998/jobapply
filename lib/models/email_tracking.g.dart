// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_tracking.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmailTrackingAdapter extends TypeAdapter<EmailTracking> {
  @override
  final int typeId = 3;

  @override
  EmailTracking read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmailTracking(
      id: fields[0] as String,
      recipient: fields[1] as String,
      subject: fields[2] as String,
      sentAt: fields[3] as DateTime,
      status: fields[4] as EmailStatus,
      repliedAt: fields[5] as DateTime?,
      replyContent: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EmailTracking obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.recipient)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.sentAt)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.repliedAt)
      ..writeByte(6)
      ..write(obj.replyContent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailTrackingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmailStatusAdapter extends TypeAdapter<EmailStatus> {
  @override
  final int typeId = 2;

  @override
  EmailStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EmailStatus.sent;
      case 1:
        return EmailStatus.delivered;
      case 2:
        return EmailStatus.read;
      case 3:
        return EmailStatus.replied;
      case 4:
        return EmailStatus.failed;
      default:
        return EmailStatus.sent;
    }
  }

  @override
  void write(BinaryWriter writer, EmailStatus obj) {
    switch (obj) {
      case EmailStatus.sent:
        writer.writeByte(0);
        break;
      case EmailStatus.delivered:
        writer.writeByte(1);
        break;
      case EmailStatus.read:
        writer.writeByte(2);
        break;
      case EmailStatus.replied:
        writer.writeByte(3);
        break;
      case EmailStatus.failed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
