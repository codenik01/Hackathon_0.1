import 'package:flutter/material.dart';

class HospitalDetailsScreen extends StatelessWidget {
  final String hospitalName;
  final String doctorName;
  final String contactNumber;
  final String location;

  const HospitalDetailsScreen({
    required this.hospitalName,
    required this.doctorName,
    required this.contactNumber,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hospitalName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Doctor: $doctorName", style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text("Contact: $contactNumber", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Location: $location", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
