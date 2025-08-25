import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  @override
  _PaginatedListExampleState createState() => _PaginatedListExampleState();
}

class _PaginatedListExampleState extends State<TestPage> {
  final ScrollController _scrollController = ScrollController();
  List<int> _items = [];
  int _page = 0;
  final int _limit = 20;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMore();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);

    // symulacja API call
    await Future.delayed(Duration(seconds: 1));

    final newItems =
    List.generate(_limit, (index) => _page * _limit + index);

    setState(() {
      print(newItems);
      _items.addAll(newItems);
      _page++;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lista z paginacją")),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + 1, // +1 dla loadera
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _isLoading
                ? Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()))
                : SizedBox();
          }
          return ListTile(
            title: Text("Element ${_items[index]}"),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
