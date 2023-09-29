import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:location_share/models/exceptions/custom_exception.dart';
import 'package:location_share/provider/user_provider.dart';
import 'package:location_share/screen/auth_page.dart';
import 'package:location_share/screen/component/assets.dart';
import 'package:location_share/screen/sign_up.dart';
import 'package:location_share/services/login_api.dart';
import 'package:provider/provider.dart';

class IdPwLoginPage extends StatefulWidget {
  const IdPwLoginPage({Key? key}) : super(key: key);

  @override
  State<IdPwLoginPage> createState() => _IdPwLoginPageState();
}

class _IdPwLoginPageState extends State<IdPwLoginPage> {
  final _formKey = GlobalKey<FormState>();
  Pattern pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void onLoginPressed(UserProvider userProvider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tokenInfo = await LoginApi().idpwLogin(_email, _password);
      Map<String, dynamic> accessTokenInfo =
          JwtDecoder.decode(tokenInfo.accessToken!);

      await userProvider.setState(
          accessTokenInfo['username'],
          accessTokenInfo['sub'],
          accessTokenInfo['auth'],
          tokenInfo.accessToken,
          tokenInfo.refreshToken,
          false);
      Navigator.pop(context);
    } on EmailNotVerified catch (e) {
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AuthCodePage(
                  loginType: "NONE",
                  msg: e.cause,
                  authString: _password,
                  email: _email)));
    } catch (e) {
      Assets().showErrorSnackBar(context, "로그인에 실패했습니다.");
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '로그인',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4), // changes position of shadow
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: '이메일',
                            labelStyle: const TextStyle(fontSize: 18),
                            contentPadding:
                                const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: Colors.grey.shade100,
                            filled: true,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이메일을 입력해주세요';
                            }
                            RegExp regex = RegExp(pattern as String);
                            if (!regex.hasMatch(value)) {
                              return '이메일 형식이 올바르지 않습니다';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _email = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: '비밀번호',
                            labelStyle: const TextStyle(fontSize: 18),
                            contentPadding:
                                const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: Colors.grey.shade100,
                            filled: true,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _password = value;
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          height: 50,
                          width: double.infinity, // fixed height for the button
                          child: ElevatedButton(
                            onPressed: _email.isEmpty ||
                                    _password.isEmpty ||
                                    _isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      onLoginPressed(userProvider);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.lightBlue.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: BorderSide(
                                  color: Colors.lightBlue.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.lightBlue.shade900),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    '로그인',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.lightBlue.shade900),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpPage()));
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '계정이 없으신가요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
