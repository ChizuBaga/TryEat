import 'package:chikankan/Controller/order_controller.dart';
import 'package:chikankan/Model/piechart_model.dart';
import 'package:chikankan/View/sellers/seller_current_order.dart';
import 'package:flutter/material.dart';
import 'package:chikankan/Model/order_model.dart'; 
import 'package:chikankan/Model/orderItem_model.dart';
import 'package:chikankan/Controller/dashboard_controller.dart';
import 'package:fl_chart/fl_chart.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final DashboardController _dashboardService = DashboardController();
  final OrderController _orderController = OrderController();
  
  late Future<Map<String, dynamic>> _dailySalesFuture;
  late Stream<List<Orders>> _recentOrdersFuture;
  late Future<Map<String, double>> _salesHistoryFuture;

  int _touchedIndex = -1;

  final List<Color> _pieChartColors = [
    Colors.blue,
    Colors.yellow.shade700,
    Colors.purple.shade300,
    Colors.green,
    Colors.red,
    Colors.teal,
    Colors.deepOrange,
    Colors.indigo,
  ]; // improvement if possible :)

  @override
  void initState() {
    super.initState();
    _dailySalesFuture = _dashboardService.getDailySalesData();
    _recentOrdersFuture = _orderController.streamCompletedOrders();
    _salesHistoryFuture = _dashboardService.getSalesHistory();
  }

  // --- Utility for Pie Chart ---
  List<PieChartSectionData> _createPieChartData(List<dynamic> rawData) {
    final data = rawData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      Color flutterColor = _pieChartColors[index % _pieChartColors.length]; 
    
      return Sales(
        item['name'], 
        item['sales'], 
        flutterColor
      );
    }).toList();

    return data.map((data){
      return PieChartSectionData(
        color: data.color,
        value: data.sales,
        title: data.name,
        radius: 50,
        showTitle: true,
      );
    }).toList();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Sales Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Daily Sales Report 
            FutureBuilder<Map<String, dynamic>>(
              future: _dailySalesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  print("Error: ${snapshot.error.toString()}");
                  return const Text('Error loading daily sales.');
                }

                final data = snapshot.data!;
                final totalSales = data['totalSales'] ?? 0.0;
                final completedOrders = data['completedOrders'] ?? 0;
                final List<PieChartSectionData> pieChartData = _createPieChartData(data['pieChartData'] ?? []);

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        // Pie Chart
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                                  setState(() {
                                    // Reset index if the tap is released or outside any slice
                                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    // Update the index of the touched slice
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                }
                              );
                                },
                              ),
                              sections: pieChartData, 
                              borderData: FlBorderData(show: false), 
                              sectionsSpace: 2, 
                              centerSpaceRadius: 0, 
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Sales Summary
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Sales Today', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text('RM ${totalSales.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            const Text('Order Completed', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text('$completedOrders', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            const Text(
              'Order History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Order History
            StreamBuilder<List<Orders>>(
              stream: _recentOrdersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  print("Error: ${snapshot.error.toString()}");
                  return const Text('No recent orders.');
                }
                final orders = snapshot.data!;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Important for nested list views
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                            child: GestureDetector(
                              onTap: (){
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => SellerCurrentOrder(order: order)));
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('#${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold)),                                      
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('RM ${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(order.orderStatus, style: const TextStyle(color: Colors.green)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Page haven implemented, or will abandon 
                      // View More Button
                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: TextButton(
                      //     onPressed: () {
                      //       // Navigate to full Order History page
                      //       print('View more orders...');
                      //     },
                      //     child: const Text('View more', style: TextStyle(color: Colors.blue)),
                      //   ),
                      // ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            const Text(
              'Sales History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // --- Sales History Card ---
            FutureBuilder<Map<String, double>>(
              future: _salesHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Error loading sales history.');
                }

                final salesData = snapshot.data!;
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('This Week', style: TextStyle(color: Colors.grey)),
                                Text('RM ${salesData['thisWeek']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('This Month', style: TextStyle(color: Colors.grey)),
                                Text('RM ${salesData['thisMonth']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),                        
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}