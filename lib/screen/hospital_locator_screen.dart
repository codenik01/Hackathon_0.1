import 'package:flutter/material.dart';

class HospitalLocatorScreen extends StatelessWidget {
  final List<Map<String, String>> hospitals = [
    {
      "name": "Rural Health Center - Devgaon",
      "contact": "+91 9876543210",
      "distance": "3.5 km away",
      "location": "Devgaon Main Road",
      "doctor": "Dr. Rakesh Kumar",
    },
    {
      "name": "District Hospital - Shivpur",
      "contact": "+91 9988776655",
      "distance": "12.8 km away",
      "location": "Shivpur Town Center",
      "doctor": "Dr. Priya Sharma",
    },
    {
      "name": "Primary Care Clinic - Ramgarh",
      "contact": "+91 9123456789",
      "distance": "7.1 km away",
      "location": "Ramgarh, Sector 2",
      "doctor": "Dr. Meena Joshi",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HOSPITAL LOCATOR"),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Map Section (placeholder image, replace later with Google Maps)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              image: DecorationImage(
                image: AssetImage("assets/map_placeholder.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 40),
                  Text(
                    "Your Location",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Hospital List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: hospitals.length,
              itemBuilder: (context, index) {
                final hospital = hospitals[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.green[50],
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Icon(
                      Icons.local_hospital,
                      color: Colors.green,
                      size: 32,
                    ),
                    title: Text(
                      hospital["name"]!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_walk,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            SizedBox(width: 6),
                            Text(hospital["distance"]!),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            SizedBox(width: 6),
                            Text(hospital["contact"]!),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      // Open details screen inside same file
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HospitalDetailsScreen(
                            hospitalName: hospital["name"]!,
                            doctorName: hospital["doctor"]!,
                            contactNumber: hospital["contact"]!,
                            location: hospital["location"]!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation
    );
  }
}

// Hospital Details Screen (same file)
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
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "👨‍⚕️ Doctor: $doctorName",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  "📞 Contact: $contactNumber",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 12),
                Text("📍 Location: $location", style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
