import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth for logout
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for adding cars
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/presentation/bloc/car_bloc.dart';
import 'package:rentapp/presentation/bloc/car_event.dart'; // Import event to reload data
import 'package:rentapp/presentation/bloc/car_state.dart';
import 'package:rentapp/presentation/pages/login_page.dart'; // Import LoginPage
import 'package:rentapp/presentation/widgets/car_card.dart';

class CarListScreen extends StatelessWidget {
  const CarListScreen({Key? key}) : super(key: key);

  void _addCar(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String model = '';
    int distance = 0;
    int fuelCapacity = 0;
    int pricePerHour = 0;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a Car'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Model'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter the car model' : null,
                  onSaved: (value) => model = value!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Distance (km)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter the distance' : null,
                  onSaved: (value) => distance = int.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Fuel Capacity (L)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter the fuel capacity' : null,
                  onSaved: (value) => fuelCapacity = int.parse(value!),
                ),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Price Per Hour (\$)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter the price per hour' : null,
                  onSaved: (value) => pricePerHour = int.parse(value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    await FirebaseFirestore.instance.collection('cars').add({
                      'model': model,
                      'distance': distance,
                      'fuelCapacity': fuelCapacity,
                      'pricePerHour': pricePerHour,
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Car added successfully!')),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add car: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reloadData(BuildContext context) async {
    // Trigger the event to reload data
    context.read<CarBloc>().add(LoadCars());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Car'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Logout user
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false, // Remove all previous routes
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CarBloc, CarState>(
        builder: (context, state) {
          if (state is CarsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CarsLoaded) {
            return RefreshIndicator(
              onRefresh: () => _reloadData(context), // Pull-to-refresh functionality
              child: ListView.builder(
                itemCount: state.cars.length,
                itemBuilder: (context, index) {
                  return CarCard(car: state.cars[index]);
                },
              ),
            );
          } else if (state is CarsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Text('Hello');
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCar(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
