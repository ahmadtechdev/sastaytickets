import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';

import '../flight_package/flight_package.dart';
import '../search_flights.dart';
import 'filter_modal.dart';

class FilterState {
  final RangeValues priceRange;
  final Set<String> selectedAirlines;
  final bool isRefundable;
  final bool isNonStop;
  final Set<String> departureTimeRanges;
  final Set<String> arrivalTimeRanges;

  FilterState({
    required this.priceRange,
    required this.selectedAirlines,
    this.isRefundable = false,
    this.isNonStop = false,
    required this.departureTimeRanges,
    required this.arrivalTimeRanges,
  });

  FilterState copyWith({
    RangeValues? priceRange,
    Set<String>? selectedAirlines,
    bool? isRefundable,
    bool? isNonStop,
    Set<String>? departureTimeRanges,
    Set<String>? arrivalTimeRanges,
  }) {
    return FilterState(
      priceRange: priceRange ?? this.priceRange,
      selectedAirlines: selectedAirlines ?? this.selectedAirlines,
      isRefundable: isRefundable ?? this.isRefundable,
      isNonStop: isNonStop ?? this.isNonStop,
      departureTimeRanges: departureTimeRanges ?? this.departureTimeRanges,
      arrivalTimeRanges: arrivalTimeRanges ?? this.arrivalTimeRanges,
    );
  }
}

class FlightController extends GetxController {
  var selectedCurrency = 'PKR'.obs;
  var flights = <Flight>[].obs;
  var filteredFlights = <Flight>[].obs;
  var filterState = Rx<FilterState>(FilterState(
    priceRange: const RangeValues(0, 100000),
    selectedAirlines: {},
    isRefundable: false,
    isNonStop: false,
    departureTimeRanges: {},
    arrivalTimeRanges: {},
  ));

  // Scenario tracking
  final Rx<FlightScenario> currentScenario = FlightScenario.oneWay.obs;

  // Flight selection tracking
  final Rx<bool> isSelectingFirstFlight = true.obs;
  final Rx<Flight?> selectedFirstFlight = Rx<Flight?>(null);
  final Rx<Flight?> selectedSecondFlight = Rx<Flight?>(null);

  void resetFlightSelection() {
    isSelectingFirstFlight.value = true;
    selectedFirstFlight.value = null;
    selectedSecondFlight.value = null;
  }

  void setScenario(FlightScenario scenario) {
    currentScenario.value = scenario;
    resetFlightSelection();
  }

  void handleFlightSelection(Flight flight) {
    if (currentScenario.value == FlightScenario.oneWay) {
      // Directly proceed to package selection for one-way trips
      Get.to(() => PackageSelectionDialog(flight: flight, isAnyFlightRemaining: false,));
    } else {
      // For return trips
      if (isSelectingFirstFlight.value) {
        // Select the first flight
        selectedFirstFlight.value = flight;
        isSelectingFirstFlight.value = false;
        Get.to(() =>
            PackageSelectionDialog(flight: flight, isAnyFlightRemaining: true));
      } else {
        // Select the second flight and move to the review page
        selectedSecondFlight.value = flight;
        Get.to(() => PackageSelectionDialog(
            flight: flight, isAnyFlightRemaining: false));
      }
    }
  }

  // New: Sorting type
  var sortType = 'Suggested'.obs;

  void loadDummyFlights() {
    flights.value = List.generate(100, (index) {
      // Generate unique flight numbers and times for variety
      final airlines = [
        'Air Arabia',
        'PIA',
        'SereneAir',
        'Air Sial',
        'Emirates',
        'Fly Dubai',
        'Fly Jinnah',
      ];
      final types = ['Economy', 'Business', 'Premium', 'Value'];
      final cities = [
        'Lahore (LHE)',
        'Karachi (KHI)',
        'Islamabad (ISB)',
        'Peshawar (PEW)',
        'Multan (MUX)',
        'Faisalabad (FSD)'
      ];
      final images = {
        'Air Arabia': 'assets/img/logos/air-arabia.png',
        'PIA': 'assets/img/logos/pia.png',
        'SereneAir': 'assets/img/logos/serena.png',
        'Air Sial': 'assets/img/logos/Air-Sial.png',
        'Emirates': 'assets/img/logos/emirates.png',
        'Fly Dubai': 'assets/img/logos/fly-dubai.png',
        'Fly Jinnah': 'assets/img/logos/flyjinnah.png',
      };

      final airline = airlines[index % airlines.length];
      final from = cities[index % cities.length];
      final to = cities[(index + 1) % cities.length];
      final type = types[index % types.length];
      // Generate a random duration between 1h 30m and 5h 25m
      final randomHours = 1 + (index % 5); // Between 1 and 5 hours
      final randomMinutes = index % 3 == 0
          ? 30
          : index % 2 == 0
              ? 15
              : 45; // Randomized 15, 30, or 45 minutes
      final duration = '${randomHours}h ${randomMinutes}m';

      // Random but consistent flight details
      return Flight(
        imgPath: images[airline]!,
        airline: airline,
        flightNumber: '${airline.substring(0, 2).toUpperCase()}-${300 + index}',
        departureTime:
            '${(6 + index % 12).toString().padLeft(2, '0')}:00 ${index % 2 == 0 ? "AM" : "PM"}',
        arrivalTime:
            '${(8 + index % 12).toString().padLeft(2, '0')}:00 ${index % 2 == 0 ? "AM" : "PM"}',
        duration: duration,
        price: 4500 * (index + 1) + (index % 50000),
        from: from,
        to: to == from ? cities[(index + 2) % cities.length] : to,
        type: type,
        isRefundable: index % 2 == 0,
        isNonStop: index % 2 == 0,
      );
    });

    filteredFlights.value = flights.toList(); // Initialize filtered flights
  }

  void changeCurrency(String currency) {
    selectedCurrency.value = currency;
    Get.back();
  }

  @override
  void onInit() {
    super.onInit();
    loadDummyFlights();
    initializeFilterRanges();
    ever(filterState, (_) => applyFilters());
    ever(sortType,
        (_) => sortFlights()); // Sort flights when sorting type changes
  }

  void initializeFilterRanges() {
    if (flights.isEmpty) return;

    double minPrice = flights.map((f) => f.price).reduce(min);
    double maxPrice = flights.map((f) => f.price).reduce(max);

    filterState.value = filterState.value.copyWith(
      priceRange: RangeValues(minPrice, maxPrice),
    );
  }

  void applyFilters() {
    var filtered = flights.where((flight) {
      // Price filter
      if (flight.price < filterState.value.priceRange.start ||
          flight.price > filterState.value.priceRange.end) {
        return false;
      }

      // Airline filter
      if (filterState.value.selectedAirlines.isNotEmpty &&
          !filterState.value.selectedAirlines.contains(flight.airline)) {
        return false;
      }

      // Refundable filter
      if (filterState.value.isRefundable && !flight.isRefundable) {
        return false;
      } // Non Stop filter
      if (filterState.value.isNonStop && !flight.isNonStop) {
        return false;
      }

      // Time range filters
      if (filterState.value.departureTimeRanges.isNotEmpty) {
        bool matchesDeparture = false;
        for (var range in filterState.value.departureTimeRanges) {
          if (isTimeInRange(flight.departureTime, range)) {
            matchesDeparture = true;
            break;
          }
        }
        if (!matchesDeparture) return false;
      }

      if (filterState.value.arrivalTimeRanges.isNotEmpty) {
        bool matchesArrival = false;
        for (var range in filterState.value.arrivalTimeRanges) {
          if (isTimeInRange(flight.arrivalTime, range)) {
            matchesArrival = true;
            break;
          }
        }
        if (!matchesArrival) return false;
      }

      return true;
    }).toList();

    filteredFlights.value = filtered;
  }

  // New: Sort flights based on the selected sort type
  void sortFlights() {
    if (sortType.value == 'Cheapest') {
      filteredFlights.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortType.value == 'Fastest') {
      filteredFlights.sort((a, b) {
        return parseTimeToDouble(a.duration)
            .compareTo(parseTimeToDouble(b.duration));
      });
    } else {
      filteredFlights.value =
          flights.toList(); // Default: Suggested (original order)
    }
  }

  // New: Update the sorting type
  void updateSortType(String type) {
    sortType.value = type;
  }

  bool isTimeInRange(String flightTime, String range) {
    final time = parseTimeToDouble(flightTime);

    switch (range) {
      case '00:00 - 06:00':
        return time >= 0 && time < 6;
      case '06:00 - 12:00':
        return time >= 6 && time < 12;
      case '12:00 - 18:00':
        return time >= 12 && time < 18;
      case '18:00 - 00:00':
        return time >= 18 && time < 24;
      default:
        return false;
    }
  }

  double parseTimeToDouble(String timeStr) {
    if (timeStr.contains('h')) {
      // Handle duration strings like "2h 30m"
      final parts = timeStr.split(' ');
      double hours = double.tryParse(parts[0].replaceAll('h', '').trim()) ?? 0;
      double minutes = parts.length > 1
          ? double.tryParse(parts[1].replaceAll('m', '').trim()) ?? 0
          : 0;
      return hours + (minutes / 60);
    } else if (timeStr.contains(':')) {
      // Handle time strings like "09:30 AM"
      final parts = timeStr.split(':');
      double hours = double.tryParse(parts[0]) ?? 0;
      double minutes = double.tryParse(parts[1].split(' ')[0]) ?? 0 / 60;

      if (timeStr.contains('PM') && hours != 12) {
        hours += 12;
      } else if (timeStr.contains('AM') && hours == 12) {
        hours = 0;
      }

      return hours + minutes;
    } else {
      // If the string format is unrecognized, return 0
      throw FormatException("Invalid time format: $timeStr");
    }
  }

  void updatePriceRange(RangeValues values) {
    filterState.value = filterState.value.copyWith(priceRange: values);
  }

  void toggleAirline(String airline) {
    var airlines = Set<String>.from(filterState.value.selectedAirlines);
    if (airlines.contains(airline)) {
      airlines.remove(airline);
    } else {
      airlines.add(airline);
    }
    filterState.value = filterState.value.copyWith(selectedAirlines: airlines);
  }

  void toggleTimeRange(String range, bool isDeparture) {
    var ranges = isDeparture
        ? Set<String>.from(filterState.value.departureTimeRanges)
        : Set<String>.from(filterState.value.arrivalTimeRanges);

    if (ranges.contains(range)) {
      ranges.remove(range);
    } else {
      ranges.add(range);
    }

    filterState.value = filterState.value.copyWith(
      departureTimeRanges: isDeparture ? ranges : null,
      arrivalTimeRanges: isDeparture ? null : ranges,
    );
  }

  void toggleRefundable(bool value) {
    filterState.value = filterState.value.copyWith(isRefundable: value);
  }

  void toggleNonStop(bool value) {
    filterState.value = filterState.value.copyWith(isNonStop: value);
  }

  void resetFilters() {
    initializeFilterRanges();
    filterState.value = FilterState(
      priceRange: filterState.value.priceRange,
      selectedAirlines: {},
      isRefundable: false,
      isNonStop: false,
      departureTimeRanges: {},
      arrivalTimeRanges: {},
    );
    sortType.value = 'Suggested'; // Reset sorting type as well
  }
}
