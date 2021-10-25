import 'package:flutter/material.dart';

class showImage extends StatefulWidget {
  //const showImage({Key? key}) : super(key: key);
  String title,imageUrl;
  showImage(this.title,this.imageUrl);

  @override
  _showImageState createState() => _showImageState(title,imageUrl);
}

class _showImageState extends State<showImage> {
  String imageUrl;
  String title;
  _showImageState(this.title,this.imageUrl);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
      ),
      backgroundColor: Colors.black,
      body: Center(child: Image.network(imageUrl)),
    );
  }
}
