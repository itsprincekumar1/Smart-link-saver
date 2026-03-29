// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LinkModelAdapter extends TypeAdapter<LinkModel> {
  @override
  final int typeId = 0;

  @override
  LinkModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LinkModel(
      id: fields[0] as String,
      url: fields[1] as String,
      note: fields[2] as String,
      category: fields[3] as String,
      domain: fields[4] as String,
      folderId: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      isFromHistory: fields[7] as bool,
      subCategory: fields[8] as String,
      imageUrl: fields[9] as String?,
      isVisibleInHistory: fields[10] == null ? true : fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LinkModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.domain)
      ..writeByte(5)
      ..write(obj.folderId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isFromHistory)
      ..writeByte(8)
      ..write(obj.subCategory)
      ..writeByte(9)
      ..write(obj.imageUrl)
      ..writeByte(10)
      ..write(obj.isVisibleInHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
