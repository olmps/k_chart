import 'package:flutter/material.dart';
import 'package:k_chart/entity/k_line_entity.dart';

import '../entity/candle_entity.dart';
import '../k_chart_widget.dart' show MainState;
import 'base_chart_renderer.dart';
import 'dart:ui' as UI;

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  late double mCandleWidth;
  late double mCandleLineWidth;
  MainState state;
  bool isLine;

  //绘制的内容区域
  late Rect _contentRect;
  double _contentPadding = 5.0;
  List<int> maDayList;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final double mLineStrokeWidth = 1.0;
  double scaleX;
  late Paint mLinePaint;
  final UI.Image currencyImage;
  final double gridPadding;

  MainRenderer(
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      this.gridPadding,
      this.state,
      this.isLine,
      int fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      this.currencyImage,
      [this.maDayList = const [5, 10, 20]])
      : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            fixedLength: fixedLength,
            gridColor: chartColors.gridColor) {
    mCandleWidth = this.chartStyle.candleWidth;
    mCandleLineWidth = this.chartStyle.candleLineWidth;
    mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = mLineStrokeWidth
      ..color = this.chartColors.kLineColor;
    _contentRect = Rect.fromLTRB(
        chartRect.left,
        chartRect.top + _contentPadding,
        chartRect.right,
        chartRect.bottom - _contentPadding);
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    scaleY = _contentRect.height / (maxValue - minValue);
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine == true) return;
    TextSpan? span;
    if (state == MainState.MA) {
      span = TextSpan(
        children: _createMATextSpan(data),
      );
    } else if (state == MainState.BOLL) {
      span = TextSpan(
        children: [
          if (data.up != 0)
            TextSpan(
                text: "BOLL:${format(data.mb)}    ",
                style: getTextStyle(this.chartColors.ma5Color)),
          if (data.mb != 0)
            TextSpan(
                text: "UB:${format(data.up)}    ",
                style: getTextStyle(this.chartColors.ma10Color)),
          if (data.dn != 0)
            TextSpan(
                text: "LB:${format(data.dn)}    ",
                style: getTextStyle(this.chartColors.ma30Color)),
        ],
      );
    }
    if (span == null) return;
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  List<InlineSpan> _createMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    for (int i = 0; i < (data.maValueList?.length ?? 0); i++) {
      if (data.maValueList?[i] != 0) {
        var item = TextSpan(
            text: "MA${maDayList[i]}:${format(data.maValueList![i])}    ",
            style: getTextStyle(this.chartColors.getMAColor(i)));
        result.add(item);
      }
    }
    return result;
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (isLine != true) {
      drawCandle(curPoint, canvas, curX);
    }
    if (isLine == true) {
      // drawPolyline(
      //     lastPoint.close, curPoint.close, canvas, lastX, curX, scaleX);
    } else if (state == MainState.MA) {
      drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
    } else if (state == MainState.BOLL) {
      drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  // Draw a line chart
  drawPolyline(
    double lastPrice,
    double curPrice,
    Canvas canvas,
    double lastX,
    double curX,
    double scaleX,
  ) {
    if (lastX == curX) lastX = 0;
    final line = [
      Offset(lastX, getY(lastPrice)),
      Offset(curX, getY(curPrice)),
    ];

    final polylinePaint = Paint();
    polylinePaint.strokeWidth = (3 / scaleX).clamp(0, 3);
    polylinePaint.style = PaintingStyle.stroke;
    polylinePaint.color = chartColors.lineFillColor;

    // Draw main line
    canvas.drawLine(line.first, line.last, polylinePaint);

    // Draw customizations
    chartColors.lineBlurs.forEach((lineBlur) {
      polylinePaint.color = lineBlur.color;
      polylinePaint.maskFilter = lineBlur.maskFilter;
      canvas.drawLine(line.first, line.last, polylinePaint);
    });

    // Draw shadows
    if (chartColors.lineShadowColor != null) {
      final shadowPath = Path();
      shadowPath.moveTo(lastX, chartRect.height + chartRect.top);
      shadowPath.lineTo(lastX, getY(lastPrice));
      shadowPath.lineTo(curX, getY(curPrice));
      shadowPath.lineTo(curX, chartRect.height + chartRect.top);
      shadowPath.close();

      final shadowPaint = Paint();
      final shadowShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        tileMode: TileMode.clamp,
        colors: [chartColors.lineShadowColor!, Colors.transparent],
      ).createShader(Rect.fromLTRB(
          chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
      shadowPaint..shader = shadowShader;

      canvas.drawPath(shadowPath, shadowPaint);
    }
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    for (int i = 0; i < (curPoint.maValueList?.length ?? 0); i++) {
      if (i == 3) {
        break;
      }
      if (lastPoint.maValueList?[i] != 0) {
        drawLine(lastPoint.maValueList?[i], curPoint.maValueList?[i], canvas,
            lastX, curX, this.chartColors.getMAColor(i));
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint,
      Canvas canvas, double lastX, double curX) {
    if (lastPoint.up != 0) {
      drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX,
          this.chartColors.ma10Color);
    }
    if (lastPoint.mb != 0) {
      drawLine(lastPoint.mb, curPoint.mb, canvas, lastX, curX,
          this.chartColors.ma5Color);
    }
    if (lastPoint.dn != 0) {
      drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX,
          this.chartColors.ma30Color);
    }
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = mCandleWidth / 2;
    double lineR = mCandleLineWidth / 2;
    if (open >= close) {
      // 实体高度>= CandleLineWidth
      if (open - close < mCandleLineWidth) {
        open = close + mCandleLineWidth;
      }
      chartPaint.color = this.chartColors.upColor;
      final candle = Rect.fromLTRB(curX - r, close, curX + r, open);
      canvas.drawRRect(
          UI.RRect.fromRectAndRadius(candle, Radius.elliptical(1, 3)),
          chartPaint);

      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else if (close > open) {
      // 实体高度>= CandleLineWidth
      if (close - open < mCandleLineWidth) {
        open = close - mCandleLineWidth;
      }
      chartPaint.color = this.chartColors.dnColor;
      final candle = Rect.fromLTRB(curX - r, open, curX + r, close);
      canvas.drawRRect(
          UI.RRect.fromRectAndRadius(candle, Radius.elliptical(1, 3)),
          chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawLineChart(
    Canvas canvas,
    Size size,
    List<KLineEntity> datas,
    double Function(int) getX,
  ) {
    final points = datas
        .asMap()
        .map((index, data) =>
            MapEntry(index, Offset(getX(index), getY(data.close))))
        .values
        .toList();

    final linePath = Path()..addPolygon(points, false);

    final polylinePaint = Paint();
    polylinePaint.strokeWidth = (3 / scaleX).clamp(0, 3);
    polylinePaint.style = PaintingStyle.stroke;
    polylinePaint.color = chartColors.lineFillColor;

    // Draw main line
    canvas.drawPath(linePath, polylinePaint);

    // Draw customizations
    chartColors.lineBlurs.forEach((lineBlur) {
      polylinePaint.color = lineBlur.color;
      polylinePaint.maskFilter = lineBlur.maskFilter;
      canvas.drawPath(linePath, polylinePaint);
    });

    // Draw shadows
    if (chartColors.lineShadowColor != null) {
      points.insert(0, Offset(points.first.dx, size.height));
      points.add(Offset(points.last.dx, size.height));
      final shadowPath = Path()..addPolygon(points, false);

      final shadowPaint = Paint();
      final shadowShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        tileMode: TileMode.clamp,
        colors: [chartColors.lineShadowColor!, Colors.transparent],
      ).createShader(Rect.fromLTRB(
          chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
      shadowPaint..shader = shadowShader;

      canvas.drawPath(shadowPath, shadowPaint);
    }
  }

  @override
  void drawRightText(
      Canvas canvas, TextStyle textStyle, int gridRows, double coinScale) {
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; ++i) {
      double value = (gridRows - i) * rowSpace / scaleY + minValue;

      final x = chartRect.width - gridPadding + 4;
      if (i == 0) {
        drawCurrencyText(
          currencyImage,
          canvas,
          "${format(value)}",
          x,
          topPadding,
          textStyle,
          coinScale,
          alignCurrencyText: AlignCurrencyText.start,
        );
      } else {
        final y = rowSpace * i + topPadding;
        drawCurrencyText(
          currencyImage,
          canvas,
          "${format(value)}",
          x,
          y,
          textStyle,
          coinScale,
          alignCurrencyText: AlignCurrencyText.start,
        );
      }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns, [Color? color]) {
    if (color != null) gridPaint..color = color;
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + topPadding),
          Offset(chartRect.width, rowSpace * i + topPadding), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, topPadding),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  double getY(double y) {
    return (maxValue - y) * scaleY + _contentRect.top;
  }
}
