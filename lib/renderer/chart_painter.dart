import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';
import 'package:k_chart/utils/number_util.dart';

import '../entity/info_window_entity.dart';
import '../entity/k_line_entity.dart';
import '../utils/date_format_util.dart';
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';
import 'dart:ui' as UI;

class ChartPainter extends BaseChartPainter {
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer, mSecondaryRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  Color? upColor, dnColor;
  Color? ma5Color, ma10Color, ma30Color;
  Color? volColor;
  Color? macdColor, difColor, deaColor, jColor;
  int fixedLength;
  List<int> maDayList;
  final ChartColors chartColors;
  late Paint selectPointPaint, selectorBorderPaint;
  final ChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final UI.Image currencyImage;
  final double rightPadding;
  final double gridPadding;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required this.currencyImage,
    required this.rightPadding,
    required this.gridPadding,
    mainState,
    volHidden,
    secondaryState,
    this.sink,
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
  }) : super(
          chartStyle,
          datas: datas,
          scaleX: scaleX,
          scrollX: scrollX,
          isLongPress: isLongPass,
          selectX: selectX,
          mainState: mainState,
          volHidden: volHidden,
          secondaryState: secondaryState,
          rightPadding: rightPadding,
          isLine: isLine,
        ) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = this.chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = this.chartColors.selectBorderColor;
  }

  @override
  void initChartRenderer() {
    if (datas != null && datas!.isNotEmpty) {
      var t = datas![0];
      fixedLength =
          NumberUtil.getMaxDecimalLength(t.open, t.close, t.high, t.low);
    }
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      gridPadding,
      mainState,
      isLine,
      fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      currencyImage,
      maDayList,
    );
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(mVolRect!, mVolMaxValue, mVolMinValue,
          mChildPadding, fixedLength, this.chartStyle, this.chartColors);
    }
    if (mSecondaryRect != null) {
      mSecondaryRenderer = SecondaryRenderer(
          mSecondaryRect!,
          mSecondaryMaxValue,
          mSecondaryMinValue,
          mChildPadding,
          secondaryState,
          fixedLength,
          chartStyle,
          chartColors);
    }
  }

  @override
  void drawGrid(Canvas canvas, Size size) {
    if (!hideGrid) {
      canvas.save();
      canvas
          .clipRect(Rect.fromLTRB(0, 0, size.width - gridPadding, size.height));
      mMainRenderer.drawGrid(
          canvas, mGridRows, mGridColumns, chartColors.gridColor);
      mVolRenderer?.drawGrid(
          canvas, mGridRows, mGridColumns, chartColors.gridColor);
      mSecondaryRenderer?.drawGrid(
          canvas, mGridRows, mGridColumns, chartColors.gridColor);
      canvas.restore();
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas
        .clipRect(Rect.fromLTRB(0, 0, size.width - rightPadding, size.height));
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KLineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mSecondaryRenderer?.drawChart(
          lastPoint, curPoint, lastX, curX, size, canvas);
    }

    canvas.restore();
  }

  @override
  void drawRightText(Canvas canvas) {
    final textStyle = this.chartStyle.axisLabelTextStyle;
    final coinScale = this.chartStyle.axisCoinScale;
    if (!hideGrid) {
      mMainRenderer.drawRightText(canvas, textStyle, mGridRows, coinScale);
    }
    mVolRenderer?.drawRightText(canvas, textStyle, mGridRows, coinScale);
    mSecondaryRenderer?.drawRightText(canvas, textStyle, mGridRows, coinScale);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (datas == null) return;

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double x = 0.0;
    double y = 0.0;
    for (var i = 0; i <= mGridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);

        if (datas?[index] == null) continue;
        TextPainter tp = getTextPainter(
            getDate(datas![index].time), chartStyle.axisLabelTextStyle);
        y = size.height - (mBottomPadding - tp.height) / 2 - tp.height;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter tp = getTextPainter(point.close.toStringAsFixed(fixedLength),
        TextStyle(color: chartColors.crossTextColor));
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      Path path = new Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + 2 * w1, y + r);
      path.lineTo(textWidth + 2 * w1 + w2, y);
      path.lineTo(textWidth + 2 * w1, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      Path path = new Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    TextPainter dateTp =
        getTextPainter(getDate(point.time), chartStyle.axisLabelTextStyle);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - mBottomPadding;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //长按显示这条数据详情
    sink?.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //长按显示按中的数据
    if (isLongPress) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //松开显示最后一条数据
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas, Size size) {
    if (isLine) {
      return;
    }
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, 0, size.width - rightPadding, size.height),
    );

    final minX = translateXtoX(getX(mMainMinIndex));
    final minY = getMainY(mMainLowMinValue);
    if (minX > size.width / 2) {
      drawMinMaxToRight(canvas, minX, minY, mMainLowMinValue);
    } else {
      drawMinMaxToLeft(canvas, minX, minY, mMainLowMinValue);
    }

    final maxX = translateXtoX(getX(mMainMaxIndex));
    final maxY = getMainY(mMainHighMaxValue);

    if (maxX > size.width / 2) {
      drawMinMaxToRight(canvas, maxX, maxY, mMainHighMaxValue);
    } else {
      drawMinMaxToLeft(canvas, maxX, maxY, mMainHighMaxValue);
    }
    canvas.restore();
  }

  void drawMinMaxToRight(Canvas canvas, double x, double y, double value) {
    TextSpan span = TextSpan(text: " ----", style: chartStyle.minMaxTextStyle);
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    mMainRenderer.drawCurrencyText(
      currencyImage,
      canvas,
      value.toStringAsFixed(fixedLength),
      x - tp.width,
      y,
      chartStyle.minMaxTextStyle,
      chartStyle.maxMinCoinScale,
      backgroundColor: chartColors.minMaxBackgroundColor,
    );

    tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
  }

  void drawMinMaxToLeft(Canvas canvas, double x, double y, double value) {
    TextSpan span = TextSpan(text: "---- ", style: chartStyle.minMaxTextStyle);
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    tp.paint(canvas, Offset(x, y - tp.height / 2));

    mMainRenderer.drawCurrencyText(
      currencyImage,
      canvas,
      value.toStringAsFixed(fixedLength),
      x + tp.width,
      y,
      chartStyle.minMaxTextStyle,
      chartStyle.maxMinCoinScale,
      backgroundColor: chartColors.minMaxBackgroundColor,
      alignCurrencyText: AlignCurrencyText.start,
    );
  }

  @override
  void drawNowPrice(Canvas canvas, Size size) {
    if (!this.showNowPrice) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = datas!.last.close;
    double y = getMainY(value);
    // Do not draw in the view display area
    if (y > getMainY(mMainLowMinValue) || y < getMainY(mMainHighMaxValue)) {
      return;
    }

    final currencyRect = mMainRenderer.drawCurrencyText(
      currencyImage,
      canvas,
      value.toStringAsFixed(fixedLength),
      size.width - 4,
      y,
      this.chartStyle.nowPriceTextStyle,
      this.chartStyle.nowCoinScale,
      backgroundColor: this.chartColors.nowPriceBackgroundColor,
    );

    // Draw line
    double startX = 0;
    final space = 8;
    while (startX < currencyRect.left - space / 2) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + 4, y),
        Paint()
          ..color = this.chartStyle.nowPriceTextStyle.color!
          ..strokeWidth = 0.5,
      );
      startX += space;
    }
  }

  ///画交叉线
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = this.chartColors.vCrossColor
      ..strokeWidth = this.chartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);
    // k线图竖线
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);

    Paint paintX = Paint()
      ..color = this.chartColors.hCrossColor
      ..strokeWidth = this.chartStyle.hCrossWidth
      ..isAntiAlias = true;
    // k线图横线
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
          paintX);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 2.0, width: 2.0 / scaleX),
          paintX);
    }
  }

  TextPainter getTextPainter(String text, TextStyle? style) {
    TextSpan span = TextSpan(text: "$text", style: style);
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int? date) => dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      mFormats);

  double getMainY(double y) => mMainRenderer.getY(y);

  /// 点是否在SecondaryRect中
  bool isInSecondaryRect(Offset point) {
    return mSecondaryRect?.contains(point) ?? false;
  }
}
