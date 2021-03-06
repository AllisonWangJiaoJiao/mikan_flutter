import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_sliver/extended_sliver.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mikan_flutter/internal/extension.dart';
import 'package:mikan_flutter/internal/screen.dart';
import 'package:mikan_flutter/mikan_flutter_routes.dart';
import 'package:mikan_flutter/model/bangumi_row.dart';
import 'package:mikan_flutter/model/carousel.dart';
import 'package:mikan_flutter/model/record_item.dart';
import 'package:mikan_flutter/model/season.dart';
import 'package:mikan_flutter/model/user.dart';
import 'package:mikan_flutter/providers/view_models/index_model.dart';
import 'package:mikan_flutter/providers/view_models/op_model.dart';
import 'package:mikan_flutter/ui/components/ova_record_item.dart';
import 'package:mikan_flutter/ui/fragments/bangumi_sliver_grid_fragment.dart';
import 'package:mikan_flutter/ui/fragments/search_fragment.dart';
import 'package:mikan_flutter/ui/fragments/select_season_fragment.dart';
import 'package:mikan_flutter/widget/animated_widget.dart';
import 'package:mikan_flutter/widget/common_widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

@immutable
class IndexFragment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final IndexModel indexModel =
        Provider.of<IndexModel>(context, listen: false);
    return Scaffold(
      body: NotificationListener(
        onNotification: (notification) {
          if (notification is OverscrollIndicatorNotification) {
            notification.disallowGlow();
          } else if (notification is ScrollUpdateNotification) {
            if (notification.depth == 0) {
              final double offset = notification.metrics.pixels;
              indexModel.hasScrolled = offset > 0.0;
            }
          }
          return true;
        },
        child: Selector<IndexModel, List<BangumiRow>>(
          selector: (_, model) => model.bangumiRows,
          shouldRebuild: (pre, next) => pre.ne(next),
          builder: (_, bangumiRows, __) {
            if (bangumiRows.isNullOrEmpty && indexModel.seasonLoading) {
              return Center(
                child: CupertinoActivityIndicator(),
              );
            }
            return SmartRefresher(
              controller: indexModel.refreshController,
              enablePullUp: false,
              enablePullDown: true,
              header: WaterDropMaterialHeader(
                backgroundColor: theme.accentColor,
                color: theme.accentColor.computeLuminance() < 0.5
                    ? Colors.white
                    : Colors.black,
                distance: Sz.statusBarHeight + 42.0,
              ),
              onRefresh: indexModel.refresh,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(context, theme),
                  _buildCarousels(theme, indexModel),
                  _buildOVASection(),
                  _buildOVAList(theme),
                  ...List.generate(bangumiRows.length, (index) {
                    final BangumiRow bangumiRow = bangumiRows[index];
                    return [
                      _buildWeekSection(theme, bangumiRow),
                      BangumiSliverGridFragment(
                        padding: EdgeInsets.all(16.0),
                        bangumis: bangumiRow.bangumis,
                        handleSubscribe: (bangumi) {
                          context.read<OpModel>().subscribeBangumi(
                                bangumi.id,
                                bangumi.subscribed,
                                onSuccess: () {},
                                onError: (msg) {},
                              );
                        },
                      ),
                    ];
                  }).expand((element) => element),
                  CommonWidgets.sliverBottomSpace,
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeekSection(
    final ThemeData theme,
    final BangumiRow bangumiRow,
  ) {
    final simple = [
      if (bangumiRow.updatedNum > 0) "🚀 ${bangumiRow.updatedNum}部",
      if (bangumiRow.subscribedUpdatedNum > 0)
        "💖 ${bangumiRow.subscribedUpdatedNum}部",
      if (bangumiRow.subscribedNum > 0) "❤ ${bangumiRow.subscribedNum}部",
      "🎬 ${bangumiRow.num}部"
    ].join("，");
    final full = [
      if (bangumiRow.updatedNum > 0) "更新${bangumiRow.updatedNum}部",
      if (bangumiRow.subscribedUpdatedNum > 0)
        "订阅更新${bangumiRow.subscribedUpdatedNum}部",
      if (bangumiRow.subscribedNum > 0) "订阅${bangumiRow.subscribedNum}部",
      "共${bangumiRow.num}部"
    ].join("，");

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: 8.0,
          left: 16.0,
          right: 16.0,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Text(
                bangumiRow.name,
                style: TextStyle(
                  fontSize: 20.0,
                  height: 1.25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Tooltip(
              message: full,
              child: Text(
                simple,
                style: TextStyle(
                  color: theme.textTheme.subtitle1.color,
                  fontSize: 12.0,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOVASection() {
    return Selector<IndexModel, List<RecordItem>>(
      selector: (_, model) => model.ovas,
      shouldRebuild: (pre, next) => pre.ne(next),
      builder: (_, ovas, child) {
        if (ovas.isSafeNotEmpty) return child;
        return SliverToBoxAdapter();
      },
      child: SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 8.0,
          ),
          child: Text(
            "OVA/剧场版 (beta)",
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousels(final ThemeData theme, final IndexModel indexModel) {
    return Selector<IndexModel, List<Carousel>>(
      selector: (_, model) => model.carousels,
      shouldRebuild: (pre, next) => pre.ne(next),
      builder: (context, carousels, __) {
        if (carousels.isNotEmpty)
          return SliverToBoxAdapter(
            child: CarouselSlider.builder(
              itemBuilder: (context, index) {
                final carousel = carousels[index];
                final String currFlag =
                    "carousel:${carousel.id}:${carousel.cover}";
                return _buildCarouselsItem(
                  theme,
                  currFlag,
                  carousel,
                  indexModel,
                );
              },
              itemCount: carousels.length,
              options: CarouselOptions(
                height: 180,
                aspectRatio: 16 / 9,
                viewportFraction: 0.8,
                autoPlay: true,
                enlargeCenterPage: true,
              ),
            ),
          );
        return SliverToBoxAdapter();
      },
    );
  }

  Widget _buildCarouselsItem(
    final ThemeData theme,
    final String currFlag,
    final Carousel carousel,
    final IndexModel indexModel,
  ) {
    return Selector<IndexModel, String>(
      selector: (_, model) => model.tapBangumiCarouselItemFlag,
      shouldRebuild: (pre, next) => pre != next,
      builder: (context, tapScaleFlag, child) {
        final Matrix4 transform = tapScaleFlag == currFlag
            ? Matrix4.diagonal3Values(0.8, 0.8, 1)
            : Matrix4.identity();
        return Hero(
          tag: currFlag,
          child: AnimatedTapContainer(
            transform: transform,
            onTapStart: () => indexModel.tapBangumiCarouselItemFlag = currFlag,
            onTapEnd: () => indexModel.tapBangumiCarouselItemFlag = null,
            onTap: () {
              Navigator.pushNamed(
                context,
                Routes.bangumi.name,
                arguments: Routes.bangumi.d(
                  heroTag: currFlag,
                  bangumiId: carousel.id,
                  cover: carousel.cover,
                ),
              );
            },
            margin: EdgeInsets.only(top: 16.0, bottom: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              color: theme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.08),
                )
              ],
              image: DecorationImage(
                fit: BoxFit.cover,
                image: ExtendedNetworkImageProvider(
                  carousel.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(final BuildContext context, final ThemeData theme) {
    return SliverPinnedToBoxAdapter(
      child: Selector<IndexModel, bool>(
        selector: (_, model) => model.hasScrolled,
        shouldRebuild: (pre, next) => pre != next,
        builder: (_, hasScrolled, child) {
          return AnimatedContainer(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0 + Sz.statusBarHeight,
              bottom: 4.0,
            ),
            decoration: BoxDecoration(
              color: hasScrolled
                  ? theme.backgroundColor
                  : theme.scaffoldBackgroundColor,
              borderRadius: hasScrolled
                  ? BorderRadius.only(
                      bottomLeft: Radius.circular(16.0),
                      bottomRight: Radius.circular(16.0),
                    )
                  : null,
              boxShadow: hasScrolled
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.024),
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        spreadRadius: 3.0,
                      ),
                    ]
                  : null,
            ),
            duration: Duration(milliseconds: 240),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Selector<IndexModel, User>(
                        selector: (_, model) => model.user,
                        shouldRebuild: (pre, next) => pre != next,
                        builder: (_, user, __) {
                          final withoutName =
                              user == null || user.name.isNullOrBlank;
                          return Text(
                            withoutName ? "Mikan Project" : "Hi, ${user.name}",
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.25,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      _buildSeasonSelector(context, theme, hasScrolled)
                    ],
                  ),
                ),
                MaterialButton(
                  onPressed: () {
                    _showSearchPanel(context);
                  },
                  child: Icon(FluentIcons.search_24_regular),
                  minWidth: 0,
                  padding: EdgeInsets.all(10.0),
                  shape: CircleBorder(),
                ),
                MaterialButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(Routes.login);
                  },
                  child: _buildAvatar(),
                  minWidth: 0,
                  padding: EdgeInsets.all(10.0),
                  shape: CircleBorder(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeasonSelector(
    final BuildContext context,
    final ThemeData theme,
    final bool hasScrolled,
  ) {
    return Row(
      children: [
        Selector<IndexModel, Season>(
          selector: (_, model) => model.selectedSeason,
          shouldRebuild: (pre, next) => pre != next,
          builder: (_, season, __) {
            return season == null
                ? Container()
                : Text(
                    season.title,
                    style: TextStyle(
                      fontSize: 24.0,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                    ),
                  );
          },
        ),
        MaterialButton(
          onPressed: () {
            _showYearSeasonBottomSheet(context);
          },
          child: Icon(
            FluentIcons.chevron_down_24_regular,
            size: 16.0,
          ),
          minWidth: 0,
          color: hasScrolled
              ? theme.scaffoldBackgroundColor
              : theme.backgroundColor,
          padding: EdgeInsets.all(5.0),
          shape: CircleBorder(),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Selector<IndexModel, User>(
      selector: (_, model) => model.user,
      shouldRebuild: (pre, next) => pre != next,
      builder: (_, user, __) {
        return user?.avatar?.isNotBlank == true
            ? ClipOval(
                child: ExtendedImage.network(
                  user?.avatar,
                  width: 36.0,
                  height: 36.0,
                  loadStateChanged: (state) {
                    switch (state.extendedImageLoadState) {
                      case LoadState.loading:
                      case LoadState.failed:
                        return ExtendedImage.asset(
                          "assets/mikan.png",
                          width: 36.0,
                          height: 36.0,
                        );
                      case LoadState.completed:
                        return null;
                    }
                    return null;
                  },
                ),
              )
            : ExtendedImage.asset(
                "assets/mikan.png",
                width: 36.0,
                height: 36.0,
              );
      },
    );
  }

  Future _showYearSeasonBottomSheet(final BuildContext context) {
    return showCupertinoModalBottomSheet(
      context: context,
      topRadius: Radius.circular(16.0),
      builder: (_) {
        return SelectSeasonFragment();
      },
    );
  }

  Widget _buildOVAList(final ThemeData theme) {
    return Selector<IndexModel, List<RecordItem>>(
      selector: (_, model) => model.ovas,
      shouldRebuild: (pre, next) => pre.ne(next),
      builder: (context, records, __) {
        if (records.isNullOrEmpty) return SliverToBoxAdapter();
        return SliverToBoxAdapter(
          child: Container(
            height: 192.0,
            padding: EdgeInsets.only(bottom: 16.0, top: 16.0),
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: records.length,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 16.0),
              itemBuilder: (context, index) {
                final RecordItem record = records[index];
                final String currFlag = "ova:$index";
                return Selector<IndexModel, String>(
                  selector: (_, model) => model.tapBangumiOVAItemFlag,
                  shouldRebuild: (pre, next) => pre != next,
                  builder: (_, tapScaleFlag, __) {
                    final Matrix4 transform = tapScaleFlag == currFlag
                        ? Matrix4.diagonal3Values(0.9, 0.9, 1)
                        : Matrix4.identity();
                    return OVARecordItem(
                      index: index,
                      record: record,
                      theme: theme,
                      transform: transform,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.recordDetail.name,
                          arguments: Routes.recordDetail.d(url: record.url),
                        );
                      },
                      onTapStart: () {
                        context.read<IndexModel>().tapBangumiOVAItemFlag =
                            currFlag;
                      },
                      onTapEnd: () {
                        context.read<IndexModel>().tapBangumiOVAItemFlag = null;
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  _showSearchPanel(final BuildContext context) {
    showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      bounce: true,
      enableDrag: false,
      topRadius: Radius.circular(16.0),
      builder: (_) {
        return SearchFragment();
      },
    );
  }
}
