import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:inventorysystem/services/auth.dart';
import 'package:inventorysystem/utils/window.dart';

class Register extends StatefulWidget {
  final Function toggleView;
  Register({this.toggleView});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String error = '';
  bool loading = false;

  TextEditingController userEmailController = TextEditingController();
  TextEditingController userPasswordController = TextEditingController();

  ParticleOptions particleOptions = ParticleOptions(
    image: Image.asset('assets/ice.png'),
    baseColor: Colors.blue,
    spawnOpacity: 0.0,
    opacityChangeRate: 0.25,
    minOpacity: 0.1,
    maxOpacity: 0.4,
    spawnMinSpeed: 30.0,
    spawnMaxSpeed: 70.0,
    spawnMinRadius: 7.0,
    spawnMaxRadius: 15.0,
    particleCount: 40,
  );

  var particlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.title;
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text('Sign up'),
        actions: <Widget>[
          FlatButton.icon(
            icon: Icon(Icons.person),
            label: Text('Sign In'),
            onPressed: () => widget.toggleView(),
          ),
        ],
      ),
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: particleOptions,
          paint: particlePaint,
        ),
        vsync: this,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 120.0, horizontal: 50.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20.0),
                WindowUtils.genTextField(
                  labelText: "Email",
                  hintText: "example@gmail.com",
                  textStyle: textStyle,
                  controller: this.userEmailController,
                  onChanged: (val) {
                    setState(() => this.userEmailController.text = val);
                  },
                ),
                WindowUtils.genTextField(
                  labelText: "Password",
                  textStyle: textStyle,
                  controller: this.userPasswordController,
                  obscureText: true,
                  validator: (val, labelText) => val.length < 6
                      ? 'Enter a $labelText 6+ chars long'
                      : null,
                  onChanged: (val) {
                    setState(() => this.userPasswordController.text = val);
                  },
                ),
                RaisedButton(
                    color: Theme.of(context).accentColor,
                    child: Text(
                      'Register',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        setState(() => loading = true);
                        String email = this.userEmailController.text;
                        String password = this.userPasswordController.text;
                        dynamic result = await _auth.register(email, password);
                        if (result == null) {
                          setState(() {
                            loading = false;
                            error = 'Please supply a valid email';
                          });
                        }
                      }
                    }),
                SizedBox(height: 12.0),
                Text(
                  error,
                  style: TextStyle(color: Colors.red, fontSize: 14.0),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
