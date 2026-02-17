import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/logger.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  /// Open address in Google Maps
  Future<bool> openInGoogleMaps(String address) async {
    if (address.isEmpty) {
      logger.w('Cannot open maps: address is empty');
      return false;
    }

    // Encode the address for URL
    final encodedAddress = Uri.encodeComponent(address);
    
    // Try Google Maps URL first (works on mobile and web)
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    
    try {
      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        logger.i('Opened Google Maps for address: $address');
        return true;
      } else {
        logger.w('Cannot launch Google Maps URL');
        return false;
      }
    } catch (e) {
      logger.e('Error opening Google Maps', error: e);
      return false;
    }
  }

  /// Open address in Waze
  Future<bool> openInWaze(String address) async {
    if (address.isEmpty) {
      logger.w('Cannot open Waze: address is empty');
      return false;
    }

    final encodedAddress = Uri.encodeComponent(address);
    final wazeUrl = 'https://waze.com/ul?q=$encodedAddress';
    
    try {
      final uri = Uri.parse(wazeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        logger.i('Opened Waze for address: $address');
        return true;
      } else {
        logger.w('Cannot launch Waze URL');
        return false;
      }
    } catch (e) {
      logger.e('Error opening Waze', error: e);
      return false;
    }
  }

  /// Show dialog to choose map app
  static Future<void> showMapOptions(
    BuildContext context, 
    String address, 
    {String? customerName}
  ) async {
    final mapService = MapService();
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buka Navigasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (customerName != null) ...[
              const SizedBox(height: 4),
              Text(
                customerName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              address,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map, color: Colors.red),
              ),
              title: const Text('Google Maps'),
              subtitle: const Text('Buka di Google Maps'),
              onTap: () async {
                Navigator.pop(ctx);
                await mapService.openInGoogleMaps(address);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.navigation, color: Colors.blue),
              ),
              title: const Text('Waze'),
              subtitle: const Text('Buka di Waze'),
              onTap: () async {
                Navigator.pop(ctx);
                await mapService.openInWaze(address);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
