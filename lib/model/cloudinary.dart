import 'package:firebase_auth/firebase_auth.dart';

class CloudinaryConfig {
  final String cloudName;
  final String apiKey;
  final String apiSecret;
  final String uploadPreset;
  final User user;

  CloudinaryConfig({
    required this.cloudName,
    required this.apiKey,
    required this.apiSecret,
    required this.uploadPreset,
    required this.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'cloud_name': cloudName,
      'api_key': apiKey,
      'api_secret': apiSecret,
      'upload_preset': uploadPreset,
      'user_id': user.uid,
    };
  }
}

class CloudinaryImage {
  final String publicId;
  final int version;
  final String signature;
  final int width;
  final int height;
  final String format;
  final String resourceType;
  final String createdAt;
  final List<dynamic> tags;
  final int bytes;
  final String type;
  final String etag;
  final bool placeholder;
  final String url;
  final String secureUrl;

  CloudinaryImage({
    required this.publicId,
    required this.version,
    required this.signature,
    required this.width,
    required this.height,
    required this.format,
    required this.resourceType,
    required this.createdAt,
    required this.tags,
    required this.bytes,
    required this.type,
    required this.etag,
    required this.placeholder,
    required this.url,
    required this.secureUrl,
  });

  factory CloudinaryImage.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw Exception('Cannot create CloudinaryImage from null JSON');
    }

    return CloudinaryImage(
      publicId: json['public_id'] as String,
      version: json['version'] as int,
      signature: json['signature'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      format: json['format'] as String,
      resourceType: json['resource_type'] as String,
      createdAt: json['created_at'] as String,
      tags: json['tags'] as List<dynamic>,
      bytes: json['bytes'] as int,
      type: json['type'] as String,
      etag: json['etag'] as String,
      placeholder: json['placeholder'] as bool,
      url: json['url'] as String,
      secureUrl: json['secure_url'] as String,
    );
  }
}