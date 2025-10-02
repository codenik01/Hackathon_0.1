import 'package:flutter/material.dart';
import 'hospitalDetailsScreen.dart';

class HospitalListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: Icon(Icons.local_hospital, color: Colors.blue),
          title: Text('City Care Hospital'),
          subtitle: Text('123 Main Street'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HospitalDetailsScreen(
                  hospitalName: 'City Care Hospital',
                  doctorName: 'Dr. Rakesh Kumar',
                  contactNumber: '+91 9876543210',
                  location: '123 Main Street, City Center',
                ),
              ),
            );
          },
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.local_hospital, color: Colors.green),
          title: Text('Green Valley Clinic'),
          subtitle: Text('456 Park Avenue'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HospitalDetailsScreen(
                  hospitalName: 'Green Valley Clinic',
                  doctorName: 'Dr. Priya Sharma',
                  contactNumber: '+91 9123456789',
                  location: '456 Park Avenue, Sector 5',
                ),
              ),
            );
          },
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.local_hospital, color: Colors.red),
          title: Text('Sunrise Medical Center'),
          subtitle: Text('789 Health Blvd'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HospitalDetailsScreen(
                  hospitalName: 'Sunrise Medical Center',
                  doctorName: 'Dr. Meena Joshi',
                  contactNumber: '+91 9988776655',
                  location: '789 Health Blvd, East Wing',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
