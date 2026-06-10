import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/route_names.dart';
import '../../features/workout/data/workout_session_store.dart';

enum _NavAction { continueWorkout, pause, abandon }

class AtlasScaffold extends StatelessWidget {
  final Widget child;
  const AtlasScaffold({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(RouteNames.progress))  return 1;
    if (location.startsWith(RouteNames.workout))   return 2;
    if (location.startsWith(RouteNames.routines))  return 3;
    if (location.startsWith(RouteNames.nutrition)) return 4;
    if (location.startsWith(RouteNames.profile))   return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: _AtlasBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => _handleNavigation(context, index, currentIndex),
      ),
    );
  }

  Future<void> _handleNavigation(BuildContext context, int index, int currentIndex) async {
    if (index == currentIndex) return;

    final target = _indexToRoute(index);
    final hasActiveSession = WorkoutSessionStore.activeSession?.started == true;

    if (!hasActiveSession || target == RouteNames.workout) {
      context.go(target);
      return;
    }

    final action = await showDialog<_NavAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Tienes un entrenamiento en curso'),
        content: Text(
          'Puedes continuar, pausar y volver después, o abandonar el entrenamiento.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _NavAction.continueWorkout),
            child: const Text('Continuar entrenamiento'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _NavAction.pause),
            child: const Text('Pausar y salir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _NavAction.abandon),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Abandonar entrenamiento'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    switch (action) {
      case _NavAction.continueWorkout:
        context.go(RouteNames.workout);
      case _NavAction.pause:
        context.go(target);
      case _NavAction.abandon:
        WorkoutSessionStore.activeSession = null;
        context.go(target);
      case null:
        break;
    }
  }

  String _indexToRoute(int index) {
    switch (index) {
      case 1: return RouteNames.progress;
      case 2: return RouteNames.workout;
      case 3: return RouteNames.routines;
      case 4: return RouteNames.nutrition;
      case 5: return RouteNames.profile;
      default: return RouteNames.dashboard;
    }
  }
}

class _AtlasBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AtlasBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFF3F3F46), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined,          label: 'Inicio',     index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.show_chart_rounded,     label: 'Progreso',   index: 1, current: currentIndex, onTap: onTap),
              _NavCenterItem(onTap: () => onTap(2)),
              _NavItem(icon: Icons.list_alt_rounded,       label: 'Rutinas',    index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Nutrición', index: 4, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Perfil',     index: 5, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? AppColors.primary : AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textDisabled,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCenterItem extends StatelessWidget {
  final VoidCallback onTap;
  const _NavCenterItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
