import 'package:flutter/material.dart';

import '../app/controller.dart';
import '../core/cloud_service.dart';
import 'widgets.dart';

Future<void> showAccount(BuildContext context, GameController c) =>
    showDialog<void>(context: context, builder: (_) => AccountDialog(c));

class AccountDialog extends StatefulWidget {
  const AccountDialog(this.c, {super.key});
  final GameController c;
  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  final email = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController(),
      name = TextEditingController();
  bool register = false, waiting = false;
  String feedback = '';
  GameController get c => widget.c;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirmation.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit({bool reset = false}) async {
    if (waiting || c.cloud.busy) return;
    final invalid = reset
        ? null
        : CloudService.validate(
            email.text,
            password.text,
            confirmation: register ? confirmation.text : null,
          );
    if (invalid != null ||
        (register &&
            !reset &&
            (name.text.trim().isEmpty || name.text.trim().length > 60))) {
      setState(
        () => feedback = invalid ?? 'Tên người chơi cần từ 1 đến 60 ký tự.',
      );
      return;
    }
    setState(() {
      waiting = true;
      feedback = '';
    });
    try {
      if (reset) {
        await c.cloud.resetPassword(email.text);
        feedback = 'Nếu địa chỉ này có tài khoản, hướng dẫn đặt lại mật khẩu sẽ được gửi đến email.';
      } else {
        await c.cloud.authenticate(
          email.text,
          password.text,
          name: register ? name.text : null,
        );
        await c.activateAccount();
        password.clear();
        confirmation.clear();
        if (mounted && c.guestHasProgress) {
          final merge = await confirm(
            context,
            'Mang hành trình khách vào tài khoản?',
            'Hành trình khách vẫn được giữ. Chọn Đồng ý để nhập các màn đã mở và thành tích tốt hơn; chọn Hủy để giữ tài khoản độc lập.',
          );
          if (merge) await c.importGuest();
        }
        feedback = c.cloud.status;
      }
    } catch (e) {
      feedback = e is FormatException ? e.message : CloudService.explain(e);
    } finally {
      if (mounted) setState(() => waiting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c.cloud,
    builder: (context, _) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: GamePanel(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                c.cloud.user == null
                    ? (register
                          ? 'Đăng ký người gác máy'
                          : 'Đăng nhập hành trình')
                    : 'Hồ sơ người chơi',
                style: const TextStyle(
                  fontFamily: 'NotoSerif',
                  color: gold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              if (!c.cloud.available) ...[
                const Text(
                  'Chế độ tài khoản chưa được cấu hình trên bản cài này. Bạn vẫn chơi và lưu trên thiết bị bình thường.',
                  style: TextStyle(color: cream, fontSize: 15),
                ),
                const Text(
                  'Cần cấu hình Firebase Android hoặc chạy bản debug kết nối Emulator. Xem docs/FIREBASE_SETUP.md.',
                  style: TextStyle(color: gold, fontSize: 13),
                ),
              ] else if (c.cloud.user != null) ...[
                Text(
                  c.cloud.profile['displayName'] as String? ??
                      c.cloud.user!.displayName ??
                      'Người gác máy',
                  style: const TextStyle(color: cream, fontSize: 20),
                ),
                Text(
                  c.cloud.user!.email ?? '',
                  style: const TextStyle(color: cream),
                ),
                Text(
                  '${c.playerStore.bestStars.length}/12 máy đã sửa · mở đến màn ${c.playerStore.unlocked}',
                  style: const TextStyle(color: gold),
                ),
                Text(c.cloud.status, style: const TextStyle(color: cream)),
                for (final result in c.cloud.results)
                  Text(
                    '${result['level']} · ${result['bestStars']} sao · ${result['bestMoves']} lượt · ${result['bestTimeSeconds']} giây',
                    style: const TextStyle(color: cream),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    MetalButton(
                      'Đồng bộ lại',
                      onPressed: waiting || c.isDeveloper
                          ? null
                          : () async {
                              setState(() => waiting = true);
                              await c.cloud.checkpoint(c.playerStore);
                              await c.cloud.sync(c.playerStore);
                              if (mounted) setState(() => waiting = false);
                            },
                    ),
                    if (c.guestHasProgress)
                      MetalButton(
                        'Nhập hành trình khách',
                        onPressed: waiting || c.isDeveloper
                            ? null
                            : () async {
                                if (await confirm(
                                  context,
                                  'Nhập dữ liệu khách?',
                                  'Giữ thành tích tốt hơn và không xóa bản khách. Trạng thái đang chơi chỉ nhập khi tài khoản chưa có màn đang chơi.',
                                )) {
                                  await c.importGuest();
                                  if (mounted) setState(() {});
                                }
                              },
                      ),
                    MetalButton(
                      'Đăng xuất',
                      onPressed: waiting
                          ? null
                          : () async {
                              setState(() => waiting = true);
                              await c.signOutAccount();
                              if (mounted) setState(() => waiting = false);
                            },
                    ),
                  ],
                ),
              ] else ...[
                if (register) _field(name, 'Tên người chơi', 'account_name'),
                _field(email, 'Email', 'account_email'),
                _field(password, 'Mật khẩu', 'account_password', secret: true),
                if (register)
                  _field(
                    confirmation,
                    'Nhập lại mật khẩu',
                    'account_confirmation',
                    secret: true,
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    MetalButton(
                      register ? 'Tạo tài khoản' : 'Đăng nhập',
                      primary: true,
                      onPressed: waiting ? null : submit,
                    ),
                    MetalButton(
                      register ? 'Đã có tài khoản' : 'Đăng ký',
                      onPressed: waiting
                          ? null
                          : () => setState(() {
                              register = !register;
                              feedback = '';
                            }),
                    ),
                    MetalButton(
                      'Quên mật khẩu',
                      onPressed: waiting ? null : () => submit(reset: true),
                    ),
                  ],
                ),
              ],
              if (waiting)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(color: gold),
                ),
              if (feedback.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    feedback,
                    style: const TextStyle(color: gold, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 12),
              MetalButton(
                'Trở về game',
                onPressed: waiting ? null : () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _field(
    TextEditingController controller,
    String label,
    String key, {
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: TextField(
      key: ValueKey(key),
      controller: controller,
      obscureText: secret,
      autocorrect: false,
      enableSuggestions: !secret,
      keyboardType: secret
          ? TextInputType.visiblePassword
          : label == 'Email'
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLength: label == 'Tên người chơi' ? 60 : 128,
    ),
  );
}
