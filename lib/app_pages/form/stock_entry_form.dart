import 'package:flutter/material.dart';
import 'package:inventorysystem/app_pages/wrapper.dart';
import 'package:inventorysystem/models/items.dart';
import 'package:inventorysystem/models/transaction.dart';
import 'package:inventorysystem/models/user.dart';
import 'package:inventorysystem/services/crud.dart';
import 'package:inventorysystem/utils/cache.dart';
import 'package:inventorysystem/utils/form.dart';
import 'package:inventorysystem/utils/scaffold.dart';
import 'package:provider/provider.dart';
import 'package:inventorysystem/utils/window.dart';

class StockEntryForm extends StatefulWidget {
  final String title;
  final ItemTransaction transaction;
  final bool forEdit;
  final Item swipeData;

  StockEntryForm({this.transaction, this.title, this.forEdit, this.swipeData});

  @override
  State<StatefulWidget> createState() {
    return _StockEntryFormState(this.title, this.transaction);
  }
}

class _StockEntryFormState extends State<StockEntryForm> {
  String title;
  ItemTransaction transaction;
  _StockEntryFormState(this.title, this.transaction);

  var _formKey = GlobalKey<FormState>();
  final double _minimumPadding = 5.0;
  static CrudHelper crudHelper;
  static UserData userData;

  List<String> _forms = ['Sales Entry', 'Stock Entry', 'Item Entry'];
  String formName;
  String disclaimerText = '';
  String stringUnderName = '';
  String _currentFormSelected;
  String tempItemId;
  List<Map> itemNamesAndNicknames = List<Map>();
  bool enableAdvancedFields = false;

  List units = List();
  String selectedUnit = '';
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemNumberController = TextEditingController();
  TextEditingController costPriceController = TextEditingController();
  TextEditingController markedPriceController = TextEditingController();
  TextEditingController duePriceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    this.formName = _forms[1];
    this._currentFormSelected = formName;
    _initializeItemNamesAndNicknamesMapCache();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userData = Provider.of<UserData>(context, listen: false);
    if (userData != null) {
      crudHelper = CrudHelper(userData: userData);
      _initiateTransactionData();
    }
  }

  void _initiateTransactionData() {
    if (this.transaction == null) {
      this.transaction = ItemTransaction(1, null, 0.0, 0.0, '');
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
      this.costPriceController.text =
          FormUtils.fmtToIntIfPossible(this.transaction.amount);
      this.descriptionController.text = this.transaction.description ?? '';
      this.duePriceController.text =
          FormUtils.fmtToIntIfPossible(this.transaction.dueAmount);
      if (this.descriptionController.text.isNotEmpty ||
          this.duePriceController.text.isNotEmpty) {
        this.enableAdvancedFields = true;
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
          this.markedPriceController.text = item.markedPrice;
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
          );
        }).toList(),
        onChanged: (String newValueSelected) {
          WindowUtils.navigateToPage(context,
              caller: this.formName, target: newValueSelected);
        },
        value: _currentFormSelected,
      ),
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
                            hintText: "Name of item you bought",
                            textStyle: textStyle,
                            controller: itemNameController,
                            getSuggestions: this._getAutoCompleteSuggestions,
                            onChanged: () {
                              return this.updateItemName();
                            },
                            suggestions: this.itemNamesAndNicknames)),
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
                            hintText: "No of items",
                            textStyle: textStyle,
                            controller: this.itemNumberController,
                            keyboardType: TextInputType.number,
                            validator: (String value, String labelText) {
                              if (value == '0.0' ||
                                  value == '0' ||
                                  value.isEmpty) {
                                return 'Quantity is zero or empty';
                              } else {
                                return null;
                              }
                            },
                            onChanged: () {},
                          )),
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
                                  this.selectedUnit = newValueSelected;
                                },
                                value: this.selectedUnit,
                              ))),
                    ]),
                    WindowUtils.genTextField(
                      labelText: "Total cost price",
                      textStyle: textStyle,
                      controller: this.costPriceController,
                      keyboardType: TextInputType.number,
                      onChanged: () {},
                    ),
                    WindowUtils.genTextField(
                      labelText: "Expected selling price",
                      hintText: "Price per item",
                      textStyle: textStyle,
                      controller: this.markedPriceController,
                      keyboardType: TextInputType.number,
                      onChanged: () {},
                    ),
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
                    Padding(
                        padding: EdgeInsets.only(
                            bottom: 3 * _minimumPadding,
                            top: 3 * _minimumPadding),
                        child: Row(children: <Widget>[
                          WindowUtils.genButton(
                              this.context, "Save", this.checkAndSave),
                          Container(
                            width: 5.0,
                          ),
                          WindowUtils.genButton(
                              this.context, "Delete", this._delete)
                        ])),
                  ]))))
    ]);
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
        child: CustomScaffold.setScaffold(context, this.title, buildForm));
  }

  void updateItemName() {
    String name = this.itemNameController.text;
    Future<Item> itemFuture = crudHelper.getItem(
      "name",
      name,
    );
    itemFuture.then((item) {
      if (item == null) {
        this.stringUnderName = 'Unregistered item';
        this.tempItemId = null;
        setState(() => this.units = List());
      } else {
        this.stringUnderName = '';
        this.tempItemId = item.id;
        setState(() => this._addUnitsIfPresent(item));
      }
    }, onError: (e) {});
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

  void clearFieldsAndTransaction() {
    this.itemNameController.text = '';
    this.itemNumberController.text = '';
    this.costPriceController.text = '';
    this.markedPriceController.text = '';
    this.duePriceController.text = '';
    this.descriptionController.text = '';
    this.enableAdvancedFields = false;
    this.units = List();
    this.selectedUnit = '';
    this.transaction = ItemTransaction(1, null, 0.0, 0.0, '');
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
    Item item;

    if (this.widget.swipeData != null) {
      item = this.widget.swipeData;
    } else {
      item = await crudHelper.getItemById(
        this.tempItemId,
      );
    }

    if (item == null) {
      WindowUtils.showAlertDialog(
          this.context, "Failed!", "Item not registered");
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
    double totalCostPrice = double.parse(this.costPriceController.text).abs();

    if (this.transaction.id != null &&
        this.transaction.itemId == itemId &&
        !_beingApproved()) {
      if (item.lastStockEntry == this.transaction.date) {
        if (userData.checkStock ?? true) {
          item.modifyLatestStockEntry(this.transaction, items, totalCostPrice);
        } else {
          item.costPrice = totalCostPrice / items;
        }
      }
    } else {
      if (userData.checkStock ?? true) {
        var newCpAndTotalStock =
            item.getNewCostPriceAndStock(totalCostPrice, items);
        item.costPrice = newCpAndTotalStock[0];
        item.totalStock = newCpAndTotalStock[1];
      } else {
        item.costPrice = totalCostPrice / items;
      }
    }

    this.transaction.itemId = itemId;
    this.transaction.items = items;
    item.markedPrice = this.markedPriceController.text;
    this.transaction.amount = totalCostPrice;

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
      Item item = await crudHelper.getItemById(
        this.transaction.itemId,
      );

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
          this.context, "Status", 'Stock updated successfully');
    } else {
      WindowUtils.showAlertDialog(this.context, 'Failed!', message);
    }
  }

  void _initializeItemNamesAndNicknamesMapCache() async {
    Map itemMap = await StartupCache().itemMap;
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
