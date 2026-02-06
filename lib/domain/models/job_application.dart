import 'package:hive/hive.dart';

@HiveType(typeId: 0)
enum ApplicationStatus {
  @HiveField(0) applied,
  @HiveField(1) underReview,
  @HiveField(2) interview,
  @HiveField(3) assessment,
  @HiveField(4) selected,
  @HiveField(5) rejected,
  @HiveField(6) personal,
  @HiveField(7) expired,
}

@HiveType(typeId: 4)
enum ApplicationPriority {
  @HiveField(0) low,
  @HiveField(1) medium,
  @HiveField(2) high,
  @HiveField(3) urgent,
}

@HiveType(typeId: 3)
class ApplicationEvent extends HiveObject {
  @HiveField(0) final DateTime date;
  @HiveField(1) final String title;
  @HiveField(2) final String? description;
  ApplicationEvent({required this.date, required this.title, this.description});
}

@HiveType(typeId: 1)
class JobApplication extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String companyName;
  @HiveField(2) final String role;
  @HiveField(3) final String jobType; 
  @HiveField(4) final DateTime dateApplied;
  @HiveField(5) final ApplicationStatus status;
  @HiveField(6) final DateTime lastResponseDate;
  @HiveField(7) final String accountEmail;
  @HiveField(8) final String? notes;
  @HiveField(9) final String? gmailMessageId;
  @HiveField(10) final String? location;
  @HiveField(11) final String? salary;
  @HiveField(12) final List<ApplicationEvent>? timeline;
  @HiveField(13) final bool isPersonal;
  @HiveField(14) final ApplicationPriority priority;

  JobApplication({
    required this.id,
    required this.companyName,
    required this.role,
    required this.jobType,
    required this.dateApplied,
    required this.status,
    required this.lastResponseDate,
    required this.accountEmail,
    this.notes,
    this.gmailMessageId,
    this.location,
    this.salary,
    this.timeline,
    this.isPersonal = false,
    this.priority = ApplicationPriority.medium,
  });
}

class JobApplicationAdapter extends TypeAdapter<JobApplication> {
  @override final int typeId = 1;
  @override
  JobApplication read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (int i = 0, len = reader.readByte(); i < len; i++) reader.readByte(): reader.read(),
    };
    return JobApplication(
      id: fields[0] as String,
      companyName: fields[1] as String,
      role: fields[2] as String,
      jobType: fields[3] as String,
      dateApplied: fields[4] as DateTime,
      status: fields[5] as ApplicationStatus,
      lastResponseDate: fields[6] as DateTime,
      accountEmail: fields[7] as String,
      notes: fields[8] as String?,
      gmailMessageId: fields[9] as String?,
      location: fields[10] as String?,
      salary: fields[11] as String?,
      timeline: (fields[12] as List?)?.cast<ApplicationEvent>(),
      isPersonal: fields[13] as bool? ?? false,
      priority: fields[14] as ApplicationPriority? ?? ApplicationPriority.medium,
    );
  }
  @override
  void write(BinaryWriter writer, JobApplication obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.companyName)
      ..writeByte(2)..write(obj.role)
      ..writeByte(3)..write(obj.jobType)
      ..writeByte(4)..write(obj.dateApplied)
      ..writeByte(5)..write(obj.status)
      ..writeByte(6)..write(obj.lastResponseDate)
      ..writeByte(7)..write(obj.accountEmail)
      ..writeByte(8)..write(obj.notes)
      ..writeByte(9)..write(obj.gmailMessageId)
      ..writeByte(10)..write(obj.location)
      ..writeByte(11)..write(obj.salary)
      ..writeByte(12)..write(obj.timeline)
      ..writeByte(13)..write(obj.isPersonal)
      ..writeByte(14)..write(obj.priority);
  }
}

class ApplicationStatusAdapter extends TypeAdapter<ApplicationStatus> {
  @override final int typeId = 0;
  @override ApplicationStatus read(BinaryReader reader) => ApplicationStatus.values[reader.readByte()];
  @override void write(BinaryWriter writer, ApplicationStatus obj) => writer.writeByte(obj.index);
}

class ApplicationPriorityAdapter extends TypeAdapter<ApplicationPriority> {
  @override final int typeId = 4;
  @override ApplicationPriority read(BinaryReader reader) => ApplicationPriority.values[reader.readByte()];
  @override void write(BinaryWriter writer, ApplicationPriority obj) => writer.writeByte(obj.index);
}

class ApplicationEventAdapter extends TypeAdapter<ApplicationEvent> {
  @override final int typeId = 3;
  @override
  ApplicationEvent read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (int i = 0, len = reader.readByte(); i < len; i++) reader.readByte(): reader.read(),
    };
    return ApplicationEvent(
      date: fields[0] as DateTime,
      title: fields[1] as String,
      description: fields[2] as String?,
    );
  }
  @override
  void write(BinaryWriter writer, ApplicationEvent obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)..write(obj.date)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.description);
  }
}
