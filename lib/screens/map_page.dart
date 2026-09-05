import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import '../services/database_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);
  static const Color lightGreen = Color(0xFFEAF4EF);
  static const Color textColor = Color(0xFF1F2924);
  static const Color secondaryText = Color(0xFF6B756F);

  final MapController mapController = MapController();
  final DatabaseService databaseService = DatabaseService();
  final Location location = Location();
  final TextEditingController searchController = TextEditingController();

  StreamSubscription<LocationData>? locationSubscription;

  double? userLatitude;
  double? userLongitude;

  bool permissionGranted = false;
  bool gpsEnabled = false;
  bool trackingEnabled = false;
  bool isLoading = true;

  double selectedRadius = 5;

  int? selectedItemCode;

  String selectedState = 'All States';
  String searchText = '';

  Map<String, dynamic>? selectedStore;

  List<Map<String, dynamic>> foodItems = [];
  List<Map<String, dynamic>> allStoreList = [];
  List<Map<String, dynamic>> storeList = [];

  List<String> states = [
    'All States',
  ];

  @override
  void initState() {
    super.initState();
    checkStatus();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await loadStates();
    await loadFoodItemsWithPrices();
  }

  Future<bool> isPermissionGranted() async {
    return await handler.Permission.locationWhenInUse.isGranted;
  }

  Future<bool> isGpsEnabled() async {
    return await handler.Permission.location.serviceStatus.isEnabled;
  }

  void checkStatus() async {
    bool permission = await isPermissionGranted();
    bool gps = await isGpsEnabled();

    setState(() {
      permissionGranted = permission;
      gpsEnabled = gps;
    });
  }

  void requestEnableGps() async {
    if (gpsEnabled) {
      showMessage(
        'GPS is already enabled.',
      );

      return;
    }

    bool isGpsActive = await location.requestService();

    if (!isGpsActive) {
      setState(() {
        gpsEnabled = false;
      });

      showMessage(
        'GPS was not enabled.',
      );
    } else {
      setState(() {
        gpsEnabled = true;
      });

      showMessage(
        'GPS enabled.',
      );
    }
  }

  void requestLocationPermission() async {
    var permissionStatus = await handler.Permission.locationWhenInUse.request();

    if (permissionStatus.isGranted) {
      setState(() {
        permissionGranted = true;
      });

      showMessage(
        'Location permission granted.',
      );
    } else {
      setState(() {
        permissionGranted = false;
      });

      showMessage(
        'Location permission denied.',
      );
    }
  }

  void stopTracking() {
    locationSubscription?.cancel();
    locationSubscription = null;

    setState(() {
      trackingEnabled = false;
    });

    showMessage(
      'Location tracking stopped.',
    );
  }

  void updateLocation(LocationData data) {
    final double latitude = data.latitude;
    final double longitude = data.longitude;

    setState(() {
      userLatitude = latitude;
      userLongitude = longitude;
    });

    filterStoresByRadius();

    mapController.move(
      LatLng(latitude, longitude),
      15,
    );
  }

  void handleLocationButton() {
    if (trackingEnabled) {
      stopTracking();
    } else {
      startTracking();
    }
  }

  Future<void> startTracking() async {
    try {
      bool serviceEnabled =
      await location.serviceEnabled();

      if (!serviceEnabled) {
        serviceEnabled =
        await location.requestService();

        if (!serviceEnabled) {
          setState(() {
            gpsEnabled = false;
          });

          showMessage(
            'Please enable location service.',
          );

          return;
        }
      }

      var permissionStatus =
      await handler
          .Permission
          .locationWhenInUse
          .status;

      if (!permissionStatus.isGranted) {
        permissionStatus =
        await handler
            .Permission
            .locationWhenInUse
            .request();

        if (!permissionStatus.isGranted) {
          setState(() {
            permissionGranted = false;
          });

          showMessage(
            'Location permission is required.',
          );

          return;
        }
      }

      setState(() {
        gpsEnabled = true;
        permissionGranted = true;
        trackingEnabled = true;
      });

      final LocationData currentLocation = await location.getLocation();

      updateLocation(currentLocation);

      await locationSubscription?.cancel();

      locationSubscription = location.onLocationChanged.listen(
                (LocationData data) {
              updateLocation(data);
            },
          );

      showMessage(
        'Current location detected.',
      );
    } catch (e) {
      setState(() {
        trackingEnabled = false;
      });

      showMessage(
        'Error getting location: $e',
      );
    }
  }

  double calculateDistance(
      double latitude,
      double longitude,
      ) {
    if (userLatitude == null ||
        userLongitude == null) {
      return 0;
    }

    const Distance distance = Distance();

    final double meter = distance(
      LatLng(
        userLatitude!,
        userLongitude!,
      ),
      LatLng(
        latitude,
        longitude,
      ),
    );

    return meter / 1000;
  }

  void filterStoresByRadius() {
    if (userLatitude == null ||
        userLongitude == null) {
      setState(() {
        storeList = allStoreList
            .take(10)
            .toList();

        selectedStore = null;
      });

      moveMapToFirstVerifiedStore();

      return;
    }

    List<Map<String, dynamic>> nearbyStores = [];

    for (final store in allStoreList) {
      final status =
          store['geocode_status']
              ?.toString() ??
              '';

      final latitude =
      double.tryParse(
        store['latitude']
            ?.toString() ??
            '',
      );

      final longitude =
      double.tryParse(
        store['longitude']
            ?.toString() ??
            '',
      );

      if (status != 'verified' ||
          latitude == null ||
          longitude == null) {
        continue;
      }

      final distance = calculateDistance(
        latitude,
        longitude,
      );

      if (distance <= selectedRadius) {
        final updatedStore =
        Map<String, dynamic>.from(
          store,
        );

        updatedStore['distance'] =
            distance;

        nearbyStores.add(
          updatedStore,
        );
      }
    }

    nearbyStores.sort(
          (a, b) {
        final priceA =
            double.tryParse(
              a['price'].toString(),
            ) ??
                999999;

        final priceB =
            double.tryParse(
              b['price'].toString(),
            ) ??
                999999;

        return priceA.compareTo(
          priceB,
        );
      },
    );

    setState(() {
      storeList =
          nearbyStores.take(10).toList();

      selectedStore = null;
    });
  }

  Future<void> loadStates() async {
    try {
      final stateList =
      await databaseService.getStates();

      setState(() {
        states = [
          'All States',
          ...stateList.where(
                (state) =>
            state != 'All States',
          ),
        ];
      });
    } catch (e) {
      debugPrint(
        'Error loading states: $e',
      );
    }
  }

  Future<void> loadFoodItemsWithPrices() async {
    try {
      setState(() {
        isLoading = true;
      });

      final allFoodItems =
      await databaseService
          .getMapFoodItems();

      if (allFoodItems.isEmpty) {
        setState(() {
          foodItems = [];
          allStoreList = [];
          storeList = [];
          selectedItemCode = null;
          isLoading = false;
        });

        return;
      }

      setState(() {
        foodItems = allFoodItems;

        if (foodItems.isNotEmpty) {
          selectedItemCode =
          foodItems.first[
          'item_code'];
        } else {
          selectedItemCode = null;
        }
      });

      if (selectedItemCode != null) {
        await loadStores();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage(
        'Error loading food items: $e',
      );
    }
  }

  Future<void> loadStores() async {
    if (selectedItemCode == null) {
      return;
    }

    setState(() {
      isLoading = true;
      selectedStore = null;
      allStoreList = [];
      storeList = [];
    });

    try {
      final priceData =
      await databaseService
          .getMapFoodPrices(
        selectedItemCode!,
      );

      if (priceData.isEmpty) {
        setState(() {
          allStoreList = [];
          storeList = [];
          isLoading = false;
        });

        resetMap();

        return;
      }

      final Map<
          dynamic,
          Map<String, dynamic>>
      latestPrices = {};

      for (final price in priceData) {
        final premiseCode =
        price['premise_code'];

        if (premiseCode == null) {
          continue;
        }

        if (!latestPrices.containsKey(
          premiseCode,
        )) {
          latestPrices[premiseCode] =
          Map<String, dynamic>.from(
            price,
          );
        }
      }

      final premiseCodes = latestPrices.keys.toList();

      if (premiseCodes.isEmpty) {
        setState(() {
          allStoreList = [];
          storeList = [];
          isLoading = false;
        });

        resetMap();

        return;
      }

      final premises = await databaseService
          .getMapPremisesByCodes(
        premiseCodes,
      );

      List<Map<String, dynamic>>
      combinedList = [];

      for (final premise in premises) {
        final premiseState =
            premise['state']
                ?.toString()
                .trim() ??
                '';

        if (selectedState !=
            'All States' &&
            premiseState !=
                selectedState) {
          continue;
        }

        final price =
        latestPrices[
        premise[
        'premise_code']];

        if (price == null) {
          continue;
        }

        combinedList.add({
          'premise_code':
          premise[
          'premise_code'],
          'premise':
          premise['premise'],
          'address':
          premise['address'],
          'district':
          premise['district'],
          'state':
          premise['state'],
          'premise_type':
          premise[
          'premise_type'],
          'latitude':
          premise['latitude'],
          'longitude':
          premise['longitude'],
          'geocode_status':
          premise[
          'geocode_status'],
          'price':
          price['price'],
          'date':
          price['date'],
        });
      }

      combinedList.sort(
            (a, b) {
          final priceA =
              double.tryParse(
                a['price']
                    .toString(),
              ) ??
                  999999;

          final priceB =
              double.tryParse(
                b['price']
                    .toString(),
              ) ??
                  999999;

          return priceA.compareTo(
            priceB,
          );
        },
      );

      setState(() {
        allStoreList = combinedList;
        isLoading = false;
      });

      filterStoresByRadius();
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage(
        'Error loading stores: $e',
      );
    }
  }

  void moveMapToFirstVerifiedStore() {
    for (final store in storeList) {
      final status =
          store['geocode_status']
              ?.toString() ??
              '';

      final latitude =
      double.tryParse(
        store['latitude']
            ?.toString() ??
            '',
      );

      final longitude =
      double.tryParse(
        store['longitude']
            ?.toString() ??
            '',
      );

      if (status == 'verified' &&
          latitude != null &&
          longitude != null) {
        Future.delayed(
          const Duration(
            milliseconds: 300,
          ),
              () {
            mapController.move(
              LatLng(
                latitude,
                longitude,
              ),
              12,
            );
          },
        );

        return;
      }
    }

    resetMap();
  }

  void resetMap() {
    Future.delayed(
      const Duration(
        milliseconds: 300,
      ),
          () {
        mapController.move(
          const LatLng(
            4.2105,
            101.9758,
          ),
          5.5,
        );
      },
    );
  }

  void locateStore(
      Map<String, dynamic> store,
      ) {
    final status =
        store['geocode_status']
            ?.toString() ??
            '';

    final latitude =
    double.tryParse(
      store['latitude']
          ?.toString() ??
          '',
    );

    final longitude =
    double.tryParse(
      store['longitude']
          ?.toString() ??
          '',
    );

    setState(() {
      selectedStore = store;
    });

    if (status != 'verified' ||
        latitude == null ||
        longitude == null) {
      showMessage(
        'Verified store location is not available yet.',
      );

      return;
    }

    mapController.move(
      LatLng(
        latitude,
        longitude,
      ),
      16,
    );
  }

  String getSelectedFoodName() {
    if (selectedItemCode == null) {
      return '';
    }

    for (final food in foodItems) {
      if (food['item_code'] ==
          selectedItemCode) {
        return food['item']
            ?.toString() ??
            '';
      }
    }

    return '';
  }

  List<Map<String, dynamic>>
  getFilteredFoodItems() {
    if (searchText.trim().isEmpty) {
      return foodItems;
    }

    return foodItems.where(
          (food) {
        final itemName =
            food['item']
                ?.toString()
                .toLowerCase() ??
                '';

        return itemName.contains(
          searchText
              .toLowerCase()
              .trim(),
        );
      },
    ).toList();
  }

  List<Marker> buildMarkers() {
    final List<Marker> markers = [];

    if (userLatitude != null &&
        userLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(
            userLatitude!,
            userLongitude!,
          ),
          width: 55,
          height: 55,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue
                  .withValues(
                alpha: 0.15,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ),
      );
    }

    for (int i = 0;
    i < storeList.length;
    i++) {
      final store = storeList[i];

      final status =
          store['geocode_status']
              ?.toString() ??
              '';

      if (status != 'verified') {
        continue;
      }

      final latitude =
      double.tryParse(
        store['latitude']
            ?.toString() ??
            '',
      );

      final longitude =
      double.tryParse(
        store['longitude']
            ?.toString() ??
            '',
      );

      if (latitude == null ||
          longitude == null) {
        continue;
      }

      final isSelected =
          selectedStore?[
          'premise_code'] ==
              store['premise_code'];

      final isCheapest = i == 0;

      markers.add(
        Marker(
          point: LatLng(
            latitude,
            longitude,
          ),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedStore = store;
              });

              mapController.move(
                LatLng(
                  latitude,
                  longitude,
                ),
                16,
              );
            },
            child: Icon(
              Icons.location_on,
              size: isCheapest
                  ? 46
                  : isSelected
                  ? 43
                  : 37,
              color: isCheapest
                  ? Colors.orange
                  : isSelected
                  ? Colors.red
                  : primaryGreen,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget buildFoodSearch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        0,
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchText = value;
          });
        },
        style: const TextStyle(
          fontSize: 15,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search food, e.g. 100PLUS, Tomato, Ayam',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: secondaryText,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: primaryGreen,
            size: 23,
          ),
          suffixIcon: searchText.isNotEmpty
              ? IconButton(
            onPressed: () {
              searchController.clear();

              setState(() {
                searchText = '';
              });
            },
            icon: const Icon(
              Icons.close,
              size: 21,
              color: secondaryText,
            ),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFFE3E9E6),
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: primaryGreen,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRadiusButton(
      double radius,
      ) {
    final bool isSelected =
        selectedRadius == radius;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedRadius = radius;
          });

          filterStoresByRadius();
        },
        borderRadius:
        BorderRadius.circular(12),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryGreen
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primaryGreen
                  : const Color(
                0xFFE3E9E6,
              ),
            ),
          ),
          child: Text(
            '${radius.toStringAsFixed(0)} KM',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRadiusSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(
            0xFFE3E9E6,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.near_me,
                color: primaryGreen,
                size: 21,
              ),
              const SizedBox(
                width: 7,
              ),
              const Expanded(
                child: Text(
                  'Nearby Radius',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                trackingEnabled
                    ? 'Live tracking'
                    : userLatitude != null &&
                    userLongitude != null
                    ? 'Last location'
                    : 'Location not started',
                style: TextStyle(
                  fontSize: 12,
                  color: trackingEnabled
                      ? primaryGreen
                      : secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              buildRadiusButton(3),
              const SizedBox(
                width: 8,
              ),
              buildRadiusButton(5),
              const SizedBox(
                width: 8,
              ),
              buildRadiusButton(10),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Icon(
                gpsEnabled
                    ? Icons.gps_fixed
                    : Icons.gps_off,
                size: 18,
                color: gpsEnabled
                    ? primaryGreen
                    : Colors.orange,
              ),
              const SizedBox(
                width: 6,
              ),
              Text(
                gpsEnabled
                    ? 'GPS Enabled'
                    : 'GPS Disabled',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: gpsEnabled
                      ? primaryGreen
                      : Colors.orange,
                ),
              ),

              const SizedBox(
                width: 18,
              ),

              Icon(
                permissionGranted
                    ? Icons.check_circle
                    : Icons.warning_amber,
                size: 18,
                color: permissionGranted
                    ? primaryGreen
                    : Colors.orange,
              ),

              const SizedBox(
                width: 6,
              ),

              Expanded(
                child: Text(
                  permissionGranted
                      ? 'Permission Granted'
                      : 'Permission Required',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: permissionGranted
                        ? primaryGreen
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 11,
          ),

          if (userLatitude == null ||
              userLongitude == null)
            const Text(
              'Tap the location button on the map to start location tracking.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: secondaryText,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              'Current location: ${userLatitude!.toStringAsFixed(5)}, ${userLongitude!.toStringAsFixed(5)}',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildFoodDropdown() {
    final filteredItems = getFilteredFoodItems();

    int? dropdownValue;

    for (final food
    in filteredItems) {
      if (food['item_code'] == selectedItemCode) {
        dropdownValue = selectedItemCode;
        break;
      }
    }

    return DropdownButtonFormField<int>(
      initialValue: dropdownValue,
      isExpanded: true,
      menuMaxHeight: 350,
      iconSize: 22,
      hint: Text(
        filteredItems.isEmpty
            ? 'No food found'
            : 'Select food',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black45,
        ),
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.restaurant_menu,
          color: primaryGreen,
          size: 21,
        ),
        prefixIconConstraints:
        const BoxConstraints(
          minWidth: 46,
          minHeight: 48,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: const BorderSide(
            color: Color(
              0xFFE3E9E6,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: const BorderSide(
            color: primaryGreen,
            width: 1.5,
          ),
        ),
      ),
      items: filteredItems.map(
            (food) {
          return DropdownMenuItem<int>(
            value: food['item_code'],
            child: Text(
              food['item']
                  ?.toString() ??
                  '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          );
        },
      ).toList(),
      onChanged: filteredItems.isEmpty
          ? null
          : (value) {
        if (value == null) {
          return;
        }

        setState(() {
          selectedItemCode =
              value;

          selectedStore =
          null;
        });

        loadStores();
      },
    );
  }

  Widget buildStateDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedState,
      isExpanded: true,
      menuMaxHeight: 350,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: primaryGreen,
          size: 20,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 45,
          minHeight: 45,
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: const BorderSide(
            color: Color(
              0xFFE3E9E6,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: const BorderSide(
            color: primaryGreen,
            width: 1.5,
          ),
        ),
      ),
      items: states.map(
            (state) {
          return DropdownMenuItem<String>(
            value: state,
            child: Text(
              state,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          );
        },
      ).toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          selectedState = value;
          selectedStore = null;
        });

        loadStores();
      },
    );
  }

  Widget buildCheapestBadge() {
    if (storeList.isEmpty) {
      return const SizedBox.shrink();
    }

    final cheapest = storeList.first;
    final price = double.tryParse(
          cheapest['price'].toString(),
        ) ??
            0;

    final bool hasLocation = userLatitude != null && userLongitude != null;

    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        width: 170,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 9,
              offset: Offset(
                0,
                3,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasLocation
                  ? 'CHEAPEST NEARBY'
                  : 'LOWEST PRICE',
              style: const TextStyle(
                color: secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              cheapest['premise']
                  ?.toString() ??
                  '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              'RM ${price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSelectedStoreCard() {
    if (selectedStore == null) {
      return const SizedBox.shrink();
    }

    final price =
        double.tryParse(
          selectedStore!['price']
              .toString(),
        ) ??
            0;

    final status = selectedStore![
        'geocode_status']
            ?.toString() ??
            '';

    final isVerified = status == 'verified';

    final isCheapest =
        storeList.isNotEmpty &&
            selectedStore![
            'premise_code'] ==
                storeList.first[
                'premise_code'];

    final distance = double.tryParse(
      selectedStore!['distance']
          ?.toString() ??
          '',
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVerified
              ? primaryGreen
              : Colors.orange,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isVerified
                      ? primaryGreen
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedStore![
                      'premise']
                          ?.toString() ??
                          '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.25,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      '${selectedStore!['district'] ?? ''}, ${selectedStore!['state'] ?? ''}',
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (distance != null) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        '${distance.toStringAsFixed(2)} KM away',
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      selectedStore!['address']?.toString() ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      isVerified
                          ? 'Verified location'
                          : 'Location not verified yet',
                      style: TextStyle(
                        color: isVerified
                            ? primaryGreen
                            : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  IconButton(
                    onPressed: () {
                      locateStore(
                        selectedStore!,
                      );
                    },
                    icon: const Icon(
                      Icons.navigation,
                      size: 24,
                    ),
                    color: isVerified
                        ? primaryGreen
                        : Colors.orange,
                  ),
                ],
              ),
            ],
          ),

          if (isCheapest)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                top: 12,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
              child: Text(
                userLatitude != null && userLongitude != null
                    ? 'Cheapest nearby price for ${getSelectedFoodName()}'
                    : 'Lowest price for ${getSelectedFoodName()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildStoreCard(
      Map<String, dynamic> store,
      int index,
      ) {
    final price = double.tryParse(store['price'].toString(),) ?? 0;
    final status = store['geocode_status']?.toString() ?? '';
    final isVerified = status == 'verified';
    final isCheapest = index == 0;
    final isSelected = selectedStore?['premise_code'] == store['premise_code'];
    final distance = double.tryParse(store['distance']?.toString() ?? '',);

    return InkWell(
      onTap: () {
        setState(() {
          selectedStore = store;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? primaryGreen
                : const Color(
              0xFFE7EBEA,
            ),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCheapest
                    ? primaryGreen
                    : lightGreen,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isCheapest
                      ? Colors.white
                      : primaryGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(
                          top: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? primaryGreen
                              : Colors.orange,
                          shape:
                          BoxShape.circle,
                        ),
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Expanded(
                        child: Text(
                          store['premise']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),

                      if (isCheapest) ...[
                        const SizedBox(
                          width: 6,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: const Text(
                            'BEST',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    '${store['district'] ?? ''}, ${store['state'] ?? ''}', maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (distance != null) ...[
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      '${distance.toStringAsFixed(2)} KM away',
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    store['address']?.toString() ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    isVerified ? 'Verified location' : 'Location not verified yet',
                    style: TextStyle(
                      color: isVerified
                          ? primaryGreen
                          : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: primaryGreen,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                InkWell(
                  onTap: () {
                    locateStore(store);
                  },
                  borderRadius:
                  BorderRadius.circular(
                    30,
                  ),
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: isVerified
                          ? lightGreen
                          : const Color(
                        0xFFFFF3E0,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.navigation,
                      size: 21,
                      color: isVerified
                          ? primaryGreen
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(
          seconds: 2,
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                14,
                20,
                16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end:
                  Alignment.bottomRight,
                  colors: [
                    primaryGreen,
                    darkGreen,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(
                    25,
                  ),
                  bottomRight: Radius.circular(
                    25,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(
                        width: 7,
                      ),
                      Text(
                        'Store Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  const Text(
                    'Find stores and compare the latest food prices',
                    style: TextStyle(
                      color: Color(0xFFDCEDE6,),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: buildFoodDropdown(),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        flex: 2,
                        child: buildStateDropdown(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading ? const Center(
                child: CircularProgressIndicator(
                  color: primaryGreen,
                ),
              )
                  : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: buildFoodSearch(),
                  ),
                  SliverToBoxAdapter(
                    child: buildRadiusSelector(),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets
                        .fromLTRB(
                      14,
                      14,
                      14,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        height: 300,
                        decoration:
                        BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius
                              .circular(
                            18,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFE3E9E6,
                            ),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: mapController,
                              options: const MapOptions(
                                initialCenter:
                                LatLng(
                                  4.2105,
                                  101.9758,
                                ),
                                initialZoom: 5.5,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.my67food_price',
                                ),
                                MarkerLayer(
                                  markers: buildMarkers(),
                                ),
                                const RichAttributionWidget(
                                  attributions: [
                                    TextSourceAttribution(
                                      'OpenStreetMap contributors',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            buildCheapestBadge(),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: FloatingActionButton
                                  .small(
                                heroTag: 'currentLocationButton',
                                backgroundColor: trackingEnabled
                                    ? Colors.red
                                    : Colors.white,
                                onPressed: handleLocationButton,
                                child: Icon(
                                  trackingEnabled
                                      ? Icons.location_off
                                      : Icons.my_location,
                                  color: trackingEnabled
                                      ? Colors.white
                                      : primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (selectedStore != null)
                    SliverToBoxAdapter(
                      child: buildSelectedStoreCard(),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets
                        .fromLTRB(
                      16,
                      18,
                      16,
                      9,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userLatitude != null && userLongitude != null
                                      ? 'Nearby Stores Within ${selectedRadius.toStringAsFixed(0)} KM'
                                      : 'Stores by Price',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  getSelectedFoodName(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              '${storeList.length}/10 stores',
                              style: const TextStyle(
                                color: primaryGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (storeList.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 45,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              18,
                            ),
                            border: Border.all(
                              color: const Color(
                                0xFFE3E9E6,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.store_mall_directory_outlined,
                                size: 48,
                                color: Colors.black26,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                userLatitude != null && userLongitude != null
                                    ? 'No stores found within ${selectedRadius.toStringAsFixed(0)} KM'
                                    : 'No store price data found',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                userLatitude != null && userLongitude != null
                                    ? 'Try a larger radius or another food item.'
                                    : 'Try another food item or state.',
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (storeList.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (
                              context,
                              index,
                              ) {
                            return buildStoreCard(
                              storeList[index],
                              index,
                            );
                          },
                          childCount:
                          storeList.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    searchController.dispose();
    mapController.dispose();
    super.dispose();
  }
}