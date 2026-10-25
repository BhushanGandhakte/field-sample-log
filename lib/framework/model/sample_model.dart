import 'sample_enums.dart';

class SampleModel {
  final int? id;
  final String siteName;
  final SampleType sampleType;
  final DateTime collectedAt;
  final double? depth;
  final double? ph;
  final String notes;
  final SampleStatus status;
  final String? receipt;

  const SampleModel({
    this.id,
    required this.siteName,
    required this.sampleType,
    required this.collectedAt,
    this.depth,
    this.ph,
    this.notes = '',
    this.status = SampleStatus.draft,
    this.receipt,
  });

  SampleModel copyWith({
    int? id,
    String? siteName,
    SampleType? sampleType,
    DateTime? collectedAt,
    double? depth,
    double? ph,
    String? notes,
    SampleStatus? status,
    String? receipt,
  }) {
    return SampleModel(
      id: id ?? this.id,
      siteName: siteName ?? this.siteName,
      sampleType: sampleType ?? this.sampleType,
      collectedAt: collectedAt ?? this.collectedAt,
      depth: depth ?? this.depth,
      ph: ph ?? this.ph,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      receipt: receipt ?? this.receipt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'site_name': siteName,
      'sample_type': sampleType.name,
      'collected_at': collectedAt.toIso8601String(),
      'depth': depth,
      'ph': ph,
      'notes': notes,
      'status': status.name,
      'receipt': receipt,
    };
  }

  factory SampleModel.fromMap(Map<String, Object?> map) {
    return SampleModel(
      id: map['id'] as int?,
      siteName: map['site_name'] as String,
      sampleType: SampleType.values.byName(map['sample_type'] as String),
      collectedAt: DateTime.parse(map['collected_at'] as String),
      depth: (map['depth'] as num?)?.toDouble(),
      ph: (map['ph'] as num?)?.toDouble(),
      notes: map['notes'] as String? ?? '',
      status: SampleStatus.values.byName(map['status'] as String),
      receipt: map['receipt'] as String?,
    );
  }
}
