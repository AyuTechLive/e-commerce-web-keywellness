// Enhanced Delhivery tracking parser for user-friendly display
// Add this to your DelhiveryService class or create a separate helper class

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class DelhiveryTrackingParser {
  /// Parse tracking data to user-friendly format
  static Map<String, dynamic> parseTrackingData(
      Map<String, dynamic> trackingResponse) {
    try {
      if (trackingResponse['ShipmentData'] == null ||
          trackingResponse['ShipmentData'].isEmpty) {
        return {'success': false, 'message': 'No tracking data available'};
      }

      final shipment = trackingResponse['ShipmentData'][0]['Shipment'];
      final status = shipment['Status'];
      final scans = shipment['Scans'] as List<dynamic>? ?? [];

      // Parse current status
      final currentStatus = _parseCurrentStatus(status);

      // Parse tracking timeline
      final timeline = _parseTrackingTimeline(scans);

      // Calculate progress
      final progress = _calculateProgress(status['Status']?.toString() ?? '');

      return {
        'success': true,
        'waybill': shipment['AWB'],
        'current_status': currentStatus['status'],
        'current_description': currentStatus['description'],
        'progress_level': progress['level'],
        'progress_percentage': progress['percentage'],
        'estimated_delivery': _formatDate(shipment['ExpectedDeliveryDate']),
        'promised_delivery': _formatDate(shipment['PromisedDeliveryDate']),
        'pickup_date': _formatDate(shipment['PickedupDate']),
        'delivery_date': _formatDate(shipment['DeliveryDate']),
        'origin': _cleanLocation(shipment['Origin']),
        'destination': _cleanLocation(shipment['Destination']),
        'order_type': shipment['OrderType'],
        'timeline': timeline,
        'shipment_details': {
          'sender': shipment['SenderName'],
          'consignee': shipment['Consignee']['Name'],
          'reference_no': shipment['ReferenceNo'],
          'cod_amount': shipment['CODAmount'],
          'invoice_amount': shipment['InvoiceAmount'],
        },
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error parsing tracking data: $e');
      return {
        'success': false,
        'message': 'Error processing tracking information'
      };
    }
  }

  /// Parse current status to user-friendly format
  static Map<String, String> _parseCurrentStatus(Map<String, dynamic>? status) {
    if (status == null) {
      return {
        'status': 'Unknown',
        'description': 'Status information not available'
      };
    }

    final statusType = status['Status']?.toString().toLowerCase() ?? '';
    final instructions = status['Instructions']?.toString() ?? '';
    final location = _cleanLocation(status['StatusLocation']?.toString() ?? '');

    switch (statusType) {
      case 'manifested':
        return {
          'status': 'Order Shipped',
          'description':
              'Your order has been picked up and is being processed at $location'
        };

      case 'pending':
        if (instructions.toLowerCase().contains('received at facility')) {
          return {
            'status': 'In Transit',
            'description': 'Package received at sorting facility in $location'
          };
        }
        return {
          'status': 'Processing',
          'description': 'Your package is being processed at $location'
        };

      case 'dispatched':
        if (instructions.toLowerCase().contains('out for delivery')) {
          return {
            'status': 'Out for Delivery',
            'description': 'Your package is out for delivery in $location'
          };
        }
        return {
          'status': 'In Transit',
          'description': 'Package is on the way to $location'
        };

      case 'delivered':
        return {
          'status': 'Delivered',
          'description': 'Package successfully delivered at $location'
        };

      case 'exception':
        return {
          'status': 'Delivery Exception',
          'description': 'There was an issue with delivery. $instructions'
        };

      case 'rto':
      case 'returned':
        return {
          'status': 'Returned',
          'description': 'Package is being returned to sender'
        };

      default:
        return {
          'status': statusType.toUpperCase(),
          'description':
              instructions.isNotEmpty ? instructions : 'Package status updated'
        };
    }
  }

  static Color getStatusColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'success':
        return Colors.green[700]!;
      case 'warning':
        return Colors.amber;
      case 'danger':
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for status
  static IconData getStatusIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'schedule':
        return Icons.schedule;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'warehouse':
        return Icons.warehouse;
      case 'hourglass_empty':
        return Icons.hourglass_empty;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'phone':
        return Icons.phone;
      case 'check_circle':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.info;
    }
  }

  /// Parse tracking timeline to user-friendly events
  static List<Map<String, dynamic>> _parseTrackingTimeline(
      List<dynamic> scans) {
    return scans
        .map<Map<String, dynamic>>((scan) {
          final scanDetail = scan['ScanDetail'] as Map<String, dynamic>;
          final scanType = scanDetail['Scan']?.toString().toLowerCase() ?? '';
          final instructions = scanDetail['Instructions']?.toString() ?? '';
          final location =
              _cleanLocation(scanDetail['ScannedLocation']?.toString() ?? '');
          final dateTime = scanDetail['ScanDateTime']?.toString() ?? '';

          // Convert to user-friendly event
          final event = _parseTrackingEvent(scanType, instructions, location);

          return {
            'timestamp': dateTime,
            'formatted_time': _formatTrackingTime(dateTime),
            'title': event['title'],
            'description': event['description'],
            'location': location,
            'icon': event['icon'],
            'color': event['color'],
            'is_milestone': event['is_milestone'],
            'raw_scan': scanType,
            'raw_instructions': instructions,
          };
        })
        .toList()
        .reversed
        .toList(); // Show latest first
  }

  /// Parse individual tracking event
  static Map<String, dynamic> _parseTrackingEvent(
      String scanType, String instructions, String location) {
    final instructionsLower = instructions.toLowerCase();

    // Manifested events
    if (scanType == 'manifested') {
      if (instructionsLower.contains('pickup scheduled')) {
        return {
          'title': 'Pickup Scheduled',
          'description': 'Your order is ready for pickup',
          'icon': 'schedule',
          'color': 'blue',
          'is_milestone': true,
        };
      }
      return {
        'title': 'Order Shipped',
        'description': 'Package has been picked up and manifested',
        'icon': 'local_shipping',
        'color': 'blue',
        'is_milestone': true,
      };
    }

    // Pending/Processing events
    if (scanType == 'pending') {
      if (instructionsLower.contains('received at facility')) {
        return {
          'title': 'Arrived at Facility',
          'description': 'Package received at sorting facility',
          'icon': 'warehouse',
          'color': 'orange',
          'is_milestone': true,
        };
      }
      return {
        'title': 'Processing',
        'description': 'Package is being processed',
        'icon': 'hourglass_empty',
        'color': 'orange',
        'is_milestone': false,
      };
    }

    // Dispatched events
    if (scanType == 'dispatched') {
      if (instructionsLower.contains('out for delivery')) {
        return {
          'title': 'Out for Delivery',
          'description': 'Package is out for delivery',
          'icon': 'delivery_dining',
          'color': 'green',
          'is_milestone': true,
        };
      }
      if (instructionsLower.contains('call placed')) {
        return {
          'title': 'Delivery Attempt',
          'description': 'Delivery executive contacted you',
          'icon': 'phone',
          'color': 'green',
          'is_milestone': false,
        };
      }
      return {
        'title': 'In Transit',
        'description': 'Package dispatched to next location',
        'icon': 'local_shipping',
        'color': 'orange',
        'is_milestone': false,
      };
    }

    // Delivered events
    if (scanType == 'delivered') {
      return {
        'title': 'Delivered',
        'description': 'Package successfully delivered',
        'icon': 'check_circle',
        'color': 'success',
        'is_milestone': true,
      };
    }

    // Exception/Error events
    if (instructionsLower.contains('exception') ||
        instructionsLower.contains('failed')) {
      return {
        'title': 'Delivery Issue',
        'description': 'There was an issue with delivery',
        'icon': 'warning',
        'color': 'warning',
        'is_milestone': true,
      };
    }

    // Default event
    return {
      'title': scanType.toUpperCase(),
      'description':
          instructions.isNotEmpty ? instructions : 'Package status updated',
      'icon': 'info',
      'color': 'grey',
      'is_milestone': false,
    };
  }

  /// Calculate delivery progress
  static Map<String, dynamic> _calculateProgress(String status) {
    final statusLower = status.toLowerCase();

    switch (statusLower) {
      case 'manifested':
        return {'level': 1, 'percentage': 25};
      case 'pending':
        return {'level': 2, 'percentage': 50};
      case 'dispatched':
        return {'level': 3, 'percentage': 75};
      case 'delivered':
        return {'level': 4, 'percentage': 100};
      case 'exception':
      case 'rto':
        return {'level': 2, 'percentage': 40};
      default:
        return {'level': 1, 'percentage': 20};
    }
  }

  /// Clean location name for display
  static String _cleanLocation(String location) {
    if (location.isEmpty) return '';

    // Remove facility codes and clean up location names
    return location
        .replaceAll(RegExp(r'_[A-Z]+'), '') // Remove facility codes like _C, _D
        .replaceAll('_', ' ')
        .split('(')
        .first // Remove state info in parentheses
        .trim();
  }

  /// Format date for display
  static String? _formatDate(dynamic date) {
    if (date == null) return null;

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return null;
      }

      final now = DateTime.now();
      final difference = dateTime.difference(now);

      if (difference.inDays == 0) {
        return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Tomorrow';
      } else if (difference.inDays == -1) {
        return 'Yesterday';
      } else if (difference.inDays > 0) {
        return 'In ${difference.inDays} days';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return date.toString();
    }
  }

  /// Format tracking event time
  static String _formatTrackingTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// Get color for status
}
