import 'dart:typed_data';

import 'package:at_contacts_group_flutter/widgets/contacts_initials.dart';
import 'package:at_contacts_group_flutter/widgets/custom_circle_avatar.dart';
import 'package:flutter/material.dart';
import 'package:at_common_flutter/at_common_flutter.dart';

class CustomPersonHorizontalTile extends StatelessWidget {
  final String title, subTitle;
  final bool isTopRight;
  final IconData icon;
  List<dynamic> image;

  CustomPersonHorizontalTile({
    this.image,
    this.title,
    this.subTitle,
    this.isTopRight = false,
    this.icon,
  }) {
    if (image != null) {
      List<int> intList = image.cast<int>();
      image = Uint8List.fromList(intList);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      child: Row(
        children: <Widget>[
          Stack(
            children: [
              image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      child: Image.memory(
                        image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.fill,
                      ),
                    )
                  : ContactInitial(initials: title.substring(0, 2)),
              icon != null
                  ? Positioned(
                      top: isTopRight ? 0 : null,
                      right: 0,
                      bottom: !isTopRight ? 0 : null,
                      child: Icon(icon))
                  : SizedBox(),
            ],
          ),
          SizedBox(width: 10.toHeight),
          Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: title != null
                      ? Text(
                          title,
                          style: Theme.of(context).textTheme.headline3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : SizedBox(),
                ),
                SizedBox(height: 5.toHeight),
                subTitle != null
                    ? Text(
                        subTitle,
                        style: Theme.of(context).textTheme.headline4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : SizedBox(),
              ],
            ),
          )
        ],
      ),
    );
  }
}