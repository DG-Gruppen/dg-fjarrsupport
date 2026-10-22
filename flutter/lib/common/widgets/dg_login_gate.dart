import 'package:flutter/foundation.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/login.dart';
import 'package:flutter_hbb/models/ab_model.dart';
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

// DG Fjärrsupport: the shared address books from the helpdesk (Kunder, Servrar) carry the
// servers' passwords, and the helpdesk changes a server's password after every session.
// Pull them fresh before each connection, so that both the address book and Fjärrstyr
// from the helpdesk use the current password without the technician typing anything.
Future<String?> dgSharedPassword(String id) async {
  if (bind.mainGetBuildinOption(key: 'dg-require-login') != 'Y') {
    return null;
  }
  if (!gFFI.userModel.isLogin) {
    return null;
  }
  try {
    await gFFI.abModel
        .pullAb(force: ForcePullAb.listAndCurrent, quiet: true);
    for (final ab in gFFI.abModel.addressbooks.values) {
      if (ab.isPersonal()) continue;
      await ab.pullAb(quiet: true);
      for (final peer in ab.peers) {
        if (peer.id == id && peer.password.isNotEmpty) {
          return peer.password;
        }
      }
    }
  } catch (e) {
    debugPrint('dgSharedPassword: $e');
  }
  return null;
}
