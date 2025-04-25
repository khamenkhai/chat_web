import 'package:flutter/material.dart';
import 'package:chat_web/core/const/color_const.dart';

/// TO SHOW WHEN THERE IS NO INTERNET CONNECTION
class InternetErrorWidget extends StatelessWidget {
  const InternetErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_sharp,
              size: 36,
              color: ColorConstants.errorColor,
            ),
            const SizedBox(height: 10),
            const Text("No Internet Connection"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {},
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.backgroundColorLight,
                foregroundColor: ColorConstants.primaryColor,
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            )
          ],
        ),
      ),
    );
  }
}
