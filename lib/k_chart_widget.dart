import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_chart/chart_translations.dart';
import 'package:k_chart/extension/map_ext.dart';
import 'package:k_chart/flutter_k_chart.dart';
import 'dart:typed_data';
import 'dart:ui' as UI;

enum MainState { MA, BOLL, NONE }
enum SecondaryState { MACD, KDJ, RSI, WR, CCI, NONE }

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const List<String> DAY_MONTH_YEAR = [dd, '/', mm, '/', yy];
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];
}

class KChartWidget extends StatefulWidget {
  final List<KLineEntity>? datas;
  final double? nowPrice;
  final MainState mainState;
  final bool volHidden;
  final SecondaryState secondaryState;
  final Function()? onSecondaryTap;
  final bool isLine;
  final bool hideGrid;
  @Deprecated('Use `translations` instead.')
  final bool isChinese;
  final bool showNowPrice;
  final bool showInfoDialog;
  final Map<String, ChartTranslations> translations;
  final List<String> timeFormat;

  //当屏幕滚动到尽头会调用，真为拉到屏幕右侧尽头，假为拉到屏幕左侧尽头
  final Function(bool)? onLoadMore;

  final int fixedLength;
  final List<int> maDayList;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final ChartColors chartColors;
  final ChartStyle chartStyle;
  final bool detailsEnabled;

  KChartWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
    this.nowPrice,
    this.mainState = MainState.MA,
    this.secondaryState = SecondaryState.MACD,
    this.onSecondaryTap,
    this.volHidden = false,
    this.isLine = false,
    this.hideGrid = false,
    @Deprecated('Use `translations` instead.') this.isChinese = false,
    this.showNowPrice = true,
    this.showInfoDialog = true,
    this.translations = kChartTranslations,
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.detailsEnabled = false,
    this.isOnDrag,
  });

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  StreamController<InfoWindowEntity?>? mInfoWindowStream;
  double mHeight = 0, mWidth = 0;
  AnimationController? _controller;
  Animation<double>? aniX;

  double getMinScrollX() {
    return mScaleX;
  }

  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false;

  @override
  void initState() {
    super.initState();
    mInfoWindowStream = StreamController<InfoWindowEntity?>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    mInfoWindowStream?.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<UI.Image> loadUiImage() async {
    final byteData =
        await rootBundle.load('packages/k_chart/assets/currency_coin.png');
    final Completer<UI.Image> completer = Completer();
    UI.decodeImageFromList(Uint8List.view(byteData.buffer), (UI.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadUiImage(),
      builder: (context, data) {
        if (!data.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        if (widget.datas != null && widget.datas!.isEmpty) {
          mScrollX = mSelectX = 0.0;
          mScaleX = 1.0;
        }
        final _painter = ChartPainter(
          widget.chartStyle,
          widget.chartColors,
          datas: widget.datas,
          nowPrice: widget.nowPrice,
          scaleX: mScaleX,
          scrollX: mScrollX,
          selectX: mSelectX,
          isLongPass: isLongPress,
          mainState: widget.mainState,
          volHidden: widget.volHidden,
          secondaryState: widget.secondaryState,
          isLine: widget.isLine,
          hideGrid: widget.hideGrid,
          showNowPrice: widget.showNowPrice,
          sink: mInfoWindowStream?.sink,
          fixedLength: widget.fixedLength,
          currencyImage: data.data as UI.Image,
          maDayList: widget.maDayList,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            mHeight = constraints.maxHeight;
            mWidth = constraints.maxWidth;

            return GestureDetector(
              onTapUp: (details) {
                if (widget.onSecondaryTap != null &&
                    _painter.isInSecondaryRect(details.localPosition)) {
                  widget.onSecondaryTap!();
                }
              },
              onHorizontalDragDown: (details) {
                _stopAnimation();
                _onDragChanged(true);
              },
              onHorizontalDragUpdate: (details) {
                if (isScale || isLongPress) return;
                mScrollX = (details.primaryDelta! / mScaleX + mScrollX)
                    .clamp(0.0, ChartPainter.maxScrollX)
                    .toDouble();
                notifyChanged();
              },
              onHorizontalDragEnd: (DragEndDetails details) {
                var velocity = details.velocity.pixelsPerSecond.dx;
                _onFling(velocity);
              },
              onHorizontalDragCancel: () => _onDragChanged(false),
              onScaleStart: (_) {
                isScale = true;
              },
              onScaleUpdate: (details) {
                if (isDrag || isLongPress) return;
                mScaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
                notifyChanged();
              },
              onScaleEnd: (_) {
                isScale = false;
                _lastScale = mScaleX;
              },
              onLongPressStart: (details) {
                if (widget.detailsEnabled) {
                  isLongPress = true;
                  if (mSelectX != details.globalPosition.dx) {
                    mSelectX = details.globalPosition.dx;
                    notifyChanged();
                  }
                }
              },
              onLongPressMoveUpdate: (details) {
                if (widget.detailsEnabled) {
                  if (mSelectX != details.globalPosition.dx) {
                    mSelectX = details.globalPosition.dx;
                    notifyChanged();
                  }
                }
              },
              onLongPressEnd: (details) {
                if (widget.detailsEnabled) {
                  isLongPress = false;
                  mInfoWindowStream?.sink.add(null);
                  notifyChanged();
                }
              },
              child: Stack(
                children: <Widget>[
                  CustomPaint(
                    size: Size(double.infinity, double.infinity),
                    painter: _painter,
                  ),
                  if (widget.showInfoDialog) _buildInfoDialog()
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double x) {
    _controller = AnimationController(
        duration: Duration(milliseconds: widget.flingTime), vsync: this);
    aniX = null;
    aniX = Tween<double>(begin: mScrollX, end: x * widget.flingRatio + mScrollX)
        .animate(CurvedAnimation(
            parent: _controller!.view, curve: widget.flingCurve));
    aniX!.addListener(() {
      mScrollX = aniX!.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      }
      notifyChanged();
    });
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });
    _controller!.forward();
  }

  void notifyChanged() => setState(() {});

  late List<String> infos;

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
        stream: mInfoWindowStream?.stream,
        builder: (context, snapshot) {
          if (!isLongPress ||
              widget.isLine == true ||
              !snapshot.hasData ||
              snapshot.data?.kLineEntity == null) return Container();
          KLineEntity entity = snapshot.data!.kLineEntity;
          double upDown = entity.change ?? entity.close - entity.open;
          double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;
          infos = [
            getDate(entity.time),
            entity.open.toStringAsFixed(widget.fixedLength),
            entity.high.toStringAsFixed(widget.fixedLength),
            entity.low.toStringAsFixed(widget.fixedLength),
            entity.close.toStringAsFixed(widget.fixedLength),
            "${upDown > 0 ? "+" : ""}${upDown.toStringAsFixed(widget.fixedLength)}",
            "${upDownPercent > 0 ? "+" : ''}${upDownPercent.toStringAsFixed(2)}%",
            entity.amount.toInt().toString()
          ];
          return Container(
            margin: EdgeInsets.only(
                left: snapshot.data!.isLeft ? 4 : mWidth - mWidth / 3 - 4,
                top: 25),
            width: mWidth / 3,
            decoration: BoxDecoration(
                color: widget.chartColors.selectFillColor,
                border: Border.all(
                    color: widget.chartColors.selectBorderColor, width: 0.5)),
            child: ListView.builder(
              padding: EdgeInsets.all(4),
              itemCount: infos.length,
              itemExtent: 14.0,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final translations = widget.isChinese
                    ? kChartTranslations['zh_CN']!
                    : widget.translations.of(context);

                return _buildItem(
                  infos[index],
                  translations.byIndex(index),
                );
              },
            ),
          );
        });
  }

  Widget _buildItem(String info, String infoName) {
    Color color = widget.chartColors.infoWindowNormalColor;
    if (info.startsWith("+"))
      color = widget.chartColors.infoWindowUpColor;
    else if (info.startsWith("-")) color = widget.chartColors.infoWindowDnColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
            child: Text("$infoName",
                style: TextStyle(
                    color: widget.chartColors.infoWindowTitleColor,
                    fontSize: 10.0))),
        Text(info, style: TextStyle(color: color, fontSize: 10.0)),
      ],
    );
  }

  String getDate(int? date) => dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      widget.timeFormat);
}
