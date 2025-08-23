import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  late final TextEditingController eMail;
  bool isResetting = false;

  @override
  void initState() {
    super.initState();
    eMail = TextEditingController();
  }

  @override
  void dispose() {
    eMail.dispose();
    super.dispose();
  }

  Future<void> passWordRest() async {
    setState(() {
      isResetting = true;
    });

    // If successful, show a success message
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Password Reset'),
          content: Text('Password reset email sent successfully!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    // Clear the text in the email field
    eMail.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.fromLTRB(25.0, 40.0, 25.0, 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(16.0),
                child: Container(
                  width: 200.0,
                  height: 200.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/email.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.green,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 30, right: 30),
                child: TextField(
                  controller: eMail,
                  decoration: const InputDecoration(
                    hintText: 'Enter Your Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: isResetting ? null : passWordRest,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 15.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: Text(
                  isResetting ? 'Resetting...' : 'Reset Password',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reset Password Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ResetPassword(),
    );
  }
}
