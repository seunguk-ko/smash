/*
 * Copyright (c) 2019-2020. Antonello Andrea (www.hydrologis.com). All rights reserved.
 * Use of this source code is governed by a GPL3 license that can be
 * found in the LICENSE file.
 */

import 'dart:async';
import 'dart:ui';

import 'package:after_layout/after_layout.dart';
import 'package:dart_hydrologis_db/dart_hydrologis_db.dart';
import 'package:dart_jts/dart_jts.dart' as JTS;
import 'package:flutter/material.dart';
import 'package:flutter_geopackage/flutter_geopackage.dart';
import 'package:flutter_map/flutter_map.dart' as FM;
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:smashlibs/com/hydrologis/flutterlibs/utils/logging.dart';
import 'package:smashlibs/smashlibs.dart';
import 'package:smash/eu/hydrologis/smash/maps/layers/core/layermanager.dart';
import 'package:smash/eu/hydrologis/smash/maps/plugins/feature_info_plugin.dart';

class FeatureAttributesViewer extends StatefulWidget {
  final EditableQueryResult features;

  FeatureAttributesViewer(this.features, {Key key}) : super(key: key);

  @override
  _FeatureAttributesViewerState createState() =>
      _FeatureAttributesViewerState();
}

class _FeatureAttributesViewerState extends State<FeatureAttributesViewer>
    with AfterLayoutMixin {
  int _index = 0;
  int _total;
  MapController _mapController = MapController();
  var _baseLayer;
  bool _loading = true;

  @override
  void afterFirstLayout(BuildContext context) async {
    await setBaseLayer();

    _total = widget.features.geoms.length;

    EditableQueryResult f = widget.features;
    var geometry = f.geoms[_index];
    var env = geometry.getEnvelopeInternal();
    var latLngBounds = LatLngBounds(LatLng(env.getMinY(), env.getMinX()),
        LatLng(env.getMaxY(), env.getMaxX()));

    _mapController.onReady.then((v) {
      _mapController.fitBounds(latLngBounds);
    });

    _loading = false;
    setState(() {});
  }

  Future<void> setBaseLayer() async {
    var activeBaseLayers = LayerManager().getLayerSources(onlyActive: true);
    if (activeBaseLayers.isNotEmpty) {
      var baseLayers = await activeBaseLayers[0].toLayers(context);
      if (baseLayers.isNotEmpty) {
        for (var baseLayer in baseLayers) {
          if (baseLayer is TileLayerOptions) {
            _baseLayer = baseLayer;
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var isLandscape = ScreenUtilities.isLandscape(context);

    Color border = Colors.black;
    Color borderFill = Colors.yellow;
    Color fillPoly = Colors.yellow.withOpacity(0.3);

    EditableQueryResult f = widget.features;
    var layers = <LayerOptions>[];

    if (_baseLayer != null) {
      layers.add(_baseLayer);
    }
    _total = f.geoms.length;
    var geometry = f.geoms[_index];

    Map<String, dynamic> data = f.data[_index];
    Map<String, String> typesMap;
    var primaryKey;
    var db;
    if (f.editable[_index]) {
      typesMap = f.fieldAndTypemap[_index];
      primaryKey = f.primaryKeys[_index];
      db = f.dbs[_index];
    }

    var centroid = geometry.getCentroid().getCoordinate();

    var geometryType = geometry.getGeometryType();
    var gType = JTS.EGeometryType.forTypeName(geometryType);
    if (gType.isPoint()) {
      double size = 30;

      var layer = new MarkerLayerOptions(
        markers: [
          new Marker(
            width: size,
            height: size,
            point: LatLng(centroid.y, centroid.x),
            builder: (ctx) => new Stack(
              children: <Widget>[
                Center(
                  child: Icon(
                    MdiIcons.circle,
                    color: border,
                    size: size,
                  ),
                ),
                Center(
                  child: Icon(
                    MdiIcons.circle,
                    color: borderFill,
                    size: size * 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      layers.add(layer);
    } else if (gType.isLine()) {
      List<Polyline> lines = [];
      for (int i = 0; i < geometry.getNumGeometries(); i++) {
        var geometryN = geometry.getGeometryN(i);
        List<LatLng> linePoints =
            geometryN.getCoordinates().map((c) => LatLng(c.y, c.x)).toList();
        lines.add(Polyline(points: linePoints, strokeWidth: 5, color: border));
        lines.add(
            Polyline(points: linePoints, strokeWidth: 3, color: borderFill));
      }
      var lineLayer = PolylineLayerOptions(
        polylineCulling: true,
        polylines: lines,
      );
      layers.add(lineLayer);
    } else if (gType.isPolygon()) {
      List<FM.Polygon> polygons = [];
      for (int i = 0; i < geometry.getNumGeometries(); i++) {
        var geometryN = geometry.getGeometryN(i);
        if (geometryN is JTS.Polygon) {
          var exteriorRing = geometryN.getExteriorRing();
          List<LatLng> polyPoints = exteriorRing
              .getCoordinates()
              .map((c) => LatLng(c.y, c.x))
              .toList();
          polygons.add(FM.Polygon(
              points: polyPoints,
              borderStrokeWidth: 5,
              borderColor: border,
              color: border.withOpacity(0)));
          polygons.add(FM.Polygon(
              points: polyPoints,
              borderStrokeWidth: 3,
              borderColor: borderFill,
              color: fillPoly));
        }
      }
      var polyLayer = PolygonLayerOptions(
        polygonCulling: true,
        polygons: polygons,
      );
      layers.add(polyLayer);
    }

    var tableName = widget.features.ids[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(tableName),
        actions: _total > 1
            ? <Widget>[
                IconButton(
                  icon: Icon(MdiIcons.arrowLeftBoldOutline),
                  onPressed: () {
                    var newIndex = _index - 1;
                    if (newIndex < 0) {
                      newIndex = _total - 1;
                    }
                    setState(() {
                      _index = newIndex;
                      var env = f.geoms[_index].getEnvelopeInternal();
                      _mapController.fitBounds(LatLngBounds(
                          LatLng(env.getMinY(), env.getMinX()),
                          LatLng(env.getMaxY(), env.getMaxX())));
                    });
                  },
                ),
                Text("${_index + 1}/$_total"),
                IconButton(
                  icon: Icon(MdiIcons.arrowRightBoldOutline),
                  onPressed: () {
                    var newIndex = _index + 1;
                    if (newIndex >= _total) {
                      newIndex = 0;
                    }
                    setState(() {
                      _index = newIndex;
                      var env = f.geoms[_index].getEnvelopeInternal();
                      _mapController.fitBounds(LatLngBounds(
                          LatLng(env.getMinY(), env.getMinX()),
                          LatLng(env.getMaxY(), env.getMaxX())));
                    });
                  },
                ),
              ]
            : [],
      ),
      body: _loading
          ? SmashCircularProgress(label: "Loading data...")
          : isLandscape
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: SmashColors.tableBorder,
                          width: 2,
                        ),
                      ),
                      width: MediaQuery.of(context).size.height / 2,
                      height: double.infinity,
                      child: FlutterMap(
                        options: new MapOptions(
                          center: LatLng(centroid.y, centroid.x),
                          zoom: 15,
                          minZoom: 7,
                          maxZoom: 19,
                        ),
                        layers: layers,
                        mapController: _mapController,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: getDataTable(
                            tableName, data, primaryKey, db, typesMap),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: SmashColors.tableBorder,
                          width: 2,
                        ),
                      ),
                      height: MediaQuery.of(context).size.height / 3,
                      width: double.infinity,
                      child: FlutterMap(
                        options: new MapOptions(
                          center: LatLng(centroid.y, centroid.x),
                          zoom: 15,
                          minZoom: 7,
                          maxZoom: 19,
                        ),
                        layers: layers,
                        mapController: _mapController,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: getDataTable(
                              tableName, data, primaryKey, db, typesMap),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget getDataTable(String tablename, Map<String, dynamic> data,
      String primaryKey, dynamic db, Map<String, String> typesMap) {
    List<DataRow> rows = [];

    data.forEach((key, value) {
      bool editable = primaryKey != null && db != null && key != primaryKey;
      var row = DataRow(
        cells: [
          DataCell(SmashUI.normalText(key)),
          DataCell(SmashUI.normalText(value.toString()), showEditIcon: editable,
              onTap: () async {
            if (editable) {
              var pkValue = data[primaryKey];
              var result = await SmashDialogs.showInputDialog(
                context,
                "Set new value",
                key,
                defaultText: value.toString(),
              );
              if (result != null) {
                if (value is String) {
                  data[key] = result;
                } else if (value is int) {
                  data[key] = int.parse(result);
                } else if (value is double) {
                  data[key] = double.parse(result);
                } else {
                  var typeString = typesMap[key].toUpperCase();

                  if (SqliteTypes.isString(typeString)) {
                    data[key] = result;
                  } else if (SqliteTypes.isInteger(typeString)) {
                    data[key] = int.parse(result);
                  } else if (SqliteTypes.isDouble(typeString)) {
                    data[key] = double.parse(result);
                  } else {
                    SMLogger().e(
                        "Could not find type for $key ($value) in table $tablename",
                        null,
                        null);
                    return;
                  }
                }
                var map = {
                  key: data[key],
                };
                var where = "$primaryKey=$pkValue";
                await db.updateMap(SqlName(tablename), map, where);
                setState(() {});
              }
            }
          }),
        ],
      );
      rows.add(row);
    });

    return DataTable(
      columns: [
        DataColumn(label: SmashUI.normalText("FIELD", bold: true)),
        DataColumn(label: SmashUI.normalText("VALUE", bold: true)),
      ],
      rows: rows,
    );
  }

  LatLng getCenterFromBounds(LatLngBounds bounds, MapState mapState) {
    var centerZoom = mapState.getBoundsCenterZoom(bounds, FitBoundsOptions());
    return centerZoom.center;
  }

  double getZoomFromBounds(LatLngBounds bounds, MapState mapState) {
    var centerZoom = mapState.getBoundsCenterZoom(bounds, FitBoundsOptions());
    return centerZoom.zoom;
  }
}
