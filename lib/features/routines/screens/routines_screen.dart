import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/atlas_widgets.dart';
import '../../../shared/mock_data.dart';
import '../../workout/data/workout_session_store.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  late String _selectedDayId;

  @override
  void initState() {
    super.initState();
    _selectedDayId = WorkoutSessionStore.activeDay.id;
  }

  @override
  Widget build(BuildContext context) {
    final active = MockData.routines.where((r) => r.isActive).first;
    final others = MockData.routines.where((r) => !r.isActive).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildActiveRoutine(context, active)),
            SliverToBoxAdapter(child: _buildOtherRoutines(context, others)),
            SliverToBoxAdapter(child: _buildAddButtons(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text('Rutinas', style: AppTextStyles.displayMedium),
          ),
          OutlinedButton.icon(
            onPressed: () => _showComingSoon(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nueva'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRoutine(BuildContext context, MockRoutine routine) {
    final selectedDay = routine.days.firstWhere(
      (day) => day.id == _selectedDayId,
      orElse: () => routine.days.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Rutina activa'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3D2260), width: 0.5),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'ACTIVA',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${routine.totalSessions} sesiones',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(routine.name, style: AppTextStyles.titleLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: routine.days.map((day) {
                    final isSelected = day.id == selectedDay.id;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(day.name),
                      onSelected: (_) => setState(() {
                        _selectedDayId = day.id;
                        WorkoutSessionStore.activeDay = day;
                      }),
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.textPrimary : AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryLight : AppColors.primary.withOpacity(0.35),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                AtlasButton(
                  label: 'Iniciar entrenamiento',
                  variant: AtlasButtonVariant.accent,
                  icon: Icons.play_arrow_rounded,
                  onTap: () => _startWorkout(context, routine, selectedDay),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRoutineDetail(context, routine),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Ver'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: EdgeInsets.zero,
                          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showComingSoon(context),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: EdgeInsets.zero,
                          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherRoutines(BuildContext context, List<MockRoutine> routines) {
    if (routines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Otras rutinas'),
        ...routines.map((r) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.name, style: AppTextStyles.titleMedium),
                      ),
                      Text(r.lastUsed, style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${r.days.length} días · ${r.totalSessions} sesiones',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRoutineDetail(context, r),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Ver'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showComingSoon(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showActivateDialog(context, r),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.success,
                            side: const BorderSide(
                              color: AppColors.success,
                              width: 0.5,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Activar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAddButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          AtlasButton(
            label: 'Nueva rutina',
            variant: AtlasButtonVariant.outline,
            icon: Icons.add_rounded,
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 10),
          AtlasButton(
            label: 'Importar desde foto',
            variant: AtlasButtonVariant.ghost,
            icon: Icons.photo_camera_outlined,
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  void _showRoutineDetail(BuildContext context, MockRoutine routine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(routine.name, style: AppTextStyles.titleLarge),
            const SizedBox(height: 6),
            Text(
              '${routine.days.length} días · ${routine.totalSessions} sesiones realizadas',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            ...routine.days.map((day) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.name, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${day.exerciseCount} ejercicios',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showActivateDialog(BuildContext context, MockRoutine routine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Activar ${routine.name}'),
        content: Text(
          'Esta rutina reemplazará a Push Pull Legs como tu rutina activa.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Próximamente disponible'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startWorkout(
    BuildContext context,
    MockRoutine routine,
    MockRoutineDay day,
  ) {
    WorkoutSessionStore.activeDay = day;
    WorkoutSessionStore.startSession(
      routine: routine,
      day: day,
    );
    context.go(RouteNames.workout);
  }
}
