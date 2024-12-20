import 'package:flight_bocking/home_search/search_hotels/BookingHotle/BookingControler.dart';
import 'package:flight_bocking/widgets/colors.dart';
import 'package:flight_bocking/widgets/snackbar.dart';
import 'package:flight_bocking/widgets/thankuscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookingScreen extends StatelessWidget {
  final BookingController bookingController = Get.put(BookingController());

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsiveness
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("Complete Your Booking"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TColors.text),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: TColors.primary.withOpacity(0.1),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              // Form Fields
              _buildTextField(
                controller: bookingController.firstNameController,
                label: "First Name",
                hintText: "Enter your first name",
                icon: Icons.person,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: bookingController.lastNameController,
                label: "Last Name",
                hintText: "Enter your last name",
                icon: Icons.person_outline,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: bookingController.emailController,
                label: "Email",
                hintText: "Enter your email",
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: bookingController.phoneController,
                label: "Phone Number",
                hintText: "Enter your phone number",
                keyboardType: TextInputType.phone,
                icon: Icons.phone,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: bookingController.addressController,
                label: "Address",
                hintText: "Enter your address",
                icon: Icons.home,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: bookingController.cityController,
                label: "City",
                hintText: "Enter your city",
                icon: Icons.location_city,
              ),
              SizedBox(height: 20),
              // Checkbox Section
              Text(
                "Special Requests",
                style: TextStyle(
                  fontSize: screenSize.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Obx(() => Column(
                    children: [
                      _buildCheckbox(
                        title: "Ground Floor",
                        value: bookingController.isGroundFloor.value,
                        onChanged: (value) =>
                            bookingController.isGroundFloor.value = value!,
                      ),
                      _buildCheckbox(
                        title: "High Floor",
                        value: bookingController.isHighFloor.value,
                        onChanged: (value) =>
                            bookingController.isHighFloor.value = value!,
                      ),
                      _buildCheckbox(
                        title: "Late Checkout",
                        value: bookingController.isLateCheckout.value,
                        onChanged: (value) =>
                            bookingController.isLateCheckout.value = value!,
                      ),
                      _buildCheckbox(
                        title: "Early Checkin",
                        value: bookingController.isEarlyCheckin.value,
                        onChanged: (value) =>
                            bookingController.isEarlyCheckin.value = value!,
                      ),
                      _buildCheckbox(
                        title: "Twin Bed",
                        value: bookingController.isTwinBed.value,
                        onChanged: (value) =>
                            bookingController.isTwinBed.value = value!,
                      ),
                      _buildCheckbox(
                        title: "Smoking",
                        value: bookingController.isSmoking.value,
                        onChanged: (value) =>
                            bookingController.isSmoking.value = value!,
                      ),
                    ],
                  )),
              SizedBox(height: 20),
              // Submit Button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(ThankYouScreen());
                      // Validate input and handle submission
                      if (_validateFields()) {
                        CustomSnackBar(
                                message: "Booking Confirmed!",
                                backgroundColor: Colors.green)
                            .show();
                      } else {
                        CustomSnackBar(
                                message: "Please fill all required fields!",
                                backgroundColor: TColors.third)
                            .show();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "Proceed to Complete Booking",
                      style: TextStyle(fontSize: screenSize.width * 0.045),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: TColors.primary),
        hintStyle: TextStyle(color: Colors.grey),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: TColors.primary)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: TColors.black)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
    );
  }

  // Helper to build checkboxes
  Widget _buildCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: TColors.primary,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  // Validate form fields
  bool _validateFields() {
    return bookingController.firstNameController.text.isNotEmpty &&
        bookingController.lastNameController.text.isNotEmpty &&
        bookingController.emailController.text.isNotEmpty &&
        bookingController.phoneController.text.isNotEmpty;
  }
}
