import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/colors.dart';
import '../home.dart';
import 'flight_package/fight_package.dart';
import 'search_flight_utils/filter_modal.dart';
import 'search_flight_utils/flight_bottom_sheet.dart';
import 'search_flight_utils/flight_controller.dart';

// Currency Dialog
class CurrencyDialog extends StatelessWidget {
  final FlightController controller;

  const CurrencyDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Price Currency',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _currencyTile('PKR', '🇵🇰'),
            _currencyTile('AED', '🇦🇪'),
            _currencyTile('GBP', '🇬🇧'),
            _currencyTile('SAR', '🇸🇦'),
            _currencyTile('USD', '🇺🇸'),
          ],
        ),
      ),
    );
  }

  Widget _currencyTile(String currency, String flag) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(currency),
      onTap: () => controller.changeCurrency(currency),
    );
  }
}

// Flight Card
class FlightCard extends StatelessWidget {
  final Flight flight;

  const FlightCard({super.key, required this.flight});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.dialog(
        PackageSelectionDialog(flight: flight),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: TColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    flight.imgPath,
                    height: 32,
                    width: 50,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    flight.airline,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    flight.flightNumber,
                    style: const TextStyle(
                      color: TColors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flight.departureTime,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        flight.from,
                        style: const TextStyle(
                          color: TColors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        flight.duration,
                        style: const TextStyle(
                          color: TColors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(
                        Icons.flight_takeoff,
                        color: TColors.primary,
                      ),
                      if (flight.isNonStop)
                        const Text(
                          'Nonstop',
                          style: TextStyle(
                            fontSize: 14,
                            color: TColors.grey,
                          ),
                        )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        flight.arrivalTime,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        flight.to,
                        style: const TextStyle(
                          color: TColors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GetX<FlightController>(
                    builder: (controller) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: TColors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(42),
                        border:
                            Border.all(color: TColors.black.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${controller.selectedCurrency.value} ${flight.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TColors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StepContainer extends StatelessWidget {
  final String stepNumber;
  final String stepText;
  final bool isActive;

  const StepContainer({
    Key? key,
    required this.stepNumber,
    required this.stepText,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isActive ? TColors.primary : TColors.grey,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: TColors.background,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            stepText,
            style: TextStyle(
              color: isActive ? TColors.primary : TColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class FlightBookingPage extends StatelessWidget {
  final controller = Get.put(FlightController());

  FlightBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.background2,
      appBar: AppBar(
        surfaceTintColor: TColors.background,
        backgroundColor: TColors.background,
        leading: const BackButton(),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Karachi ',
                  style: TextStyle(
                    fontSize: 16,
                    color: TColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.swap_horiz,
                  size: 20,
                  color:  TColors.text,
                ),
                Text(
                  ' Islamabad',
                  style: TextStyle(
                    fontSize: 16,
                    color:  TColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  '20 Dec - 25 Dec',
                  style: TextStyle(
                    fontSize: 14,
                    color: TColors.text,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    // Add your logic for changing the date
                    Get.off(()=> const HomeScreen());
                  },
                  child: Row(
                    children: const [
                      Icon(
                        Icons.edit,
                        size: 16,
                        color:  TColors.text,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 14,
                          color:  TColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          GetX<FlightController>(
            builder: (controller) => TextButton(
              onPressed: () {
                // Currency selection dialog
                showDialog(
                  context: context,
                  builder: (context) => CurrencyDialog(controller: controller),
                );
              },
              child: Text(
                controller.selectedCurrency.value,
                style: const TextStyle(
                  color: TColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                StepContainer(
                  stepNumber: '1',
                  stepText: 'Karachi to Islamabad',
                  isActive: true,
                ),
                StepContainer(
                  stepNumber: '2',
                  stepText: 'Islamabad to Karachi',
                  isActive: false,
                ),
              ],
            ),
          ),

          // Filter and sorting section
          Container(
            color: TColors.background,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Obx(() => _filterButton(
                      'Suggested', controller.sortType.value == 'Suggested')),
                  Obx(() => _filterButton(
                      'Cheapest', controller.sortType.value == 'Cheapest')),
                  Obx(() => _filterButton(
                      'Fastest', controller.sortType.value == 'Fastest')),
                  OutlinedButton(
                    onPressed: () {
                      // Open filter bottom sheet
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) =>
                            FilterBottomSheet(controller: controller),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.tune, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Filters',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Flight list section
          Expanded(
            child: GetX<FlightController>(
              builder: (controller) {
                if (controller.filteredFlights.isEmpty) {
                  return const Center(
                    child: Text(
                      'No flights match your criteria.',
                      style: TextStyle(color: TColors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: controller.filteredFlights.length,
                  itemBuilder: (context, index) {
                    return FlightCard(
                        flight: controller.filteredFlights[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String text, bool isSelected) {
    return TextButton(
      onPressed: () {
        // Update sorting type
        controller.updateSortType(text);
      },
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? TColors.primary : TColors.grey,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
