// admin/website_content_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/website_content_provider.dart';
import '../models/website_content.dart';

class WebsiteContentManagementScreen extends StatefulWidget {
  const WebsiteContentManagementScreen({Key? key}) : super(key: key);

  @override
  State<WebsiteContentManagementScreen> createState() =>
      _WebsiteContentManagementScreenState();
}

class _WebsiteContentManagementScreenState
    extends State<WebsiteContentManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this); // Updated to 7 tabs

    // Load website config when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WebsiteContentProvider>(context, listen: false)
          .loadWebsiteConfig();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Image Upload Helper Method
  Future<String?> _uploadImage(XFile imageFile, String folder) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('website_content')
          .child(folder)
          .child(fileName);

      UploadTask uploadTask;

      if (kIsWeb) {
        final Uint8List imageData = await imageFile.readAsBytes();
        uploadTask = storageRef.putData(imageData);
      } else {
        final File file = File(imageFile.path);
        uploadTask = storageRef.putFile(file);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Pick and Upload Image
  Future<String?> _pickAndUploadImage(
      String folder, BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading image...'),
              ],
            ),
          ),
        );

        final String? downloadUrl = await _uploadImage(pickedFile, folder);
        Navigator.pop(context); // Close loading dialog

        if (downloadUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          return downloadUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Website Content Management'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Site Branding', icon: Icon(Icons.branding_watermark)),
            Tab(text: 'Banners', icon: Icon(Icons.view_carousel)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            Tab(text: 'Social Media', icon: Icon(Icons.share)),
            Tab(text: 'About Us', icon: Icon(Icons.info)),
            Tab(text: 'Policies', icon: Icon(Icons.policy)),
            Tab(text: 'Terms', icon: Icon(Icons.gavel)),
          ],
        ),
      ),
      body: Consumer<WebsiteContentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading website configuration...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadWebsiteConfig(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildSiteBrandingTab(provider),
              _buildBannersTab(provider),
              _buildStatisticsTab(provider),
              _buildSocialMediaTab(provider),
              _buildAboutUsTab(provider),
              _buildPoliciesTab(provider),
              _buildTermsTab(provider),
            ],
          );
        },
      ),
    );
  }

  // Site Branding Tab
  Widget _buildSiteBrandingTab(WebsiteContentProvider provider) {
    final config = provider.websiteConfig;
    if (config == null)
      return const Center(child: Text('No configuration found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Site Branding Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _SiteBrandingForm(
            config: config,
            provider: provider,
            onPickImage: _pickAndUploadImage,
          ),
        ],
      ),
    );
  }

  // Banners Tab
  Widget _buildBannersTab(WebsiteContentProvider provider) {
    final config = provider.websiteConfig;
    if (config == null)
      return const Center(child: Text('No configuration found'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Website Banners',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showBannerDialog(provider, null),
                icon: const Icon(Icons.add),
                label: const Text('Add Banner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: config.banners.length,
            itemBuilder: (context, index) {
              final banner = config.banners[index];
              return _buildBannerCard(provider, banner);
            },
          ),
        ),
      ],
    );
  }

  // Statistics Tab
  Widget _buildStatisticsTab(WebsiteContentProvider provider) {
    final config = provider.websiteConfig;
    if (config == null)
      return const Center(child: Text('No configuration found'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Website Statistics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showStatDialog(provider, null),
                icon: const Icon(Icons.add),
                label: const Text('Add Stat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: config.stats.length,
            itemBuilder: (context, index) {
              final stat = config.stats[index];
              return _buildStatCard(provider, stat);
            },
          ),
        ),
      ],
    );
  }

  // Social Media Tab
  Widget _buildSocialMediaTab(WebsiteContentProvider provider) {
    final config = provider.websiteConfig;
    if (config == null)
      return const Center(child: Text('No configuration found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Social Media Links',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _SocialMediaForm(socialMedia: config.socialMedia, provider: provider),
        ],
      ),
    );
  }

  // About Us Tab
  Widget _buildAboutUsTab(WebsiteContentProvider provider) {
    final config = provider.websiteConfig;
    if (config == null)
      return const Center(child: Text('No configuration found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Us Page Content',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _PageContentForm(
            pageContent: config.aboutUs,
            pageType: 'aboutUs',
            provider: provider,
            onPickImage: _pickAndUploadImage,
          ),
        ],
      ),
    );
  }

  // Policies Tab (Privacy Policy & Refund Policy)
  Widget _buildPoliciesTab(WebsiteContentProvider provider) {
    final config = provider.websiteConfig;
    if (config == null)
      return const Center(child: Text('No configuration found'));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey[100],
            child: const TabBar(
              labelColor: Color(0xFF2E7D32),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF2E7D32),
              tabs: [
                Tab(text: 'Privacy Policy'),
                Tab(text: 'Refund Policy'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _PageContentForm(
                    pageContent: config.privacyPolicy,
                    pageType: 'privacyPolicy',
                    provider: provider,
                    onPickImage: _pickAndUploadImage,
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _PageContentForm(
                    pageContent: config.refundPolicy,
                    pageType: 'refundPolicy',
                    provider: provider,
                    onPickImage: _pickAndUploadImage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Terms Tab
  Widget _buildTermsTab(WebsiteContentProvider provider) {
    final config = provider.websiteConfig;
    if (config == null)
      return const Center(child: Text('No configuration found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terms & Conditions Content',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _PageContentForm(
            pageContent: config.termsConditions,
            pageType: 'termsConditions',
            provider: provider,
            onPickImage: _pickAndUploadImage,
          ),
        ],
      ),
    );
  }

  // Banner Card Widget (keeping existing implementation)
  Widget _buildBannerCard(WebsiteContentProvider provider, BannerItem banner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: banner.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    banner.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const Spacer(),
                Text(
                  'Order: ${banner.order}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showBannerDialog(provider, banner);
                        break;
                      case 'delete':
                        _deleteBanner(provider, banner);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (banner.backgroundImageUrl?.isNotEmpty == true) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Background Image
                      Image.network(
                        banner.backgroundImageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      // Gradient Overlay
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      // Content Overlay
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              banner.subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Text(
                banner.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(banner.subtitle),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Text(banner.badgeIcon),
                const SizedBox(width: 8),
                Text(banner.badgeText),
                const Spacer(),
                Text('Button: ${banner.buttonText}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Stat Card Widget (keeping existing implementation)
  Widget _buildStatCard(WebsiteContentProvider provider, StatItem stat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: stat.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stat.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showStatDialog(provider, stat);
                        break;
                      case 'delete':
                        _deleteStat(provider, stat);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stat.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(stat.label),
            const SizedBox(height: 8),
            Text('Icon: ${stat.iconName}'),
            Text('Order: ${stat.order}'),
          ],
        ),
      ),
    );
  }

  // Show Banner Dialog (keeping existing implementation)
  void _showBannerDialog(WebsiteContentProvider provider, BannerItem? banner) {
    showDialog(
      context: context,
      builder: (context) => _BannerDialog(
        provider: provider,
        banner: banner,
        onPickImage: _pickAndUploadImage,
      ),
    );
  }

  // Show Stat Dialog (keeping existing implementation)
  void _showStatDialog(WebsiteContentProvider provider, StatItem? stat) {
    showDialog(
      context: context,
      builder: (context) => _StatDialog(
        provider: provider,
        stat: stat,
      ),
    );
  }

  // Delete Banner (keeping existing implementation)
  void _deleteBanner(WebsiteContentProvider provider, BannerItem banner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: Text('Are you sure you want to delete "${banner.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await provider.deleteBanner(banner.id);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $error'),
                      backgroundColor: Colors.red),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Banner deleted successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Delete Stat (keeping existing implementation)
  void _deleteStat(WebsiteContentProvider provider, StatItem stat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Statistic'),
        content: Text('Are you sure you want to delete "${stat.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await provider.deleteStat(stat.id);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $error'),
                      backgroundColor: Colors.red),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Statistic deleted successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Page Content Form Widget
class _PageContentForm extends StatefulWidget {
  final PageContent pageContent;
  final String pageType;
  final WebsiteContentProvider provider;
  final Future<String?> Function(String, BuildContext) onPickImage;

  const _PageContentForm({
    required this.pageContent,
    required this.pageType,
    required this.provider,
    required this.onPickImage,
  });

  @override
  State<_PageContentForm> createState() => _PageContentFormState();
}

class _PageContentFormState extends State<_PageContentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _contentController;
  late TextEditingController _heroImageController;
  late TextEditingController _keyPointsController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _workingHoursController;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.pageContent.title);
    _subtitleController =
        TextEditingController(text: widget.pageContent.subtitle);
    _contentController =
        TextEditingController(text: widget.pageContent.content);
    _heroImageController =
        TextEditingController(text: widget.pageContent.heroImageUrl ?? '');
    _keyPointsController =
        TextEditingController(text: widget.pageContent.keyPoints.join('\n'));
    _emailController = TextEditingController(
        text: widget.pageContent.contactInfo?.email ?? '');
    _phoneController = TextEditingController(
        text: widget.pageContent.contactInfo?.phone ?? '');
    _addressController = TextEditingController(
        text: widget.pageContent.contactInfo?.address ?? '');
    _workingHoursController = TextEditingController(
        text: widget.pageContent.contactInfo?.workingHours ?? '');
    _isEnabled = widget.pageContent.isEnabled;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _contentController.dispose();
    _heroImageController.dispose();
    _keyPointsController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Status
          Row(
            children: [
              const Text('Page Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Switch(
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
                activeColor: const Color(0xFF2E7D32),
              ),
              Text(_isEnabled ? 'Enabled' : 'Disabled'),
            ],
          ),
          const SizedBox(height: 24),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Page Title',
              hintText: 'Enter the page title',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter page title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Subtitle
          TextFormField(
            controller: _subtitleController,
            decoration: const InputDecoration(
              labelText: 'Page Subtitle',
              hintText: 'Enter the page subtitle',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter page subtitle';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Hero Image Upload Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heroImageController,
                      decoration: const InputDecoration(
                        labelText: 'Hero Image URL (Optional)',
                        hintText: 'Enter image URL or upload',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = await widget.onPickImage('pages', context);
                      if (url != null) {
                        setState(() {
                          _heroImageController.text = url;
                        });
                      }
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Hero Image Preview
              if (_heroImageController.text.isNotEmpty) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _heroImageController.text,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _heroImageController.clear();
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Remove Image',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Content
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Page Content',
              hintText: 'Enter the main content for this page',
              border: OutlineInputBorder(),
            ),
            maxLines: 15,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter page content';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Key Points
          TextFormField(
            controller: _keyPointsController,
            decoration: const InputDecoration(
              labelText: 'Key Points (One per line)',
              hintText: 'Enter key points, each on a new line',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),

          // Contact Information (for About Us page)
          if (widget.pageType == 'aboutUs') ...[
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Email',
                      hintText: 'Enter contact email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone',
                      hintText: 'Enter contact phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Enter business address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _workingHoursController,
              decoration: const InputDecoration(
                labelText: 'Working Hours',
                hintText: 'Enter working hours',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
          ],

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savePageContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Update ${_getPageDisplayName()} Content'),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageDisplayName() {
    switch (widget.pageType) {
      case 'aboutUs':
        return 'About Us';
      case 'privacyPolicy':
        return 'Privacy Policy';
      case 'termsConditions':
        return 'Terms & Conditions';
      case 'refundPolicy':
        return 'Refund Policy';
      default:
        return 'Page';
    }
  }

  void _savePageContent() async {
    if (_formKey.currentState!.validate()) {
      final keyPoints = _keyPointsController.text
          .split('\n')
          .where((point) => point.trim().isNotEmpty)
          .toList();

      ContactInfo? contactInfo;
      if (widget.pageType == 'aboutUs') {
        contactInfo = ContactInfo(
          email: _emailController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          workingHours: _workingHoursController.text,
        );
      }

      final pageContent = PageContent(
        title: _titleController.text,
        subtitle: _subtitleController.text,
        content: _contentController.text,
        heroImageUrl: _heroImageController.text.isEmpty
            ? null
            : _heroImageController.text,
        keyPoints: keyPoints,
        contactInfo: contactInfo,
        isEnabled: _isEnabled,
        lastUpdated: DateTime.now(),
      );

      final error = await widget.provider.updatePageContent(
        pageType: widget.pageType,
        content: pageContent,
      );

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_getPageDisplayName()} content updated successfully!')),
        );
      }
    }
  }
}

// Site Branding Form Widget (keeping existing implementation with minor updates)
class _SiteBrandingForm extends StatefulWidget {
  final WebsiteConfig config;
  final WebsiteContentProvider provider;
  final Future<String?> Function(String, BuildContext) onPickImage;

  const _SiteBrandingForm({
    required this.config,
    required this.provider,
    required this.onPickImage,
  });

  @override
  State<_SiteBrandingForm> createState() => _SiteBrandingFormState();
}

class _SiteBrandingFormState extends State<_SiteBrandingForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _siteNameController;
  late TextEditingController _logoUrlController;
  late TextEditingController _taglineController;
  late TextEditingController _descriptionController;
  late TextEditingController _footerTextController;

  @override
  void initState() {
    super.initState();
    _siteNameController = TextEditingController(text: widget.config.siteName);
    _logoUrlController = TextEditingController(text: widget.config.logoUrl);
    _taglineController = TextEditingController(text: widget.config.tagline);
    _descriptionController =
        TextEditingController(text: widget.config.description);
    _footerTextController =
        TextEditingController(text: widget.config.footerText);
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _logoUrlController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _footerTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _siteNameController,
            decoration: const InputDecoration(
              labelText: 'Site Name',
              hintText: 'Enter your website name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter site name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Logo Upload Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _logoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Logo URL',
                        hintText: 'Enter logo image URL or upload',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = await widget.onPickImage('logos', context);
                      if (url != null) {
                        setState(() {
                          _logoUrlController.text = url;
                        });
                      }
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Logo Preview
              if (_logoUrlController.text.isNotEmpty) ...[
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _logoUrlController.text,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _logoUrlController.clear();
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Remove Logo',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),
          TextFormField(
            controller: _taglineController,
            decoration: const InputDecoration(
              labelText: 'Tagline',
              hintText: 'Enter website tagline',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter tagline';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter website description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _footerTextController,
            decoration: const InputDecoration(
              labelText: 'Footer Text',
              hintText: 'Enter footer copyright text',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter footer text';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveBranding,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Update Site Branding'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveBranding() async {
    if (_formKey.currentState!.validate()) {
      final error = await widget.provider.updateSiteBranding(
        siteName: _siteNameController.text,
        logoUrl: _logoUrlController.text,
        tagline: _taglineController.text,
        description: _descriptionController.text,
        footerText: _footerTextController.text,
      );

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site branding updated successfully!')),
        );
      }
    }
  }
}

// Banner Dialog Widget (keeping existing implementation)
class _BannerDialog extends StatefulWidget {
  final WebsiteContentProvider provider;
  final BannerItem? banner;
  final Future<String?> Function(String, BuildContext) onPickImage;

  const _BannerDialog({
    required this.provider,
    this.banner,
    required this.onPickImage,
  });

  @override
  State<_BannerDialog> createState() => _BannerDialogState();
}

class _BannerDialogState extends State<_BannerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _buttonTextController;
  late TextEditingController _buttonActionController;
  late TextEditingController _backgroundImageController;
  late TextEditingController _badgeTextController;
  late TextEditingController _badgeIconController;
  late TextEditingController _orderController;
  late TextEditingController _gradientColor1Controller;
  late TextEditingController _gradientColor2Controller;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final banner = widget.banner;
    _titleController = TextEditingController(text: banner?.title ?? '');
    _subtitleController = TextEditingController(text: banner?.subtitle ?? '');
    _buttonTextController =
        TextEditingController(text: banner?.buttonText ?? 'Learn More');
    _buttonActionController =
        TextEditingController(text: banner?.buttonAction ?? '');
    _backgroundImageController =
        TextEditingController(text: banner?.backgroundImageUrl ?? '');
    _badgeTextController = TextEditingController(text: banner?.badgeText ?? '');
    _badgeIconController =
        TextEditingController(text: banner?.badgeIcon ?? '✨');
    _orderController =
        TextEditingController(text: (banner?.order ?? 1).toString());
    _gradientColor1Controller =
        TextEditingController(text: banner?.gradientColors.first ?? '#667EEA');
    _gradientColor2Controller =
        TextEditingController(text: banner?.gradientColors.last ?? '#764BA2');
    _isActive = banner?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _buttonTextController.dispose();
    _buttonActionController.dispose();
    _backgroundImageController.dispose();
    _badgeTextController.dispose();
    _badgeIconController.dispose();
    _orderController.dispose();
    _gradientColor1Controller.dispose();
    _gradientColor2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 750,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              widget.banner == null ? 'Add Banner' : 'Edit Banner',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter subtitle';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buttonTextController,
                              decoration: const InputDecoration(
                                labelText: 'Button Text',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter button text';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _buttonActionController,
                              decoration: const InputDecoration(
                                labelText: 'Button Action (Route/URL)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Background Image Upload Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _backgroundImageController,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Background Image URL (Optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final url = await widget.onPickImage(
                                      'banners', context);
                                  if (url != null) {
                                    setState(() {
                                      _backgroundImageController.text = url;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Background Image Preview
                          if (_backgroundImageController.text.isNotEmpty) ...[
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _backgroundImageController.text,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _backgroundImageController.clear();
                                });
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Remove Image',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _badgeTextController,
                              decoration: const InputDecoration(
                                labelText: 'Badge Text',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _badgeIconController,
                              decoration: const InputDecoration(
                                labelText: 'Badge Icon (Emoji)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gradientColor1Controller,
                              decoration: const InputDecoration(
                                labelText: 'Gradient Color 1 (Hex)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter color';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _gradientColor2Controller,
                              decoration: const InputDecoration(
                                labelText: 'Gradient Color 2 (Hex)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter color';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _orderController,
                              decoration: const InputDecoration(
                                labelText: 'Display Order',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter order';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Active'),
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _saveBanner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                      widget.banner == null ? 'Add Banner' : 'Update Banner'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveBanner() async {
    if (_formKey.currentState!.validate()) {
      final banner = BannerItem(
        id: widget.banner?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        subtitle: _subtitleController.text,
        buttonText: _buttonTextController.text,
        buttonAction: _buttonActionController.text.isEmpty
            ? null
            : _buttonActionController.text,
        backgroundImageUrl: _backgroundImageController.text.isEmpty
            ? null
            : _backgroundImageController.text,
        gradientColors: [
          _gradientColor1Controller.text,
          _gradientColor2Controller.text
        ],
        badgeText: _badgeTextController.text,
        badgeIcon: _badgeIconController.text,
        isActive: _isActive,
        order: int.tryParse(_orderController.text) ?? 1,
      );

      final error = await widget.provider.saveBanner(banner);
      Navigator.pop(context);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Banner ${widget.banner == null ? 'added' : 'updated'} successfully!')),
        );
      }
    }
  }
}

// Stat Dialog Widget
class _StatDialog extends StatefulWidget {
  final WebsiteContentProvider provider;
  final StatItem? stat;

  const _StatDialog({
    required this.provider,
    this.stat,
  });

  @override
  State<_StatDialog> createState() => _StatDialogState();
}

class _StatDialogState extends State<_StatDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numberController;
  late TextEditingController _labelController;
  late TextEditingController _iconNameController;
  late TextEditingController _orderController;
  late TextEditingController _gradientColor1Controller;
  late TextEditingController _gradientColor2Controller;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final stat = widget.stat;
    _numberController = TextEditingController(text: stat?.number ?? '');
    _labelController = TextEditingController(text: stat?.label ?? '');
    _iconNameController =
        TextEditingController(text: stat?.iconName ?? 'star_outline');
    _orderController =
        TextEditingController(text: (stat?.order ?? 1).toString());
    _gradientColor1Controller =
        TextEditingController(text: stat?.gradientColors.first ?? '#667EEA');
    _gradientColor2Controller =
        TextEditingController(text: stat?.gradientColors.last ?? '#764BA2');
    _isActive = stat?.isActive ?? true;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _labelController.dispose();
    _iconNameController.dispose();
    _orderController.dispose();
    _gradientColor1Controller.dispose();
    _gradientColor2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              widget.stat == null ? 'Add Statistic' : 'Edit Statistic',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numberController,
                              decoration: const InputDecoration(
                                labelText: 'Number/Value',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _labelController,
                              decoration: const InputDecoration(
                                labelText: 'Label',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter label';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _iconNameController,
                              decoration: const InputDecoration(
                                labelText: 'Icon Name',
                                hintText: 'e.g., star_outline, people_outline',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter icon name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _orderController,
                              decoration: const InputDecoration(
                                labelText: 'Display Order',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter order';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gradientColor1Controller,
                              decoration: const InputDecoration(
                                labelText: 'Gradient Color 1 (Hex)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter color';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _gradientColor2Controller,
                              decoration: const InputDecoration(
                                labelText: 'Gradient Color 2 (Hex)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter color';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _saveStat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.stat == null
                      ? 'Add Statistic'
                      : 'Update Statistic'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveStat() async {
    if (_formKey.currentState!.validate()) {
      final stat = StatItem(
        id: widget.stat?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        number: _numberController.text,
        label: _labelController.text,
        iconName: _iconNameController.text,
        gradientColors: [
          _gradientColor1Controller.text,
          _gradientColor2Controller.text
        ],
        isActive: _isActive,
        order: int.tryParse(_orderController.text) ?? 1,
      );

      final error = await widget.provider.saveStat(stat);
      Navigator.pop(context);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Statistic ${widget.stat == null ? 'added' : 'updated'} successfully!')),
        );
      }
    }
  }
}

// Social Media Form Widget
class _SocialMediaForm extends StatefulWidget {
  final SocialMediaLinks socialMedia;
  final WebsiteContentProvider provider;

  const _SocialMediaForm({
    required this.socialMedia,
    required this.provider,
  });

  @override
  State<_SocialMediaForm> createState() => _SocialMediaFormState();
}

class _SocialMediaFormState extends State<_SocialMediaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;
  late TextEditingController _youtubeController;
  late TextEditingController _linkedinController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _facebookController =
        TextEditingController(text: widget.socialMedia.facebook);
    _instagramController =
        TextEditingController(text: widget.socialMedia.instagram);
    _twitterController =
        TextEditingController(text: widget.socialMedia.twitter);
    _youtubeController =
        TextEditingController(text: widget.socialMedia.youtube);
    _linkedinController =
        TextEditingController(text: widget.socialMedia.linkedin);
    _whatsappController =
        TextEditingController(text: widget.socialMedia.whatsapp);
    _emailController = TextEditingController(text: widget.socialMedia.email);
    _phoneController = TextEditingController(text: widget.socialMedia.phone);
  }

  @override
  void dispose() {
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _linkedinController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _facebookController,
                  decoration: const InputDecoration(
                    labelText: 'Facebook URL',
                    prefixIcon: Icon(Icons.facebook),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _instagramController,
                  decoration: const InputDecoration(
                    labelText: 'Instagram URL',
                    prefixIcon: Icon(Icons.camera_alt),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _twitterController,
                  decoration: const InputDecoration(
                    labelText: 'Twitter URL',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _youtubeController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube URL',
                    prefixIcon: Icon(Icons.play_circle),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _linkedinController,
                  decoration: const InputDecoration(
                    labelText: 'LinkedIn URL',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Number',
                    prefixIcon: Icon(Icons.message),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSocialMedia,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Update Social Media Links'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSocialMedia() async {
    final socialMedia = SocialMediaLinks(
      facebook: _facebookController.text,
      instagram: _instagramController.text,
      twitter: _twitterController.text,
      youtube: _youtubeController.text,
      linkedin: _linkedinController.text,
      whatsapp: _whatsappController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );

    final error = await widget.provider.updateSocialMedia(socialMedia);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Social media links updated successfully!')),
      );
    }
  }
}
