/*
 * Copyright (c) 2019-2020. Antonello Andrea (www.hydrologis.com). All rights reserved.
 * Use of this source code is governed by a GPL3 license that can be
 * found in the LICENSE file.
 */

import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:dart_hydrologis_utils/dart_hydrologis_utils.dart';
import 'package:dart_jts/dart_jts.dart' hide Orientation;
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:latlong/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smash/eu/hydrologis/smash/forms/form_smash_utils.dart';
import 'package:smash/eu/hydrologis/smash/gps/gps.dart';
import 'package:smash/eu/hydrologis/smash/models/map_state.dart';
import 'package:smash/eu/hydrologis/smash/models/project_state.dart';
import 'package:smash/eu/hydrologis/smash/project/objects/notes.dart';
import 'package:smash/eu/hydrologis/smash/project/project_database.dart';
import 'package:smash/eu/hydrologis/smash/widgets/note_properties.dart';
import 'package:smashlibs/smashlibs.dart';

/// The notes list widget.
class NotesListWidget extends StatefulWidget {
  final bool _doSimpleNotes;
  final GeopaparazziProjectDb db;

  NotesListWidget(this._doSimpleNotes, this.db);

  @override
  State<StatefulWidget> createState() {
    return NotesListWidgetState();
  }
}

/// The notes list widget state.
class NotesListWidgetState extends State<NotesListWidget>
    with AfterLayoutMixin {
  List<dynamic> _notesList = [];
  bool _isLoading = true;

  @override
  void afterFirstLayout(BuildContext context) {
    loadNotes();
  }

  loadNotes() {
    _notesList.clear();
    dynamic itemsList = widget.db.getNotes(doSimple: widget._doSimpleNotes);
    if (itemsList != null) {
      _notesList.addAll(itemsList);
    }
    if (widget._doSimpleNotes) {
      itemsList = widget.db.getImages();
      if (itemsList != null) {
        _notesList.addAll(itemsList);
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var projectState = Provider.of<ProjectState>(context, listen: false);
    var db = projectState.projectDb;
    return WillPopScope(
      onWillPop: () async {
        Provider.of<ProjectState>(context, listen: false)
            .reloadProject(context);
        return true;
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text(widget._doSimpleNotes
                ? "Simple Notes List"
                : "Form Notes List"),
          ),
          body: _isLoading
              ? Center(child: SmashCircularProgress(label: "Loading Notes..."))
              : ListView.builder(
                  itemCount: _notesList.length,
                  itemBuilder: (context, index) {
                    return NoteInfo(
                        _notesList[index], db, projectState, loadNotes);
                  })),
    );
  }
}

class NoteInfo extends StatefulWidget {
  final dynamic note;
  final GeopaparazziProjectDb db;
  final ProjectState projectState;
  final reloadNotesFunction;
  NoteInfo(this.note, this.db, this.projectState, this.reloadNotesFunction);

  @override
  _NoteInfoState createState() => _NoteInfoState();
}

class _NoteInfoState extends State<NoteInfo> {
  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];
    List<Widget> secondaryActions = [];
    // dynamic dynNote = _notesList[index];
    dynamic dynNote = widget.note;
    int id;
    var markerName;
    var markerColor;
    String text;
    bool isForm = false;
    int ts;
    double lat;
    double lon;
    if (dynNote is Note) {
      id = dynNote.id;
      markerName = dynNote.noteExt.marker;
      markerColor = dynNote.noteExt.color;
      text = dynNote.text;
      ts = dynNote.timeStamp;
      lon = dynNote.lon;
      lat = dynNote.lat;
      if (dynNote.form != null) {
        isForm = true;
      }
    } else {
      id = dynNote.id;
      markerName = 'camera';
      markerColor = ColorExt.asHex(SmashColors.mainDecorationsDarker);
      text = dynNote.text;
      ts = dynNote.timeStamp;
      lon = dynNote.lon;
      lat = dynNote.lat;
    }
    actions.add(IconSlideAction(
        caption: 'Zoom to',
        color: SmashColors.mainDecorations,
        icon: MdiIcons.magnifyScan,
        onTap: () async {
          LatLng position = LatLng(lat, lon);
          Provider.of<SmashMapState>(context, listen: false).center =
              Coordinate(position.longitude, position.latitude);
          Navigator.of(context).pop();
        }));
    if (isForm) {
      actions.add(IconSlideAction(
        caption: 'Edit',
        color: SmashColors.mainDecorations,
        icon: MdiIcons.pencil,
        onTap: () async {
          var sectionMap = jsonDecode(dynNote.form);
          var sectionName = sectionMap[ATTR_SECTIONNAME];
          SmashPosition sp = SmashPosition.fromCoords(dynNote.lon, dynNote.lat,
              DateTime.now().millisecondsSinceEpoch.toDouble());

          await Navigator.push(context, MaterialPageRoute(builder: (context) {
            var masterDetailPage = MasterDetailPage(
              sectionMap,
              SmashUI.titleText(sectionName,
                  color: SmashColors.mainBackground, bold: true),
              sectionName,
              sp,
              dynNote.id,
              SmashFormHelper(),
            );
            return masterDetailPage;
          }));
          setState(() {});
        },
      ));
    } else if (dynNote is Note) {
      actions.add(IconSlideAction(
        caption: 'Properties',
        color: SmashColors.mainDecorations,
        icon: MdiIcons.palette,
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NotePropertiesWidget(dynNote)));
          setState(() {});
        },
      ));
    }
    secondaryActions.add(IconSlideAction(
        caption: 'Delete',
        color: SmashColors.mainDanger,
        icon: MdiIcons.delete,
        onTap: () async {
          bool doDelete = await showConfirmDialog(
              context, "DELETE", 'Are you sure you want to delete the note?');
          if (doDelete) {
            if (dynNote is Note) {
              widget.db.deleteNote(id);
            } else {
              widget.db.deleteImage(id);
            }
            widget.reloadNotesFunction();
          }
        }));

    return Slidable(
      key: ValueKey(id),
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: ListTile(
        title: SmashUI.normalText('$text', bold: true),
        subtitle: Text(
            '${TimeUtilities.ISO8601_TS_FORMATTER.format(DateTime.fromMillisecondsSinceEpoch(ts))}'),
        leading: Icon(
          getSmashIcon(markerName) ?? MdiIcons.mapMarker,
          color: ColorExt(markerColor),
          size: SmashUI.MEDIUM_ICON_SIZE,
        ),
      ),
      actions: actions,
      secondaryActions: secondaryActions,
    );
  }
}
