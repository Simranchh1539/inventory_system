import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventorysystem/models/items.dart';
import 'package:inventorysystem/models/user.dart';
import 'package:inventorysystem/services/crud.dart';

class StartupCache {
  static StartupCache _startupCache;
  static Map _itemMap;
  bool reload;
  UserData userData;

  StartupCache._createInstance();

  factory StartupCache({bool reload, UserData userData}) {
    if (_startupCache == null) {
      _startupCache = StartupCache._createInstance();
    }
    _startupCache.reload = reload ?? false;
    _startupCache.userData = userData;
    return _startupCache;
  }

  Future<Map> get itemMap async {
    if (_itemMap == null || this.reload) {
      _itemMap = await initializeItemMap();
    }
    return _itemMap;
  }

  Future<Map> initializeItemMap() async {
    Map itemMap = Map();
    CrudHelper crudHelper = CrudHelper(userData: this.userData);
    List<Item> items = await crudHelper.getItems();
    if (items.isEmpty) {
      return itemMap;
    }
    items.forEach((Item item) {
      itemMap[item.id] = [
        item.name,
        item.nickName,
      ];
    });
    return itemMap;
  }
}
