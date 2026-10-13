import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/intervention_controller.dart';

class EyeRelaxationView extends GetView<InterventionController> {
  const EyeRelaxationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Relaksasi Mata'),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () {
            controller.setEyeStep(0);
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Get.back();
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 40 ? constraints.maxHeight - 40 : 0,
                ),
                child: Obx(() {
                  final stepIndex = controller.eyeStep;
                  final steps = InterventionController.eyeRelaxationSteps;
                  final currentStep = steps[stepIndex.clamp(0, steps.length - 1)];
                  final isLast = stepIndex >= steps.length - 1;

                  return IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Step Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(steps.length, (index) {
                            final isDone = index < stepIndex;
                            final isCurrent = index == stepIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isCurrent ? 28 : 10,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.primary
                                    : (isDone
                                        ? AppColors.primary.withValues(alpha: 0.45)
                                        : AppColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        // Timer Badge (if active)
                        if (controller.isActive && controller.remainingSeconds > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sisa Waktu: ${controller.formattedRemainingTime}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Spacer(),

                        // Calming Step Illustration / Icon
                        Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getStepIcon(currentStep['icon']),
                              size: 60,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Step Title & Description
                        Text(
                          currentStep['title'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            currentStep['description'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 24),

                        // Calm reminder banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.eco_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Istirahat sejenak dari layar. Berikan jeda pada mata.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Navigation Buttons
                        Row(
                          children: [
                            if (!isLast)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await controller.cancel();
                                    controller.setEyeStep(0);
                                    if (context.mounted && Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      Get.back();
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Keluar',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            if (!isLast) const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => controller.nextEyeStep(),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isLast ? 'Selesai & Tutup' : 'Langkah Berikutnya',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getStepIcon(String? iconKey) {
    switch (iconKey) {
      case 'look_away':
        return Icons.visibility_off_outlined;
      case 'far_object':
        return Icons.landscape_outlined;
      case 'blink':
        return Icons.remove_red_eye_outlined;
      case 'breathe':
        return Icons.air_outlined;
      case 'check_circle':
        return Icons.check_circle_outline;
      default:
        return Icons.spa_outlined;
    }
  }
}
