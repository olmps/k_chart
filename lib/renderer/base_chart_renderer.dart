import 'package:flutter/material.dart';

export '../chart_style.dart';
import 'dart:ui' as UI;

abstract class BaseChartRenderer<T> {
  double maxValue, minValue;
  late double scaleY;
  double topPadding;
  Rect chartRect;
  int fixedLength;
  Paint chartPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 1.0
    ..color = Colors.red;
  Paint gridPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 0.5
    ..color = Color(0xff4c5c74);

  BaseChartRenderer({
    required this.chartRect,
    required this.maxValue,
    required this.minValue,
    required this.topPadding,
    required this.fixedLength,
    required Color gridColor,
  }) {
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    scaleY = chartRect.height / (maxValue - minValue);
    gridPaint.color = gridColor;
    // print("maxValue=====" + maxValue.toString() + "====minValue===" + minValue.toString() + "==scaleY==" + scaleY.toString());
  }

  double getY(double y) => (maxValue - y) * scaleY + chartRect.top;

  String format(double? n) {
    if (n == null || n.isNaN) {
      return "0.00";
    } else {
      return n.toStringAsFixed(fixedLength);
    }
  }

  void drawGrid(Canvas canvas, int gridRows, int gridColumns);

  void drawText(Canvas canvas, T data, double x);

  void drawRightText(Canvas canvas, TextStyle textStyle, int gridRows);

  /// Returns the start currencyText start
  ///
  /// [x] refers to the align position.
  /// [y] refers to the central position.
  Rect drawCurrencyText(
    UI.Image currencyImage,
    Canvas canvas,
    String text,
    double x,
    double y,
    TextStyle textStyle, {
    Color? backgroundColor,
    AlignCurrencyText alignCurrencyText = AlignCurrencyText.end,
  }) {
    // Draw text
    TextSpan span = TextSpan(text: text, style: textStyle);
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    final textStart =
        alignCurrencyText == AlignCurrencyText.end ? x - tp.width : x + currencyImage.width;
    final left = alignCurrencyText == AlignCurrencyText.end
        ? textStart - currencyImage.width
        : x;
    final right = alignCurrencyText == AlignCurrencyText.end ? x : x + tp.width;
    double top = y - tp.height / 2;

    final rect =
        Rect.fromLTRB(left - 4, top - 2, right + 4, top + tp.height + 2);
    if (backgroundColor != null) {
      canvas.drawRect(
        rect,
        Paint()..color = backgroundColor,
      );
    }
    tp.paint(canvas, Offset(textStart, top));

    // Draw asset
    canvas.save();
    final imageScale = textStyle.fontSize! * 0.8 / currencyImage.height;
    final paint = Paint()
      ..colorFilter = ColorFilter.mode(textStyle.color!, BlendMode.srcATop);
    canvas.scale(imageScale);
    canvas.drawImage(
      currencyImage,
      Offset(
        left / imageScale,
        y / imageScale - tp.height / 2,
      ),
      paint,
    );
    canvas.restore();

    return rect;
  }

  void drawChart(
    T lastPoint,
    T curPoint,
    double lastX,
    double curX,
    Size size,
    Canvas canvas,
  );

  void drawLine(double? lastPrice, double? curPrice, Canvas canvas,
      double lastX, double curX, Color color) {
    if (lastPrice == null || curPrice == null) {
      return;
    }
    //("lasePrice==" + lastPrice.toString() + "==curPrice==" + curPrice.toString());
    double lastY = getY(lastPrice);
    double curY = getY(curPrice);
    //print("lastX-----==" + lastX.toString() + "==lastY==" + lastY.toString() + "==curX==" + curX.toString() + "==curY==" + curY.toString());
    canvas.drawLine(
        Offset(lastX, lastY), Offset(curX, curY), chartPaint..color = color);
  }

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }
}

enum AlignCurrencyText {
  end,
  start,
}
