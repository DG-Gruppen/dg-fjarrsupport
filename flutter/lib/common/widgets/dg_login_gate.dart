import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/login.dart';
import 'package:flutter_hbb/models/platform_model.dart';

// DG Fjärrsupport: the technician client only connects once the technician has logged in
// with a helpdesk account, so every session can be tied to a handler in the helpdesk.
Future<bool> dgEnsureLogin() async {
  if (bind.mainGetBuildinOption(key: 'dg-require-login') != 'Y') {
    return true;
  }
  if (gFFI.userModel.isLogin) {
    return true;
  }
  await loginDialog();
  return gFFI.userModel.isLogin;
}
