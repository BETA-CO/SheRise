import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

class NearbyPlacesPage extends StatefulWidget {
  const NearbyPlacesPage({super.key});

  @override
  State<NearbyPlacesPage> createState() => _NearbyPlacesPageState();
}

class _NearbyPlacesPageState extends State<NearbyPlacesPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            // Prevent intent:// schemes from crashing the webview
            // and try to keep Google Maps navigation inside the app
            if (request.url.startsWith('intent://')) {
              // Extract browser_fallback_url if present
              try {
                // The fallback URL is often encoded inside the intent string
                // Format: ...S.browser_fallback_url=EncodedURL;...
                final parts = request.url.split('S.browser_fallback_url=');
                if (parts.length > 1) {
                  final fallback = parts[1].split(';').first;
                  final decoded = Uri.decodeComponent(fallback);
                  _controller.loadRequest(Uri.parse(decoded));
                }
              } catch (e) {
                // If parsing fails, just ignore/prevent the crash
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Default load, will be overridden by buttons
    _loadMapQuery("police station");
  }

  Future<void> _loadMapQuery(String query) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // Construct Google Maps Search URL
      final url =
          "https://www.google.com/maps/search/$query/@${position.latitude},${position.longitude},14z";
      _controller.loadRequest(Uri.parse(url));
    } catch (e) {
      // Fallback if location fails (e.g. permission denied)
      final url = "https://www.google.com/maps/search/$query";
      _controller.loadRequest(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Safe Places")),
      body: Column(
        children: [
          // Filter Buttons
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  "Police",
                  Icons.local_police,
                  Colors.blue,
                  "police+station",
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "Hospitals",
                  Icons.local_hospital,
                  Colors.red,
                  "hospital",
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "Pharmacies",
                  Icons.local_pharmacy,
                  Colors.green,
                  "pharmacy",
                ),
              ],
            ),
          ),
          // Map View
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    Color color,
    String query,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      onPressed: () => _loadMapQuery(query),
    );
  }
}
