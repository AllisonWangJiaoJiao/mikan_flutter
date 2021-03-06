import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mikan_flutter/internal/extension.dart';
import 'package:mikan_flutter/internal/screen.dart';
import 'package:mikan_flutter/model/record_item.dart';
import 'package:mikan_flutter/widget/animated_widget.dart';

@immutable
class OVARecordItem extends StatelessWidget {
  final int index;
  final Matrix4 transform;
  final RecordItem record;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onTapStart;
  final VoidCallback onTapEnd;

  const OVARecordItem({
    @required this.index,
    @required this.record,
    @required this.transform,
    @required this.onTap,
    @required this.onTapStart,
    @required this.onTapEnd,
    @required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle fileTagStyle = TextStyle(
      fontSize: 10,
      height: 1.25,
      color: theme.accentColor.computeLuminance() < 0.5
          ? Colors.white
          : Colors.black,
    );
    final TextStyle titleTagStyle = TextStyle(
      fontSize: 10,
      height: 1.25,
      color: theme.primaryColor.computeLuminance() < 0.5
          ? Colors.white
          : Colors.black,
    );
    return AnimatedTapContainer(
      width: Sz.screenWidth * 0.9 - 32.0,
      onTap: onTap,
      onTapEnd: onTapEnd,
      onTapStart: onTapStart,
      transform: transform,
      margin: EdgeInsets.only(
        right: 16.0,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
            ),
            child: Text(
              record.publishAt,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 8.0,
            ),
            child: Text(
              record.title + "\n",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.0,
                height: 1.25,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 8.0,
            ),
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  theme.backgroundColor.withOpacity(0),
                  theme.backgroundColor
                ],
                stops: [0.8, 1],
              ),
            ),
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      right: 4.0,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.accentColor,
                          theme.accentColor.withOpacity(0.56),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    child: Text(
                      record.size,
                      style: fileTagStyle,
                    ),
                  ),
                  if (!record.tags.isNullOrEmpty)
                    ...List.generate(record.tags.length, (index) {
                      return Container(
                        margin: EdgeInsets.only(
                          right: 4.0,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.56),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                        child: Text(
                          record.tags[index],
                          style: titleTagStyle,
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(
                icon: Icon(FluentIcons.cloud_download_24_regular),
                tooltip: "复制并尝试打开种子链接",
                color: theme.accentColor,
                iconSize: 20.0,
                onPressed: () {
                  record.torrent.launchAppAndCopy();
                  record.torrent.copy();
                },
              ),
              IconButton(
                icon: Icon(FluentIcons.clipboard_link_24_regular),
                color: theme.accentColor,
                tooltip: "复制并尝试打开磁力链接",
                iconSize: 20.0,
                onPressed: () {
                  record.magnet.launchAppAndCopy();
                  record.magnet.copy();
                },
              ),
              IconButton(
                icon: Icon(FluentIcons.share_24_regular),
                color: theme.accentColor,
                tooltip: "分享",
                iconSize: 20.0,
                onPressed: () {
                  record.shareString().share();
                },
              ),
              // IconButton(
              //   icon: Icon(FluentIcons.star_24_regular),
              //   color: accentColor,
              //   tooltip: "收藏",
              //   iconSize: 20.0,
              //   onPressed: () {},
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
