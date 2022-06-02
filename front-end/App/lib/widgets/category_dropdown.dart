import 'package:flutter/material.dart';

class CategoryDropDown extends StatelessWidget {
  final List<String> categories;
  final Function executeOnChange;
  final String currentItem;

  CategoryDropDown(this.categories, this.executeOnChange, this.currentItem);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: DropdownButton<String>(
        alignment: Alignment.center,
        items: categories.map((String item) {
          return DropdownMenuItem<String>(
            child: Text(item),
            value: item,
          );
        }).toList(),
        onChanged: (String? newItem) {
          executeOnChange(newItem!);
        },
        value: currentItem,
        icon: const Icon(Icons.filter_list_rounded),
      ),
    );
  }
}
