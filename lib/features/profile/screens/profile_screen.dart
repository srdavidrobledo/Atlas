import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/atlas_widgets.dart';
import '../../../shared/mock_data.dart';
import '../../onboarding/data/onboarding_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildStats()),
            SliverToBoxAdapter(child: _buildPersonalData(context)),
            SliverToBoxAdapter(child: _buildConfig(context)),
            SliverToBoxAdapter(child: _buildDangerZone(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0E2E), AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3F3F46), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'DR',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(OnboardingStore.data.userName, style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          Text(
            'Miembro desde ${MockUser.memberSince}',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final items = [
      _StatItem(label: 'Sesiones', value: '${MockStats.totalSessions}'),
      _StatItem(label: 'Horas', value: MockStats.totalHours),
      _StatItem(label: 'Volumen', value: MockStats.totalVolume),
      _StatItem(label: 'Récords', value: '${MockStats.totalRecords}'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
              ),
              child: Column(
                children: [
                  Text(
                    item.value,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPersonalData(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Datos personales'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AtlasCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Peso actual',
                  value: '${MockUser.currentWeight} kg',
                  onTap: () => _showEditDialog(context, 'Peso actual', '${MockUser.currentWeight}'),
                ),
                const Divider(indent: 56, height: 1),
                _SettingsItem(
                  icon: Icons.flag_outlined,
                  label: 'Peso objetivo',
                  value: '${MockUser.targetWeight} kg',
                  onTap: () => _showEditDialog(context, 'Peso objetivo', '${MockUser.targetWeight}'),
                ),
                const Divider(indent: 56, height: 1),
                _SettingsItem(
                  icon: Icons.emoji_events_outlined,
                  label: 'Objetivo',
                  value: OnboardingStore.data.goal,
                  onTap: () => _showGoalPicker(context),
                ),
                const Divider(indent: 56, height: 1),
                _SettingsItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Días por semana',
                  value: '${MockUser.weeklyDays} días',
                  onTap: () => _showDaysPicker(context),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfig(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Configuración'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AtlasCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.timer_outlined,
                  label: 'Descanso por defecto',
                  value: '${MockUser.defaultRest} seg',
                  onTap: () => _showEditDialog(context, 'Descanso', '${MockUser.defaultRest}'),
                ),
                const Divider(indent: 56, height: 1),
                _SettingsItem(
                  icon: Icons.straighten_outlined,
                  label: 'Unidades de peso',
                  value: 'kg',
                  onTap: () {},
                ),
                const Divider(indent: 56, height: 1),
                _SettingsItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notificaciones',
                  value: 'Activadas',
                  onTap: () {},
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: AtlasButton(
        label: 'Cerrar sesión',
        variant: AtlasButtonVariant.outline,
        icon: Icons.logout_rounded,
        onTap: () => _showLogoutDialog(context),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String field, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Editar $field'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showGoalPicker(BuildContext context) {
    final goals = [
      'Ganar músculo',
      'Perder grasa',
      'Fuerza',
      'Mantenimiento',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Objetivo', style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              ...goals.map((g) {
                final isActive = g == OnboardingStore.data.goal;
                return ListTile(
                  title: Text(g, style: AppTextStyles.bodyLarge),
                  trailing: isActive
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    unawaited(OnboardingStore.save(
                      OnboardingStore.data.copyWith(goal: g),
                    ));
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showDaysPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Días por semana', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final isActive = day == MockUser.weeklyDays;
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? AppColors.primary : const Color(0xFF3F3F46),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Cerrar sesión?'),
        content: Text(
          'Tendrás que iniciar sesión nuevamente.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyLarge),
            ),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
}
