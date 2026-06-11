import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/atlas_widgets.dart';
import '../../../shared/mock_data.dart';
import '../../workout/data/workout_session_store.dart';
import '../data/routine_store.dart';

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
    final active = RoutineStore.active;
    final others = RoutineStore.all.where((r) => r.id != active.id).toList();

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
            onPressed: () async {
              await context.push(RouteNames.importRoutineImage);
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Foto'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await context.push(RouteNames.importRoutineText);
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.text_snippet_outlined, size: 18),
            label: const Text('Importar'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await context.push(RouteNames.createRoutine);
              if (mounted) setState(() {});
            },
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
                        onPressed: () async {
                          await context.push(RouteNames.editRoutine, extra: routine.id);
                          if (mounted) setState(() {});
                        },
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
                          onPressed: () async {
                            await context.push(RouteNames.editRoutine, extra: r.id);
                            if (mounted) setState(() {});
                          },
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showDeleteDialog(context, r),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                              color: AppColors.error.withOpacity(0.5),
                              width: 0.5,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Eliminar'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AtlasSectionTitle(title: 'Crear nueva rutina'),
          _buildCreationOption(
            context,
            icon: Icons.edit_note_rounded,
            title: 'Manual',
            subtitle: 'Crea tu rutina desde cero',
            available: true,
            onTap: () async {
              await context.push(RouteNames.createRoutine);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),
          _buildCreationOption(
            context,
            icon: Icons.text_snippet_outlined,
            title: 'Desde texto',
            subtitle: 'Pega el texto de tu rutina',
            available: true,
            onTap: () async {
              await context.push(RouteNames.importRoutineText);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),
          _buildCreationOption(
            context,
            icon: Icons.picture_as_pdf_outlined,
            title: 'Desde PDF',
            subtitle: 'Extrae ejercicios de un PDF',
            available: true,
            onTap: () async {
              await context.push(RouteNames.importRoutinePdf);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),
          _buildCreationOption(
            context,
            icon: Icons.auto_awesome_rounded,
            title: 'Generar con IA',
            subtitle: 'Rutina personalizada según tus objetivos',
            available: false,
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool available,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: available
                ? AppColors.primary.withOpacity(0.35)
                : const Color(0xFF3F3F46),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: available
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: available ? AppColors.primaryLight : AppColors.textDisabled,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: available
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (available)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondary)
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Próximamente',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
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

  void _showDeleteDialog(BuildContext context, MockRoutine routine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar rutina'),
        content: Text(
          '¿Eliminar "${routine.name}"? Esta acción no se puede deshacer.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await RoutineStore.deleteRoutine(routine.id);
              if (mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showActivateDialog(BuildContext context, MockRoutine routine) {
    final hasActiveSession = WorkoutSessionStore.activeSession?.started == true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Activar ${routine.name}'),
        content: Text(
          hasActiveSession
              ? 'Tienes un entrenamiento en curso. Puedes activar esta rutina, pero el entrenamiento actual no se verá afectado hasta que lo finalices.'
              : 'Esta rutina reemplazará a "${RoutineStore.active.name}" como tu rutina activa.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              RoutineStore.activateRoutine(routine.id);
              Navigator.pop(ctx);
              setState(() {});
            },
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
