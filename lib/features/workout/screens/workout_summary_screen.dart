import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/atlas_widgets.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  const WorkoutSummaryScreen({super.key});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  int? _selectedFeeling;
  final _notesController = TextEditingController();

  static const _feelings = [
    _FeelingOption('😀', 'Excelente', AppColors.success),
    _FeelingOption('🙂', 'Bien', Color(0xFF84CC16)),
    _FeelingOption('😐', 'Normal', AppColors.secondary),
    _FeelingOption('😕', 'Cansado', AppColors.warning),
    _FeelingOption('😫', 'Agotado', AppColors.error),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildStats()),
            SliverToBoxAdapter(child: _buildRecord()),
            SliverToBoxAdapter(child: _buildFeelingSection()),
            SliverToBoxAdapter(child: _buildNotesSection()),
            SliverToBoxAdapter(child: _buildSaveButton(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.cardGradient,
        border: Border(
          bottom: BorderSide(color: Color(0xFF3D2260), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            '¡Entrenamiento completado!',
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Día A — Push · Lunes 2 Jun',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _StatCard(value: '54:23', label: 'DURACIÓN'),
          const SizedBox(width: 10),
          _StatCard(value: '18', label: 'SERIES'),
          const SizedBox(width: 10),
          _StatCard(value: '4.2t', label: 'VOLUMEN'),
        ],
      ),
    );
  }

  Widget _buildRecord() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🏆  NUEVO RÉCORD',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Press Inclinado', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              '72.5 kg × 4',
              style: AppTextStyles.numericLarge.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Anterior: 70 kg × 4',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeelingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: '¿Cómo te sentiste hoy?'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AtlasCard(
            child: Row(
              children: List.generate(_feelings.length, (i) {
                final f = _feelings[i];
                final isSelected = _selectedFeeling == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFeeling = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? f.color.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? f.color.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            f.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 9,
                              color: isSelected ? f.color : AppColors.textDisabled,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Notas opcionales'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: '¿Algo que destacar de la sesión?',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          AtlasButton(
            label: 'GUARDAR Y SALIR',
            variant: AtlasButtonVariant.accent,
            onTap: () => context.go(RouteNames.dashboard),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AtlasCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.numericLarge.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeelingOption {
  final String emoji;
  final String label;
  final Color color;
  const _FeelingOption(this.emoji, this.label, this.color);
}
