import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

FlutterMap buildMap(
  BuildContext context,
  MapController mapController, {
  bool interactive = true,
  double minZoom = 4,
  double maxZoom = 18,
  double zoom = 13,
  LatLng center,
  void Function(MapPosition, bool) onPositionChanged,
  List<Marker> markers,
  List<CircleMarker> circleMarkers,
}) {
  return FlutterMap(
    mapController: mapController,
    options: MapOptions(
      center: center,
      zoom: zoom,
      minZoom: minZoom,
      maxZoom: maxZoom,
      interactiveFlags: interactive
          ? InteractiveFlag.all
          : InteractiveFlag.none,
      onPositionChanged: onPositionChanged,
    ),
    children: buildMapLayers(
      context,
      markers: markers,
      circleMarkers: circleMarkers,
    ),
  );
}

List<Widget> buildMapLayers(
  BuildContext context, {
  List<Marker> markers,
  List<CircleMarker> circleMarkers,
}) {
  return [
    TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
    ),
    if (markers != null && markers.isNotEmpty)
      MarkerLayer(markers: markers),
    if (circleMarkers != null && circleMarkers.isNotEmpty)
      CircleLayer(circles: circleMarkers),
  ];
}

void fitMapBounds(
  MapController mapController,
  LatLngBounds mapBounds, {
  double padding = 50,
}) {
  if (mapController != null && mapBounds != null) {
    mapController.fitBounds(
      mapBounds,
      options: FitBoundsOptions(
        padding: EdgeInsets.all(padding),
      ),
    );
  }
}
