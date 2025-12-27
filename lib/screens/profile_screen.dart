import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/theme_manager.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Profil",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary,
                        AppColors.secondary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 35,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? "İsimsiz Kullanıcı",
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? "",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _showEditProfileDialog(context, user),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),

            _buildSettingItem(
              context,
              icon: Icons.lock_outline,
              title: "Güvenli Şifre Değiştir",
              onTap: () => _showSecureChangePasswordDialog(context),
            ),
            
            
            
            
            SwitchListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 4),
               title: Text("Bildirimler", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
               value: _notificationsEnabled,
               activeColor: AppColors.primary,
               secondary: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: Theme.of(context).cardColor,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface),
               ),
               onChanged: (val) {
                 setState(() => _notificationsEnabled = val);
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Bildirim ayarı güncellendi.")),
                 );
               },
            ),

            
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeManager().themeMode,
              builder: (context, mode, _) {
                return SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text("Karanlık Mod", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  value: mode == ThemeMode.dark,
                  activeColor: AppColors.primary,
                  secondary: Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Theme.of(context).cardColor,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Icon(Icons.dark_mode_outlined, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  onChanged: (val) {
                    ThemeManager().toggleTheme(val);
                  },
                );
              },
            ),

            
            
            
            _buildSettingItem(
              context,
              icon: Icons.help_outline,
              title: "Yardım ve Destek",
              onTap: () => _showHelpDialog(context),
            ),

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text("Çıkış Yap"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => _showDeleteAccountDialog(context),
              child: Text(
                "Hesabımı Sil",
                style: GoogleFonts.inter(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yardım Merkezi"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Herhangi bir sorunuz için bize ulaşın:"),
            SizedBox(height: 8),
            SelectableText(
              "destek@moneyrota.com",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text("S.S.S", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("- Verilerim güvende mi? Evet, Firebase güvencesiyle saklanır."),
            Text("- Şifremi unuttum? Giriş ekranından sıfırlayabilirsiniz."),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hesabı Sil"),
        content: const Text(
          "Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
          style: TextStyle(color: AppColors.error),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                if (context.mounted) {
                   Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hesabınız silindi.")));
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); 
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: Güvenlik için lütfen çıkış yapıp tekrar girdikten sonra deneyin. ($e)")),
                  );
                }
              }
            },
            child: const Text("Hesabı Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  
  void _showEditProfileDialog(BuildContext context, User? user) {
    if (user == null) return;
    
    
    final parts = (user.displayName ?? "").split(' ');
    String initialName = parts.isNotEmpty ? parts.first : "";
    String initialSurname = parts.length > 1 ? parts.sublist(1).join(' ') : "";

    final nameCtrl = TextEditingController(text: initialName);
    final surnameCtrl = TextEditingController(text: initialSurname);
    final emailCtrl = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Profili Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Ad")),
            TextField(controller: surnameCtrl, decoration: const InputDecoration(labelText: "Soyad")),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "E-posta")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              try {
                
                String newName = "${nameCtrl.text.trim()} ${surnameCtrl.text.trim()}";
                if (newName.trim() != user.displayName) {
                  await user.updateDisplayName(newName);
                }
                
                
                if (emailCtrl.text.trim() != user.email) {
                  await user.verifyBeforeUpdateEmail(emailCtrl.text.trim());
                   
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("E-posta adresinize doğrulama linki gönderildi.")),
                  );
                }

                await user.reload(); 
                if (context.mounted) {
                  setState(() {}); 
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profil güncellendi.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  
  void _showSecureChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Şifre Değiştir"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text("Güvenliğiniz için önce eski şifrenizi girin.", style: TextStyle(fontSize: 12, color: Colors.grey)),
               const SizedBox(height: 10),
               TextField(controller: oldPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Eski Şifre")),
               TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Yeni Şifre")),
               TextField(controller: confirmPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Yeni Şifre (Tekrar)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (newPassCtrl.text != confirmPassCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni şifreler uyuşmuyor!")));
                return;
              }
              
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && user.email != null) {
                  
                  final cred = EmailAuthProvider.credential(email: user.email!, password: oldPassCtrl.text);
                  await user.reauthenticateWithCredential(cred);
                  
                  
                  await user.updatePassword(newPassCtrl.text);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Şifreniz başarıyla değiştirildi.")),
                    );
                  }
                }
              } catch (e) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: Eski şifre yanlış olabilir. ($e)"), backgroundColor: Colors.red),
                   );
                 }
              }
            },
            child: const Text("Değiştir"),
          ),
        ],
      ),
    );
  }
}
