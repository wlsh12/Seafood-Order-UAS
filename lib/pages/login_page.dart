import 'package:flutter/material.dart';

import '../services/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onMasuk});

  final Future<void> Function(int) onMasuk;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = LocalAuth();
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool daftar = false;
  bool tampilkanSandi = false;
  bool sibuk = false;
  String? pesan;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> kirim() async {
    if (sibuk || !form.currentState!.validate()) return;
    setState(() {
      sibuk = true;
      pesan = null;
    });
    try {
      if (daftar) {
        final berhasil = await auth.register(email.text, password.text);
        if (!mounted) return;
        setState(() {
          if (berhasil) {
            daftar = false;
            tampilkanSandi = false;
            password.clear();
          }
          pesan = berhasil
              ? 'Akun dibuat. Silakan masuk.'
              : 'Email sudah terdaftar.';
        });
      } else {
        final id = await auth.login(email.text, password.text);
        if (!mounted) return;
        if (id == null) {
          setState(() => pesan = 'Email atau kata sandi salah.');
        } else {
          await widget.onMasuk(id);
        }
      }
    } catch (_) {
      if (mounted) setState(() => pesan = 'Akun gagal diproses. Coba lagi.');
    } finally {
      if (mounted) setState(() => sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HarborBanner(),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              daftar ? 'Buat akun' : 'Selamat datang',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              daftar
                                  ? 'Daftar dengan email untuk mulai memesan.'
                                  : 'Masuk untuk memesan menu favoritmu.',
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: email,
                              enabled: !sibuk,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: (value) =>
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(value?.trim() ?? '')
                                  ? null
                                  : 'Masukkan email yang valid.',
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: password,
                              enabled: !sibuk,
                              obscureText: !tampilkanSandi,
                              onFieldSubmitted: (_) => kirim(),
                              decoration: InputDecoration(
                                labelText: 'Kata sandi',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: tampilkanSandi
                                      ? 'Sembunyikan kata sandi'
                                      : 'Tampilkan kata sandi',
                                  onPressed: () => setState(
                                    () => tampilkanSandi = !tampilkanSandi,
                                  ),
                                  icon: Icon(
                                    tampilkanSandi
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) => (value ?? '').length < 8
                                  ? 'Gunakan minimal 8 karakter.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            if (pesan != null) ...[
                              Text(pesan!),
                              const SizedBox(height: 12),
                            ],
                            FilledButton(
                              onPressed: sibuk ? null : kirim,
                              child: Text(
                                sibuk
                                    ? 'Memproses…'
                                    : daftar
                                    ? 'Daftar'
                                    : 'Masuk',
                              ),
                            ),
                            TextButton(
                              onPressed: sibuk
                                  ? null
                                  : () => setState(() {
                                      daftar = !daftar;
                                      tampilkanSandi = false;
                                      password.clear();
                                      pesan = null;
                                    }),
                              child: Text(
                                daftar ? 'Kembali ke masuk' : 'Daftar akun',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Ombak dan kapal digambar secara lokal agar halaman pertama langsung tampil.
class _HarborBanner extends StatelessWidget {
  const _HarborBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff083849), Color(0xff126b78)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _WavePainter())),
          const Positioned(
            right: 32,
            top: 32,
            child: Icon(
              Icons.sailing_rounded,
              size: 56,
              color: Color(0xffb9eff0),
            ),
          ),
          const Positioned(
            left: 22,
            bottom: 22,
            child: Text(
              'Seafood Order',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final offset in [0.0, 11.0, 22.0]) {
      final wave = Path()
        ..moveTo(0, size.height * .55 + offset)
        ..cubicTo(
          size.width * .32,
          12 + offset,
          size.width * .58,
          size.height + offset,
          size.width,
          size.height * .51 + offset,
        );
      canvas.drawPath(
        wave,
        Paint()
          ..color = const Color(0x427ddfe0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}
