/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class SolarPanelModel {
  final String? date;
  final String? energy;
  final String? co2Avoidance;
  final String? payment;
  final String? text;

  SolarPanelModel({
    this.date,
    this.energy,
    this.co2Avoidance,
    this.payment,
    this.text,
  });

  factory SolarPanelModel.fromJson(dynamic json) => SolarPanelModel(
      date: json["date"],
      energy: json["energy"],
      co2Avoidance: json["co2avoidance"],
      payment: json["payment"],
      text: json["text"]);

  dynamic toJson() => {
        "date": date,
        "energy": energy,
        "co2avoidance": co2Avoidance,
        "payment": payment,
        "text": text
      };
}
