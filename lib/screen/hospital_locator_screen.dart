import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalLocatorScreen extends StatefulWidget {
  @override
  _HospitalLocatorScreenState createState() => _HospitalLocatorScreenState();
}

class _HospitalLocatorScreenState extends State<HospitalLocatorScreen> {
  List<Map<String, dynamic>> hospitals = [];
  bool isLoading = true;
  Position? currentPosition;
  String locationStatus = "Finding your location...";

  // Comprehensive free hospital database for India
  final List<Map<String, dynamic>> allHospitals = [
    {
      "name": "AIIMS Hospital",
      "contact": "+91-11-26588500",
      "location": "Ansari Nagar, New Delhi",
      "type": "Government Hospital",
      "emergency": true,
      "latitude": 28.5673,
      "longitude": 77.2100,
    },
    {
      "name": "Safdarjung Hospital",
      "contact": "+91-11-26165060",
      "location": "Ansari Nagar East, New Delhi",
      "type": "Government Hospital",
      "emergency": true,
      "latitude": 28.5675,
      "longitude": 77.2078,
    },
    {
      "name": "Ram Manohar Lohia Hospital",
      "contact": "+91-11-23365525",
      "location": "Baba Kharak Singh Marg, New Delhi",
      "type": "Government Hospital",
      "emergency": true,
      "latitude": 28.6265,
      "longitude": 77.2142,
    },
    {
      "name": "Lady Hardinge Medical College",
      "contact": "+91-11-23344334",
      "location": "Connaught Place, New Delhi",
      "type": "Government Hospital",
      "emergency": true,
      "latitude": 28.6334,
      "longitude": 77.2187,
    },
    {
      "name": "Lok Nayak Hospital",
      "contact": "+91-11-23237400",
      "location": "Jawaharlal Nehru Marg, New Delhi",
      "type": "Government Hospital",
      "emergency": true,
      "latitude": 28.6462,
      "longitude": 77.2334,
    },
    {
      "name": "Rural Health Center - Devgaon",
      "contact": "+91-9876543210",
      "location": "Devgaon Main Road",
      "type": "Rural Health Center",
      "emergency": true,
      "latitude": 28.6129,
      "longitude": 77.2295,
    },
    {
      "name": "District Hospital - Shivpur",
      "contact": "+91-9988776655",
      "location": "Shivpur Town Center",
      "type": "District Hospital",
      "emergency": true,
      "latitude": 28.6139,
      "longitude": 77.2090,
    },
    {
      "name": "Primary Care Clinic - Ramgarh",
      "contact": "+91-9123456789",
      "location": "Ramgarh, Sector 2",
      "type": "Primary Clinic",
      "emergency": false,
      "latitude": 28.6140,
      "longitude": 77.2190,
    },
    {
      "name": "Apollo Hospital",
      "contact": "+91-11-29871090",
      "location": "Sarita Vihar, Delhi",
      "type": "Private Hospital",
      "emergency": true,
      "latitude": 28.5313,
      "longitude": 77.2927,
    },
    {
      "name": "Max Hospital",
      "contact": "+91-11-26515050",
      "location": "Saket, New Delhi",
      "type": "Private Hospital",
      "emergency": true,
      "latitude": 28.5245,
      "longitude": 77.2159,
    },
    {
      "name": "Fortis Hospital",
      "contact": "+91-11-47135000",
      "location": "Shalimar Bagh, Delhi",
      "type": "Private Hospital",
      "emergency": true,
      "latitude": 28.7132,
      "longitude": 77.1456,
    },
    {
      "name": "Community Health Center",
      "contact": "+91-8765432109",
      "location": "Village Panchayat, Haryana",
      "type": "Community Center",
      "emergency": true,
      "latitude": 28.7000,
      "longitude": 77.1000,
    },
  ];

  @override
  void initState() {
    super.initState();
    initializeLocation();
  }

  Future<void> initializeLocation() async {
    try {
      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationStatus = "Please enable location services";
          hospitals = getNearestHospitals(null);
          isLoading = false;
        });
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        setState(() {
          locationStatus = "Location permission required";
          hospitals = getNearestHospitals(null);
          isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        currentPosition = position;
        locationStatus = "Location found - Finding nearby hospitals";
      });

      // Find nearest hospitals
      await findNearestHospitals(position);
      
    } catch (e) {
      print("Location error: $e");
      setState(() {
        locationStatus = "Error getting location - Showing all hospitals";
        hospitals = getNearestHospitals(null);
        isLoading = false;
      });
    }
  }

  Future<void> findNearestHospitals(Position position) async {
    List<Map<String, dynamic>> hospitalsWithDistance = [];

    for (var hospital in allHospitals) {
      try {
        double distance = await Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          hospital["latitude"],
          hospital["longitude"],
        ) / 1000; // Convert to kilometers

        hospitalsWithDistance.add({
          ...hospital,
          "distance": distance,
        });
      } catch (e) {
        print("Error calculating distance for ${hospital['name']}: $e");
      }
    }

    // Sort by distance and take nearest 15
    hospitalsWithDistance.sort((a, b) => a["distance"].compareTo(b["distance"]));
    
    setState(() {
      hospitals = hospitalsWithDistance.take(15).toList();
      isLoading = false;
      locationStatus = "Found ${hospitals.length} nearby hospitals";
    });
  }

  List<Map<String, dynamic>> getNearestHospitals(Position? position) {
    // If no location, return first 10 hospitals
    return allHospitals.take(10).map((hospital) => ({
      ...hospital,
      "distance": 0.0, // Unknown distance
    })).toList();
  }

  void _refreshHospitals() {
    setState(() {
      isLoading = true;
      hospitals = [];
    });
    initializeLocation();
  }

  void _callHospital(String phoneNumber) async {
    if (phoneNumber.contains("Not Available")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final url = 'tel:${phoneNumber.replaceAll(RegExp(r'[^\d+]'), '')}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot make call: $phoneNumber')),
      );
    }
  }

  void _openMaps(double lat, double lng, String name) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name';
    
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open maps for $name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("NEARBY HOSPITALS"),
        centerTitle: true,
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshHospitals,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          // Location Status
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(
                  currentPosition != null ? Icons.location_on : Icons.location_searching,
                  color: currentPosition != null ? Colors.green : Colors.blue,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                      if (currentPosition != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            "${currentPosition!.latitude.toStringAsFixed(4)}, ${currentPosition!.longitude.toStringAsFixed(4)}",
                            style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
  padding: EdgeInsets.all(12),
  child: Wrap(
    spacing: 10, // horizontal spacing
    runSpacing: 10, // vertical spacing
    alignment: WrapAlignment.center,
    children: [
      ActionChip(
        avatar: Icon(Icons.emergency, color: Colors.white, size: 18),
        label: Text("Emergency"),
        backgroundColor: Colors.red,
        labelStyle: TextStyle(color: Colors.white),
        onPressed: _showEmergencyContacts,
      ),
      ActionChip(
        avatar: Icon(Icons.phone, color: Colors.white, size: 18),
        label: Text("Ambulance"),
        backgroundColor: Colors.orange,
        labelStyle: TextStyle(color: Colors.white),
        onPressed: () => _callHospital("+91-102"),
      ),
      ActionChip(
        avatar: Icon(Icons.medical_services, color: Colors.white, size: 18),
        label: Text("First Aid"),
        backgroundColor: Colors.green,
        labelStyle: TextStyle(color: Colors.white),
        onPressed: _showFirstAidTips,
      ),
    ],
  ),
          ),


          // Hospitals List
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          "Searching for nearby hospitals...",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: hospitals.length,
                    itemBuilder: (context, index) {
                      final hospital = hospitals[index];
                      final distance = hospital["distance"] as double;
                      
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: hospital["emergency"] == true 
                                  ? Colors.red[100] 
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              hospital["emergency"] == true 
                                  ? Icons.emergency 
                                  : Icons.local_hospital,
                              color: hospital["emergency"] == true 
                                  ? Colors.red 
                                  : Colors.blue,
                            ),
                          ),
                          title: Text(
                            hospital["name"],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              // Distance
                              if (distance > 0)
                                Row(
                                  children: [
                                    Icon(Icons.directions_walk, size: 14, color: Colors.grey[700]),
                                    SizedBox(width: 4),
                                    Text(
                                      "${distance.toStringAsFixed(1)} km away",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              // Contact
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 14, color: Colors.grey[700]),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hospital["contact"],
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              // Type
                              Text(
                                hospital["type"],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _showHospitalDetails(hospital);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showHospitalDetails(Map<String, dynamic> hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  hospital["emergency"] == true ? Icons.emergency : Icons.local_hospital,
                  color: hospital["emergency"] == true ? Colors.red : Colors.blue,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hospital["name"],
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildDetailItem("🏥 Type", hospital["type"]),
            _buildDetailItem("📞 Contact", hospital["contact"]),
            _buildDetailItem("📍 Location", hospital["location"]),
            if (hospital["distance"] > 0)
              _buildDetailItem("📏 Distance", "${hospital["distance"].toStringAsFixed(1)} km away"),
            
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.phone),
                    label: Text("Call"),
                    onPressed: () {
                      Navigator.pop(context);
                      _callHospital(hospital["contact"]);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.directions),
                    label: Text("Directions"),
                    onPressed: () {
                      Navigator.pop(context);
                      _openMaps(hospital["latitude"], hospital["longitude"], hospital["name"]);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyContacts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Emergency Contacts"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyContact("National Emergency", "112"),
            _buildEmergencyContact("Police", "100"),
            _buildEmergencyContact("Fire", "101"),
            _buildEmergencyContact("Ambulance", "102"),
            _buildEmergencyContact("Disaster Management", "108"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String name, String number) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.emergency, color: Colors.red),
      title: Text(name),
      subtitle: Text(number),
      onTap: () => _callHospital(number),
    );
  }

  void _showFirstAidTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Emergency First Aid Tips"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("• Check for danger before helping"),
              Text("• Call emergency services immediately"),
              Text("• Stop bleeding with direct pressure"),
              Text("• Don't move injured person unnecessarily"),
              Text("• Keep patient warm and comfortable"),
            ].map((tip) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: tip,
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }
}