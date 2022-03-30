import 'package:flutter/material.dart';
import 'package:inventorysystem/app_pages/wrapper.dart';
import 'package:inventorysystem/models/items.dart';
import 'package:inventorysystem/models/transaction.dart';
import 'package:inventorysystem/models/user.dart';
import 'package:inventorysystem/services/crud.dart';
import 'package:inventorysystem/utils/cache.dart';
import 'package:inventorysystem/utils/form.dart';
import 'package:inventorysystem/utils/loading.dart';
import 'package:inventorysystem/utils/scaffold.dart';
import 'package:inventorysystem/utils/window.dart';
import 'package:provider/provider.dart';

class SalesEntryForm extends StatefulWidget {
  final String title;
  final ItemTransaction transaction;
  final bool forEdit;
  final Item swipeData;

  SalesEntryForm({this.title, this.transaction, this.forEdit, this.swipeData});

  @override
  State<StatefulWidget> createState() {
    return _SalesEntryFormState(this.title, this.transaction);
  }
}

class _SalesEntryFormState extends State<SalesEntryForm> {
  // Variables
  String title;
  ItemTransaction transaction;
  _SalesEntryFormState(this.title, this.transaction);

  var _formKey = GlobalKey<FormState>();
  final double _minimumPadding = 5.0;
  List<String> _forms = ['Sales Entry', 'Stock Entry', 'Item Entry'];
  String formName;
  String _currentFormSelected;

  static CrudHelper crudHelper;
  static UserData userData;
  List<Map> itemNamesAndNicknames = List<Map>();
  String disclaimerText = '';
  String stringUnderName = '';
  String tempItemId;
  bool enableAdvancedFields = false;

  List units = List();
  String selectedUnit = '';
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemNumberController = TextEditingController();
  TextEditingController sellingPriceController = TextEditingController();
  TextEditingController duePriceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController costPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    this.formName = _forms[0];
    this._currentFormSelected = this.formName;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userData = Provider.of<UserData>(context, listen: false);
    if (userData != null) {
      crudHelper = CrudHelper(userData: userData);
      _initiateTransactionData();
      _initializeItemNamesAndNicknamesMapCache();
    } else {
      Loading();
    }
  }

  void _initiateTransactionData() {
    if (this.transaction == null) {
      this.transaction = ItemTransaction(0, null, 0.0, 0.0, '');
    }
    if (this.widget.swipeData != null) {
      Item item = this.widget.swipeData;
      this.units = item.units?.keys?.toList() ?? List();
      if (this.units.isNotEmpty) {
        this.units.add('');
      }
    }

    if (this.transaction.id != null) {
      this.itemNumberController.text =
          FormUtils.fmtToIntIfPossible(this.transaction.items);
      this.sellingPriceController.text =
          FormUtils.fmtToIntIfPossible(this.transaction.amount);
      this.costPriceController.text =
          FormUtils.fmtToIntIfPossible(this.transaction.costPrice);
      this.descriptionController.text = this.transaction.description ?? '';
      this.duePriceController.text =
          FormUtils.fmtToIntIfPossible(this.transaction.dueAmount);
      if (this.descriptionController.text.isNotEmpty ||
          (this.transaction.dueAmount ?? 0.0) != 0.0) {
        setState(() {
          this.enableAdvancedFields = true;
        });
      }

      Future<Item> itemFuture = crudHelper.getItemById(
        this.transaction.itemId,
      );
      itemFuture.then((item) {
        if (item == null) {
          setState(() {
            this.disclaimerText =
                'Orphan Transaction: The item associated with this transaction has been deleted';
          });
        } else {
          this.itemNameController.text = '${item.name}';
          this.tempItemId = item.id;
          this._addUnitsIfPresent(item);
        }
      });
    }
  }

  Widget buildForm(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.title;

    return Column(children: <Widget>[
      DropdownButton<String>(
        items: _forms.map((String dropDownStringItem) {
          return DropdownMenuItem<String>(
            value: dropDownStringItem,
            child: Text(dropDownStringItem),
          ); // DropdownMenuItem
        }).toList(),

        onChanged: (String newValueSelected) {
          WindowUtils.navigateToPage(context,
              caller: this.formName, target: newValueSelected);
        }, //onChanged

        value: _currentFormSelected,
      ), // DropdownButton

      Expanded(
          child: Form(
              key: this._formKey,
              child: Padding(
                  padding: EdgeInsets.all(_minimumPadding * 2),
                  child: ListView(children: <Widget>[
                    Visibility(
                      visible: this.disclaimerText.isNotEmpty,
                      child: Padding(
                          padding: EdgeInsets.all(_minimumPadding),
                          child: Text(this.disclaimerText)),
                    ),

                    Visibility(
                      visible: this.widget.swipeData == null ? true : false,
                      child: WindowUtils.genAutocompleteTextField(
                          labelText: "Item name",
                          hintText: "Name of item sold",
                          textStyle: textStyle,
                          controller: itemNameController,
                          getSuggestions: this._getAutoCompleteSuggestions,
                          onChanged: () {
                            return this.updateItemName();
                          },
                          suggestions: this.itemNamesAndNicknames),
                    ),

                    Visibility(
                      visible: stringUnderName.isNotEmpty,
                      child: Padding(
                          padding: EdgeInsets.all(_minimumPadding),
                          child: Text(this.stringUnderName)),
                    ),

                    Row(children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: WindowUtils.genTextField(
                            labelText: "Quantity",
                            hintText: "No of items sold",
                            textStyle: textStyle,
                            controller: this.itemNumberController,
                            keyboardType: TextInputType.number,
                            validator: (String value, String labelText) {
                              if (value == '0.0' ||
                                  value == '0' ||
                                  value.isEmpty) {
                                return "$labelText is empty or zero";
                              } else {
                                return null;
                              }
                            },
                            onChanged: () {}),
                      ),
                      Visibility(
                          visible: this.units.isNotEmpty,
                          child: Padding(
                              padding: EdgeInsets.only(right: 5.0, left: 10.0),
                              child: DropdownButton<String>(
                                items: this.units.map((dropDownStringItem) {
                                  return DropdownMenuItem<String>(
                                    value: dropDownStringItem,
                                    child: Text(dropDownStringItem),
                                  );
                                }).toList(),
                                onChanged: (String newValueSelected) {
                                  setState(() {
                                    this.selectedUnit = newValueSelected;
                                  });
                                },
                                value: this.selectedUnit,
                              ))),
                    ]),

                    WindowUtils.genTextField(
                      labelText: "Total selling price",
                      textStyle: textStyle,
                      controller: this.sellingPriceController,
                      keyboardType: TextInputType.number,
                      onChanged: this.updateSellingPrice,
                    ),

                    Visibility(
                        visible:
                            this.transaction.costPrice == null ? false : true,
                        child: WindowUtils.genTextField(
                          labelText: "Cost price",
                          hintText: "Cost price per item",
                          textStyle: textStyle,
                          controller: this.costPriceController,
                          keyboardType: TextInputType.number,
                          onChanged: this.updateCostPrice,
                        )),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Checkbox(
                            onChanged: (value) {
                              setState(() => this.enableAdvancedFields = value);
                            },
                            value: this.enableAdvancedFields),
                        Text(
                          "Show advanced fields",
                          style: textStyle,
                        ),
                      ],
                    ),

                    Visibility(
                        visible: this.enableAdvancedFields,
                        child: WindowUtils.genTextField(
                            labelText: "Unpaid amount",
                            hintText: "Amount remaining to be collected",
                            textStyle: textStyle,
                            controller: this.duePriceController,
                            keyboardType: TextInputType.number,
                            onChanged: this.updateDuePrice,
                            validator: (value, labelText) {})),

                    Visibility(
                        visible: this.enableAdvancedFields,
                        child: WindowUtils.genTextField(
                            labelText: "Description",
                            hintText: "Any notes for this transaction",
                            textStyle: textStyle,
                            maxLines: 3,
                            controller: this.descriptionController,
                            validator: (value, labelText) {},
                            onChanged: () {
                              return setState(() {
                                this.updateTransactionDescription();
                              });
                            })),

                    // save
                    Padding(
                        padding: EdgeInsets.only(
                            bottom: _minimumPadding * 3,
                            top: 3 * _minimumPadding),
                        child: Row(children: <Widget>[
                          WindowUtils.genButton(
                              context, "Save", this.checkAndSave),
                          Container(
                            width: _minimumPadding,
                          ),
                          WindowUtils.genButton(context, "Delete", this._delete)
                        ]) // Row

                        ), // Paddin
                  ]) //List view
                  ) // Padding
              ))
    ]); // return
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Wrapper();
    }
    return WillPopScope(
        onWillPop: () {
          return WindowUtils.moveToLastScreen(context);
        },
        child: CustomScaffold.setScaffold(context, title, buildForm));
  }

  void updateSellingPrice() {
    this.transaction.amount =
        double.parse(this.sellingPriceController.text).abs();
  }

  void updateCostPrice() {
    this.transaction.costPrice =
        double.parse(this.costPriceController.text).abs();
  }

  void updateDuePrice() {
    double amount = 0.0;
    if (this.duePriceController.text.isNotEmpty) {
      amount = double.parse(this.duePriceController.text).abs();
    }
    this.transaction.dueAmount = amount;
  }

  void updateTransactionDescription() {
    this.transaction.description = this.descriptionController.text;
  }

  void updateItemName() {
    var name = this.itemNameController.text;
    Future<Item> itemFuture = crudHelper.getItem(
      "name",
      name,
    );
    itemFuture.then((item) {
      if (item == null) {
        this.stringUnderName = 'Unregistered name';
        this.tempItemId = null;
        setState(() => this.units = List());
      } else {
        this.stringUnderName = '';
        this.tempItemId = item.id;
        setState(() => this._addUnitsIfPresent(item));
      }
    }, onError: (e) {});
  }

  void clearFieldsAndTransaction() {
    this.itemNameController.text = '';
    this.itemNumberController.text = '';
    this.sellingPriceController.text = '';
    this.costPriceController.text = '';
    this.descriptionController.text = '';
    this.duePriceController.text = '';
    this.enableAdvancedFields = false;
    this.units = List();
    this.selectedUnit = '';
    this.transaction = ItemTransaction(0, null, 0.0, 0.0, '');
  }

  void _addUnitsIfPresent(item) {
    if (item.units != null) {
      this.units = item.units.keys.toList();
      this.units.add('');
    } else {
      this.units = List();
    }
  }

  void checkAndSave() {
    if (this._formKey.currentState.validate()) {
      this._save();
    }
  }

  void _save() async {
    void _alertFail(message) {
      WindowUtils.showAlertDialog(context, "Failed!", message);
    }

    Item item;
    if (this.widget.swipeData != null) {
      item = this.widget.swipeData;
    } else {
      item = await crudHelper
          .getItemById(
        this.tempItemId,
      )
          .catchError((e) {
        return null;
      });
    }

    if (item == null) {
      _alertFail("Item not registered");
      return;
    }

    String itemId = item.id;
    double unitMultiple = 1.0;
    if (this.selectedUnit != '') {
      if (item.units?.containsKey(this.selectedUnit) ?? false) {
        unitMultiple = item.units[this.selectedUnit];
      }
    }
    double items =
        double.parse(this.itemNumberController.text).abs() * unitMultiple;

    // Additional checks.
    if ((this.transaction.id == null && this.transaction.itemId != itemId) ||
        _beingApproved()) {
      // Case insert
      if ((userData.checkStock ?? true) && item.totalStock < items) {
        _alertFail("Empty stock. Cannot sell.");
        return;
      }

      this.transaction.costPrice = item.costPrice;
      item.decreaseStock(items);
    } else {
      double netAddition = items - this.transaction.items;

      if ((userData.checkStock ?? true) && item.totalStock < netAddition) {
        _alertFail("Empty or insufficient stock.\nCannot sell.");
        return;
      } else {
        item.decreaseStock(netAddition);
      }
    }

    this.transaction.itemId = itemId;
    this.transaction.items = items;

    String message = await FormUtils.saveTransactionAndUpdateItem(
        this.transaction, item,
        userData: userData);

    this.saveCallback(message);
  }

  bool _beingApproved() {
    return FormUtils.isDatabaseOwner(userData) &&
        !FormUtils.isTransactionOwner(userData, this.transaction);
  }

  void _delete() async {
    if (this.transaction.id == null) {
      this.clearFieldsAndTransaction();
      WindowUtils.showAlertDialog(context, "Status", 'Item not created');
      return;
    } else {
      Item item = await crudHelper.getItemById(this.transaction.itemId);

      WindowUtils.showAlertDialog(context, "Delete?",
          "This action is very dangerous and you may lose vital information. Delete?",
          onPressed: (buildContext) {
        FormUtils.deleteTransactionAndUpdateItem(
            this.saveCallback, this.transaction, item, userData);
      });
    }
  }

  void saveCallback(String message) {
    if (message.isEmpty) {
      this.clearFieldsAndTransaction();
      if (this.widget.forEdit ?? false) {
        WindowUtils.moveToLastScreen(this.context, modified: true);
      }

      WindowUtils.showAlertDialog(
          this.context, "Status", 'Sales updated successfully');
    } else {
      WindowUtils.showAlertDialog(this.context, 'Failed!', message);
    }
  }

  void _initializeItemNamesAndNicknamesMapCache() async {
    Map itemMap = await StartupCache().itemMap;
    // ignore: deprecated_member_use
    List<Map> cacheItemAndNickNames = List<Map>();
    if (itemMap.isNotEmpty) {
      itemMap.forEach((key, value) {
        Map nameNickNameMap = {'name': value.first, 'nickName': value.last};
        cacheItemAndNickNames.add(nameNickNameMap);
      });
    }

    setState(() {
      this.itemNamesAndNicknames = cacheItemAndNickNames;
    });
  }

  List<Map> _getAutoCompleteSuggestions() {
    return this.itemNamesAndNicknames;
  }
}
