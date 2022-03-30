import 'package:flutter/material.dart';
import 'package:inventorysystem/app_pages/authentication/authenticate.dart';
import 'package:inventorysystem/app_pages/item_list.dart';
import 'package:inventorysystem/app_pages/setting.dart';
import 'package:inventorysystem/models/user.dart';
import 'package:inventorysystem/services/crud.dart';
import 'package:inventorysystem/utils/cache.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserData>(context, listen: false);

    final StartupCache startupCache =
        StartupCache(userData: user, reload: true);

    if (user == null) {
      return Authenticate();
    } else {
      _initializeCache(startupCache);
      _checkForTargetPermission(user);
      return ItemList();
    }
  }

  void _initializeCache(startupCache) async {
    await startupCache.itemMap;
  }

  void _checkForTargetPermission(UserData userData) async {
    bool permitted = await SettingState.validateTargetEmail(userData);
    if (!permitted) {
      userData.targetEmail = userData.email;
      await CrudHelper().updateUserData(userData);
    }
  }
}
