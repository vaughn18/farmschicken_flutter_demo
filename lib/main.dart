import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import 'amplifyconfiguration.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Farms Chicken Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> itemList = [];
  String _scanBarcode = 'Unknown';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _configureAmplify();
    fetchData();
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      print(barcodeScanRes);
      await createTodo();
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  void _configureAmplify() async {
    // Add the following line to add API plugin to your app
    Amplify.addPlugin(AmplifyAPI());

    try {
      await Amplify.configure(amplifyconfig);
    } on AmplifyAlreadyConfiguredException {
      print(
          "Tried to reconfigure Amplify; this can occur when your app restarts on Android.");
    }
  }

  Stream<dynamic> subscribeToData() {
    try {
      String graphQLDocument = '''subscription OnCreateTodo {
        onCreateTodo {
          id
          itemName
          createdAt
          updatedAt
        }
      }''';

      var operation = Amplify.API.subscribe(
          request: GraphQLRequest<String>(document: graphQLDocument),
          onData: (event) {
            print('Subscription event data received: ${event.data}');
            var extractedData = json.decode(event.data);
            return extractedData;
          },
          onEstablished: () {
            print('Subscription established');
            return;
          },
          onError: (e) {
            print('Subscription failed with error: $e');
            return;
          },
          onDone: () {
            print('Subscription has been closed successfully');
            return;
          });
    } on ApiException catch (e) {
      print('Failed to establish subscription: $e');
    }
  }

  Future<void> fetchData() async {
    try {
      String graphQLDocument = '''query ListTodos {
      listTodos {
        items {
          id
          itemName
          createdAt
          updatedAt
        }
        nextToken
      }
    }''';

      var operation = Amplify.API.query(
          request: GraphQLRequest<String>(
        document: graphQLDocument,
      ));

      var response = await operation.response;
      var data = response.data;
      var decodedData = json.decode(data);
      setState(() {
        itemList = decodedData['listTodos']['items'];
      });

      print(itemList);
    } on ApiException catch (e) {
      print('Query failed: $e');
    }
  }

  createTodo() async {
    try {
      String graphQLDocument = '''mutation CreateTodo(\$itemName: String!) {
              createTodo(input: {itemName: \$itemName}) {
                id
                itemName
                createdAt
                updatedAt
              }
        }''';
      var variables = {
        "itemName": "An Order is Scanned",
      };
      var request = GraphQLRequest<String>(
          document: graphQLDocument, variables: variables);

      var operation = Amplify.API.mutate(request: request);
      var response = await operation.response;

      var data = response.data;

      print('Mutation result: ' + data);
    } on ApiException catch (e) {
      print('Mutation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: Icon(Icons.scanner), onPressed: scanQR),
          IconButton(icon: Icon(Icons.refresh), onPressed: fetchData)
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // FutureBuilder(
            //     future: fetchData(),
            //     builder: (ctx, dataSnapshot) {
            //       if (dataSnapshot.connectionState == ConnectionState.waiting) {
            //         return Center(
            //           child: CircularProgressIndicator(
            //             valueColor:
            //                 new AlwaysStoppedAnimation<Color>(Colors.orange),
            //           ),
            //         );
            //       } else {
            //         if (dataSnapshot.error != null) {
            //           return Center(
            //             child: Text('an error occured'),
            //           );
            //         } else {
            //           return ListView.builder(itemBuilder: (_, i) {
            //             return ListTile(
            //               title: Text('Order'),
            //               subtitle: Text(itemList[i]['itemName']),
            //               trailing: IconButton(
            //                 onPressed: () {},
            //                 icon: Icon(Icons.panorama_fish_eye),
            //               ),
            //             );
            //           });
            //         }
            //       }
            //     })
            Container(
              height: 500,
              child: ListView.builder(
                itemCount: itemList.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text('Order'),
                  subtitle: Text(itemList[i]['itemName']),
                  trailing: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.panorama_fish_eye,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
