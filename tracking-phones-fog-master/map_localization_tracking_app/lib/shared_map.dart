import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;

class SharedMap {
  // Singleton instance
  static final SharedMap _instance = SharedMap._internal();

  // Private constructor to ensure a single instance
  SharedMap._internal();

  // Public factory constructor to access the instance
  factory SharedMap() {
    return _instance;
  }

  // Map-related properties
  final MapController _controller = MapController();
  Style? _style;
  Object? _error;

  // Initialize the map in the constructor
  Future<void> init() async {
    try {
      _style = await _readStyle();
    } catch (e, stack) {
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(stack);
      _error = e;
    }
  }

  // Method to create and return the map
  Widget buildMap() {
    if (_style == null) {
      // Return a loading indicator or a placeholder
      return const CircularProgressIndicator();
    } else {
      return _createMap(_style!);
    }
  }

  Widget _createMap(Style style) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        center: style.center ?? const LatLng(49.246292, -123.116226),
        zoom: style.zoom ?? 10,
        maxZoom: 22,
        interactiveFlags: InteractiveFlag.drag |
            InteractiveFlag.flingAnimation |
            InteractiveFlag.pinchMove |
            InteractiveFlag.pinchZoom |
            InteractiveFlag.doubleTapZoom,
      ),
      children: [
        VectorTileLayer(
          theme: style.theme,
          sprites: style.sprites,
          tileProviders: style.providers,
        ),
      ],
    );
  }

  Future<Style> _readStyle() {
    return StyleReader(
      uri: 'https://api.maptiler.com/maps/outdoor/style.json?key={key}',
      apiKey: 'J9IsnpD2OLw1utwkyBrz', // Replace with your actual API key
      logger: const Logger.console(),
    ).read();
  }
}

// alternates:
//   Mapbox - mapbox://styles/mapbox/streets-v12?access_token={key}
//   Maptiler - https://api.maptiler.com/maps/outdoor/style.json?key={key}
//   Stadia Maps - https://tiles.stadiamaps.com/styles/outdoors.json?api_key={key}