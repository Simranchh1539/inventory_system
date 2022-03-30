import 'package:flutter/material.dart';
import 'package:inventorysystem/app_pages/form/sale_entry_form.dart';
import 'package:inventorysystem/app_pages/item_list.dart';
import 'package:inventorysystem/app_pages/setting.dart';
import 'package:inventorysystem/app_pages/transactions/transaction_list.dart';
import 'package:inventorysystem/app_pages/wrapper.dart';
import 'package:inventorysystem/models/user.dart';
import 'package:inventorysystem/services/auth.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserData>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bookkeeping app',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        routes: <String, WidgetBuilder>{
          "/mainForm": (BuildContext context) =>
              SalesEntryForm(title: "Sales Entry"),
          "/itemList": (BuildContext context) => ItemList(),
          "/transactionList": (BuildContext context) => TransactionList(),
          "/settings": (BuildContext context) => Setting(),
        },
        home: Wrapper(),
      ),
    );
  }
}
