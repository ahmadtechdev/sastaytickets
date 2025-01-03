import 'package:flight_bocking/home_search/search_hotels/BookingHotle/booking_hotel.dart';
import 'package:flight_bocking/home_search/search_hotels/search_hotel_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flight_bocking/widgets/colors.dart';

import '../../services/api_service.dart';
import '../booking_card/forms/hotel/guests/guests_controller.dart';

class SelectRoomScreen extends StatefulWidget {
  const SelectRoomScreen({super.key});

  @override
  State<SelectRoomScreen> createState() => _SelectRoomScreenState();
}

class _SelectRoomScreenState extends State<SelectRoomScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(SearchHotelController());
  final Map<int, dynamic> selectedRooms = {};
  final guestsController = Get.find<GuestsController>();
  final apiService = ApiService();
  bool isLoading = false;

  Future<void> handleBookNow() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Extract rate keys from selected rooms
      List<String> rateKeys = selectedRooms.values
          .map((room) => room['rateKey'].toString())
          .toList();

      // Get the group code from the first selected room
      int groupCode = selectedRooms.values.first['groupCode'] as int;

      // Make the prebook API call
      var response = await apiService.prebook(
        sessionId: controller.sessionId.value,
        hotelCode: controller.hotelCode.value,
        groupCode: groupCode,
        currency: "USD",
        rateKeys: rateKeys,
      );

      // Check the booking status
      if (response != null) {
        bool isSoldOut = response['isSoldOut'] ?? false;
        bool isPriceChanged = response['isPriceChanged'] ?? false;
        bool isBookable = response['isBookable'] ?? false;

        if (isSoldOut) {
          _showErrorDialog('Sorry, one or more selected rooms are no longer available.');
        } else if (isPriceChanged) {
          _showErrorDialog('The price for one or more rooms has changed. Please review the updated prices.');
        } else if (!isBookable) {
          _showErrorDialog('One or more rooms are not currently bookable. Please try different rooms.');
        } else {
          // All validations passed, proceed to booking
          Get.to(() => BookingHotelScreen());
        }
      } else {
        _showErrorDialog('Failed to validate room availability. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while processing your booking. Please try again.');
      print('Booking error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: guestsController.roomCount.value,
      vsync: this,
    );

    // Listen to tab changes
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void selectRoom(int roomIndex, dynamic room) {
    setState(() {
      selectedRooms[roomIndex] = room;
      if (roomIndex < guestsController.roomCount.value - 1) {
        _tabController.animateTo(roomIndex + 1);
      }
    });
  }

  bool get allRoomsSelected =>
      selectedRooms.length == guestsController.roomCount.value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Room', style: TextStyle(color: TColors.text)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TColors.text),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
        bottom: guestsController.roomCount.value > 1
            ? TabBar(
          controller: _tabController,
          tabs: List.generate(
            guestsController.roomCount.value,
                (index) => Tab(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Room ${index + 1}', style: const TextStyle(fontSize: 14),),
                    if (selectedRooms.containsKey(index))
                      const Icon(Icons.check_circle, size: 10),
                  ],
                ),
              ),
            ),
          ),
          labelColor: TColors.primary,
          unselectedLabelColor: TColors.grey,
          indicatorColor: TColors.primary,
        )
            : null,
      ),
      body: Obx(() {
        if (controller.roomsdata.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: TColors.primary),
          );
        }

        // Group rooms by roomName
        Map<String, List<dynamic>> groupedRooms = {};
        for (var room in controller.roomsdata) {
          String roomName = room['roomName'] ?? 'Unknown Room';
          if (!groupedRooms.containsKey(roomName)) {
            groupedRooms[roomName] = [];
          }
          groupedRooms[roomName]!.add(room);
        }

        if (guestsController.roomCount.value > 1) {
          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(
                    guestsController.roomCount.value,
                        (roomIndex) => SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHotelInfo(),
                          ...groupedRooms.entries.map((entry) => RoomTypeSection(
                            roomTypeName: entry.key,
                            rooms: entry.value,
                            nights: controller.nights.value,
                            onRoomSelected: (room) =>
                                selectRoom(roomIndex, room),
                            isSelected: (room) =>
                            selectedRooms[roomIndex] == room,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Single room view (original layout)
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHotelInfo(),
                ...groupedRooms.entries.map((entry) => RoomTypeSection(
                  roomTypeName: entry.key,
                  rooms: entry.value,
                  nights: controller.nights.value,
                  onRoomSelected: (room) => selectRoom(0, room),
                  isSelected: (room) => selectedRooms[0] == room,
                )),
              ],
            ),
          );
        }
      }),
      bottomNavigationBar: guestsController.roomCount.value >= 1 && allRoomsSelected
          ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : handleBookNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isLoading ? 'Checking Availability...' : 'Book Now',
                style: const TextStyle(
                  color: TColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (isLoading)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(
                    color: TColors.secondary,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      )
          : null,
    );
  }

  Widget _buildHotelInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: TColors.background2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.hotelName.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.star, color: TColors.primary, size: 18),
              SizedBox(width: 4),
              Text(
                '4 Star Hotel',
                style: TextStyle(
                  color: TColors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RoomTypeSection extends StatefulWidget {
  final String roomTypeName;
  final List<dynamic> rooms;
  final int nights;
  final Function(dynamic) onRoomSelected;
  final Function(dynamic) isSelected;

  const RoomTypeSection({
    super.key,
    required this.roomTypeName,
    required this.rooms,
    required this.nights,
    required this.onRoomSelected,
    required this.isSelected,
  });

  @override
  State<RoomTypeSection> createState() => _RoomTypeSectionState();
}

class _RoomTypeSectionState extends State<RoomTypeSection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: TColors.secondary.withOpacity(0.3),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => isExpanded = !isExpanded),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TColors.background4,
                    border: Border.all(color: TColors.background3),
                  ),
                  child: Center(
                    child: Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      size: 16,
                      color: TColors.background3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.roomTypeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isExpanded)
          ...widget.rooms.map((room) => RoomCard(
            room: room,
            nights: widget.nights,
            onSelect: widget.onRoomSelected,
            isSelected: widget.isSelected(room),
          )),
      ],
    );
  }
}

class RoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final int nights;
  final Function(dynamic) onSelect;
  final bool isSelected;

  const RoomCard({
    super.key,
    required this.room,
    required this.nights,
    required this.onSelect,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pricePerNight = room['price']['net'] ?? 0.0;
    final totalPrice = pricePerNight * nights;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? TColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? TColors.primary.withOpacity(0.05) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildRoomIcon(),
                        const SizedBox(width: 8),
                        Text(
                          room['meal'] ?? 'Not Available',
                          style: const TextStyle(
                            color: TColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _buildBadge(room['rateType'] ?? 'Unknown'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPriceSection(pricePerNight as double, totalPrice),
                if (room['remarks']?['remark'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    room['remarks']['remark'][0]['text'] ?? '',
                    style: const TextStyle(
                      color: TColors.grey,
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onSelect(room),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isSelected ? Colors.green: TColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isSelected ? 'Selected' : 'Select Room',
                      style: const TextStyle(
                        color: TColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(double pricePerNight, double totalPrice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, size: 16, color: TColors.grey),
                SizedBox(width: 4),
                Text(
                  'Per Night',
                  style: TextStyle(
                    color: TColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '\$${pricePerNight.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate, size: 16, color: TColors.grey),
                SizedBox(width: 4),
                Text(
                  'Total',
                  style: TextStyle(
                    color: TColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '\$${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: TColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.hotel,
        color: TColors.primary,
        size: 24,
      ),
    );
  }

  Widget _buildBadge(String text) {
    final isRefundable = text.toLowerCase() == 'refundable';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRefundable ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isRefundable ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
