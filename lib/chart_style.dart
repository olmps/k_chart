import 'package:flutter/material.dart';

class ChartColors {
  ChartColors({
    this.kLineColor = const Color(0xff4C86CD),
    this.lineFillColor = const Color(0x554C86CD),
    this.ma5Color = const Color(0xffC9B885),
    this.ma10Color = const Color(0xff6CB0A6),
    this.ma30Color = const Color(0xff9979C6),
    this.upColor = const Color(0xff4DAA90),
    this.dnColor = const Color(0xffC15466),
    this.volColor = const Color(0xff4729AE),
    this.macdColor = const Color(0xff4729AE),
    this.difColor = const Color(0xffC9B885),
    this.deaColor = const Color(0xff6CB0A6),
    this.kColor = const Color(0xffC9B885),
    this.dColor = const Color(0xff6CB0A6),
    this.jColor = const Color(0xff9979C6),
    this.rsiColor = const Color(0xffC9B885),
    this.defaultTextColor = const Color(0xff60738E),
    this.nowPriceUpColor = const Color(0xff4DAA90),
    this.nowPriceDnColor = const Color(0xffC15466),
    this.nowPriceTextColor = const Color(0xffffffff),
    this.depthBuyColor = const Color(0xff60A893),
    this.depthSellColor = const Color(0xffC15866),
    this.selectBorderColor = const Color(0xff6C7A86),
    this.selectFillColor = const Color(0xff0D1722),
    this.gridColor = const Color(0xff4c5c74),
    this.infoWindowNormalColor = const Color(0xffffffff),
    this.infoWindowTitleColor = const Color(0xffffffff),
    this.infoWindowUpColor = const Color(0xff00ff00),
    this.infoWindowDnColor = const Color(0xffff0000),
    this.hCrossColor = const Color(0xffffffff),
    this.vCrossColor = const Color(0x1Effffff),
    this.crossTextColor = const Color(0xffffffff),
    this.maxColor = const Color(0xffffffff),
    this.minColor = const Color(0xffffffff),
    this.minMaxBackgroundColor = const Color(0xffffffff),
    this.nowPriceBackgroundColor = const Color(0xffffffff),
  });

  /// BackgroundColor
  final Color kLineColor;
  final Color lineFillColor;
  final Color ma5Color;
  final Color ma10Color;
  final Color ma30Color;

  /// Up candle color
  final Color upColor;

  /// Down candle color
  final Color dnColor;
  final Color volColor;

  final Color macdColor;
  final Color difColor;
  final Color deaColor;

  final Color kColor;
  final Color dColor;
  final Color jColor;
  final Color rsiColor;

  final Color defaultTextColor;

  final Color nowPriceUpColor;
  final Color nowPriceDnColor;
  final Color nowPriceTextColor;

  final Color depthBuyColor;
  final Color depthSellColor;

  final Color selectBorderColor;

  final Color selectFillColor;

  final Color gridColor;

  final Color infoWindowNormalColor;
  final Color infoWindowTitleColor;
  final Color infoWindowUpColor;
  final Color infoWindowDnColor;

  final Color hCrossColor;
  final Color vCrossColor;
  final Color crossTextColor;

  final Color maxColor;
  final Color minColor;

  final Color minMaxBackgroundColor;
  final Color nowPriceBackgroundColor;

  Color getMAColor(int index) {
    switch (index % 3) {
      case 1:
        return ma10Color;
      case 2:
        return ma30Color;
      default:
        return ma5Color;
    }
  }
}

class ChartStyle {
  ChartStyle({
    this.topPadding = 30.0,
    this.bottomPadding = 20.0,
    this.childPadding = 12.0,
    this.pointWidth = 11.0,
    this.candleWidth = 8.5,
    this.candleLineWidth = 1.5,
    this.volWidth = 8.5,
    this.macdWidth = 3.0,
    this.vCrossWidth = 8.5,
    this.hCrossWidth = 0.5,
    this.nowPriceLineLength = 1,
    this.nowPriceLineSpan = 1,
    this.nowPriceLineWidth = 1,
    this.gridRows = 3,
    this.gridColumns = 3,
    this.dateTimeFormat,
    this.yAxisLabelTextStyle = const TextStyle(fontSize: 10),
    this.nowPriceTextStyle = const TextStyle(fontSize: 10),
    this.minMaxTextStyle = const TextStyle(fontSize: 10),
  });

  final double topPadding;
  final double bottomPadding;
  final double childPadding;
  final double pointWidth;
  final double candleWidth;
  final double candleLineWidth;
  final double volWidth;
  final double macdWidth;
  final double vCrossWidth;

  final double hCrossWidth;

  final int nowPriceLineLength;

  final int nowPriceLineSpan;

  final double nowPriceLineWidth;

  final int gridRows;

  final int gridColumns;

  final List<String>? dateTimeFormat;
  final TextStyle yAxisLabelTextStyle;
  final TextStyle nowPriceTextStyle;
  final TextStyle minMaxTextStyle;
}
