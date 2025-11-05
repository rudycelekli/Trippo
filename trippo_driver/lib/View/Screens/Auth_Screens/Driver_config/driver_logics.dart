import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homzy_provider/Container/Repositories/firestore_repo.dart';
import 'package:homzy_provider/Container/utils/error_notification.dart';
import 'package:homzy_provider/View/Routes/routes.dart';
import 'package:homzy_provider/View/Screens/Auth_Screens/Driver_config/driver_providers.dart';

class DriverLogics{
   void sendDataToFirestore(BuildContext context ,ref , TextEditingController carNameController ,TextEditingController plateNumController ) async {
    try {
      if (carNameController.text.isEmpty || plateNumController.text.isEmpty) {
          ErrorNotification().showError(context, "Please Enter Car Name and Plate Number");

        return;
      }
      ref.watch(driverConfigIsLoadingProvider.notifier).update((state) => true);

      ref.watch(globalFirestoreRepoProvider).addDriversDataToFirestore(
          context,
          carNameController.text.trim(),
          plateNumController.text.trim(),
          ref.watch(driverConfigDropDownProvider)!);

      if (context.mounted) {
        context.goNamed(Routes().navigationScreen);
      }
    } catch (e) {
      ref.watch(driverConfigIsLoadingProvider.notifier).update((state) => false);
          ErrorNotification().showError(context, "An Error Occurred $e");
    }
  }
}