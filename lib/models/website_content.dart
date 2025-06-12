// models/website_content.dart
class WebsiteConfig {
  final String id;
  final String siteName;
  final String logoUrl;
  final String tagline;
  final String description;
  final List<BannerItem> banners;
  final List<StatItem> stats;
  final SocialMediaLinks socialMedia;
  final String footerText;
  final PageContent aboutUs;
  final PageContent privacyPolicy;
  final PageContent termsConditions;
  final PageContent refundPolicy;
  final DateTime updatedAt;

  WebsiteConfig({
    required this.id,
    required this.siteName,
    required this.logoUrl,
    required this.tagline,
    required this.description,
    required this.banners,
    required this.stats,
    required this.socialMedia,
    required this.footerText,
    required this.aboutUs,
    required this.privacyPolicy,
    required this.termsConditions,
    required this.refundPolicy,
    required this.updatedAt,
  });

  factory WebsiteConfig.fromMap(Map<String, dynamic> map, String id) {
    return WebsiteConfig(
      id: id,
      siteName: map['siteName'] ?? 'WellnessHub',
      logoUrl: map['logoUrl'] ?? '',
      tagline: map['tagline'] ?? 'Your Wellness Partner',
      description:
          map['description'] ?? 'Premium quality products for your health',
      banners: (map['banners'] as List<dynamic>?)
              ?.map((banner) => BannerItem.fromMap(banner))
              .toList() ??
          [],
      stats: (map['stats'] as List<dynamic>?)
              ?.map((stat) => StatItem.fromMap(stat))
              .toList() ??
          [],
      socialMedia: SocialMediaLinks.fromMap(map['socialMedia'] ?? {}),
      footerText:
          map['footerText'] ?? '© 2024 WellnessHub. All rights reserved.',
      aboutUs: PageContent.fromMap(map['aboutUs'] ?? {}),
      privacyPolicy: PageContent.fromMap(map['privacyPolicy'] ?? {}),
      termsConditions: PageContent.fromMap(map['termsConditions'] ?? {}),
      refundPolicy: PageContent.fromMap(map['refundPolicy'] ?? {}),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siteName': siteName,
      'logoUrl': logoUrl,
      'tagline': tagline,
      'description': description,
      'banners': banners.map((banner) => banner.toMap()).toList(),
      'stats': stats.map((stat) => stat.toMap()).toList(),
      'socialMedia': socialMedia.toMap(),
      'footerText': footerText,
      'aboutUs': aboutUs.toMap(),
      'privacyPolicy': privacyPolicy.toMap(),
      'termsConditions': termsConditions.toMap(),
      'refundPolicy': refundPolicy.toMap(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class PageContent {
  final String title;
  final String subtitle;
  final String content;
  final String? heroImageUrl;
  final List<String> keyPoints;
  final ContactInfo? contactInfo;
  final bool isEnabled;
  final DateTime lastUpdated;

  PageContent({
    required this.title,
    required this.subtitle,
    required this.content,
    this.heroImageUrl,
    required this.keyPoints,
    this.contactInfo,
    this.isEnabled = true,
    required this.lastUpdated,
  });

  factory PageContent.fromMap(Map<String, dynamic> map) {
    return PageContent(
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      content: map['content'] ?? '',
      heroImageUrl: map['heroImageUrl'],
      keyPoints: List<String>.from(map['keyPoints'] ?? []),
      contactInfo: map['contactInfo'] != null
          ? ContactInfo.fromMap(map['contactInfo'])
          : null,
      isEnabled: map['isEnabled'] ?? true,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          map['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'heroImageUrl': heroImageUrl,
      'keyPoints': keyPoints,
      'contactInfo': contactInfo?.toMap(),
      'isEnabled': isEnabled,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class ContactInfo {
  final String email;
  final String phone;
  final String address;
  final String workingHours;

  ContactInfo({
    required this.email,
    required this.phone,
    required this.address,
    required this.workingHours,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      workingHours: map['workingHours'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      'address': address,
      'workingHours': workingHours,
    };
  }
}

class BannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String buttonText;
  final String? buttonAction; // URL or route
  final String? backgroundImageUrl;
  final List<String> gradientColors; // Hex color codes
  final String badgeText;
  final String badgeIcon; // Emoji or icon name
  final bool isActive;
  final int order;

  BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.buttonAction,
    this.backgroundImageUrl,
    required this.gradientColors,
    required this.badgeText,
    required this.badgeIcon,
    this.isActive = true,
    this.order = 0,
  });

  factory BannerItem.fromMap(Map<String, dynamic> map) {
    return BannerItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      buttonText: map['buttonText'] ?? 'Learn More',
      buttonAction: map['buttonAction'],
      backgroundImageUrl: map['backgroundImageUrl'],
      gradientColors:
          List<String>.from(map['gradientColors'] ?? ['#667EEA', '#764BA2']),
      badgeText: map['badgeText'] ?? '',
      badgeIcon: map['badgeIcon'] ?? '✨',
      isActive: map['isActive'] ?? true,
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'buttonText': buttonText,
      'buttonAction': buttonAction,
      'backgroundImageUrl': backgroundImageUrl,
      'gradientColors': gradientColors,
      'badgeText': badgeText,
      'badgeIcon': badgeIcon,
      'isActive': isActive,
      'order': order,
    };
  }
}

class StatItem {
  final String id;
  final String number;
  final String label;
  final String iconName; // Material icon name
  final List<String> gradientColors;
  final bool isActive;
  final int order;

  StatItem({
    required this.id,
    required this.number,
    required this.label,
    required this.iconName,
    required this.gradientColors,
    this.isActive = true,
    this.order = 0,
  });

  factory StatItem.fromMap(Map<String, dynamic> map) {
    return StatItem(
      id: map['id'] ?? '',
      number: map['number'] ?? '0',
      label: map['label'] ?? '',
      iconName: map['iconName'] ?? 'star_outline',
      gradientColors:
          List<String>.from(map['gradientColors'] ?? ['#667EEA', '#764BA2']),
      isActive: map['isActive'] ?? true,
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'label': label,
      'iconName': iconName,
      'gradientColors': gradientColors,
      'isActive': isActive,
      'order': order,
    };
  }
}

class SocialMediaLinks {
  final String facebook;
  final String instagram;
  final String twitter;
  final String youtube;
  final String linkedin;
  final String whatsapp;
  final String email;
  final String phone;

  SocialMediaLinks({
    this.facebook = '',
    this.instagram = '',
    this.twitter = '',
    this.youtube = '',
    this.linkedin = '',
    this.whatsapp = '',
    this.email = '',
    this.phone = '',
  });

  factory SocialMediaLinks.fromMap(Map<String, dynamic> map) {
    return SocialMediaLinks(
      facebook: map['facebook'] ?? '',
      instagram: map['instagram'] ?? '',
      twitter: map['twitter'] ?? '',
      youtube: map['youtube'] ?? '',
      linkedin: map['linkedin'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facebook': facebook,
      'instagram': instagram,
      'twitter': twitter,
      'youtube': youtube,
      'linkedin': linkedin,
      'whatsapp': whatsapp,
      'email': email,
      'phone': phone,
    };
  }
}
