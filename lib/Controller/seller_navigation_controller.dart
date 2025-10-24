import 'package:flutter/material.dart';
import 'package:chikankan/View/sellers/seller_homepage.dart';
import 'package:chikankan/View/sellers/seller_chat.dart';
import 'package:chikankan/View/sellers/seller_pending_order.dart';
import 'package:chikankan/View/sellers/seller_profile.dart';

class SellerNavigationHandler {
  final BuildContext context;

  SellerNavigationHandler(this.context);

  void navigate(int index) {
    Widget destinationPage;

    if (index == 0) {
      destinationPage = const SellerHomepage();
    } else if (index == 1) {
      destinationPage = const SellerChat();
    } else if (index == 2) {
      destinationPage = const SellerPendingOrder();
    } else if (index == 3) {
      destinationPage = const SellerProfile();
    } else {
      return; 
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destinationPage),
    );
  }
}