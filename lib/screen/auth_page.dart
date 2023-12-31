import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:location_share/models/jwt_token_info.dart';
import 'package:location_share/provider/user_provider.dart';
import 'package:location_share/services/login_api.dart';
import 'package:provider/provider.dart';

class AuthCodePage extends StatefulWidget {
  const AuthCodePage(
      {Key? key,
      required this.loginType,
      required this.msg,
      required this.authString,
      required this.email})
      : super(key: key);

  final String loginType;
  final String msg;
  final String authString;
  final String email;

  @override
  State<AuthCodePage> createState() => _AuthCodePageState();
}

class _AuthCodePageState extends State<AuthCodePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = "";
  Color _errorMessageColor = Colors.red;

  void completeLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    JwtTokenInfo? tokenInfo;

    if (widget.loginType == "NONE") {
      tokenInfo = await LoginApi().idpwLogin(widget.email, widget.authString);
    } else if (widget.loginType == "KAKAO") {
      tokenInfo = await LoginApi().kakaoSocialLogin(context, widget.authString);
    }

    Map<String, dynamic> accessTokenInfo =
        JwtDecoder.decode(tokenInfo!.accessToken!);

    await userProvider.setState(
        accessTokenInfo['username'],
        accessTokenInfo['sub'],
        accessTokenInfo['auth'],
        tokenInfo.accessToken,
        tokenInfo.refreshToken,
        false);
    Navigator.pop(context);
  }

  void onCodeSubmit() async {
    setState(() {
      _isLoading = true;
    });
    try {
      bool result = await LoginApi().authEmail(widget.email, _controller.text);
      if (!result) {
        _errorMessageColor = Colors.red;
        _errorMessage = "잘못되거나 만료된 인증코드";
      } else {
        completeLogin();
      }
    } on TimeoutException {
      setState(() {
        _errorMessageColor = Colors.red;
        _errorMessage = "서버와 연결에 실패했습니다.";
      });
    } catch (e) {
      setState(() {
        _errorMessageColor = Colors.red;
        _errorMessage = "예기치 못한 오류가 발생했습니다.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void onResendCode() async {
    try {
      await LoginApi().resendAuthEmail(widget.email);
      setState(() {
        _errorMessageColor = Colors.blue;
        _errorMessage = "인증 코드가 재발급되었습니다.";
      });
    } on TimeoutException {
      setState(() {
        _errorMessageColor = Colors.red;
        _errorMessage = "서버와 연결에 실패했습니다.";
      });
    } catch (e) {
      setState(() {
        _errorMessageColor = Colors.red;
        _errorMessage = "인증 코드 재발급에 실패했습니다.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              widget.msg,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const Text(
              '인증 코드',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 30,
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                hintText: '• • • • • •',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                errorStyle: TextStyle(
                  color: _errorMessageColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              maxLength: 6,
              onChanged: (value) {
                setState(() {
                  _errorMessage = "";
                });
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: onCodeSubmit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '제출',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onResendCode,
              child: const Text(
                '인증 코드 재전송',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
