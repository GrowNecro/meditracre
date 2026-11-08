import '../../l10n/localization.dart';

import 'package:flutter/material.dart';

class MedicationGuideScreen extends StatelessWidget {
  const MedicationGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.medicationUsageGuide)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text(
                        context.l10n.importantNote,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(context.l10n.thisIsGeneralInformationAndDoesNotReplace),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _GuideCard(
            icon: Icons.schedule_outlined,
            title: context.l10n.whyDoesSchedulingMatter,
            body: context
                .l10n
                .takingMedicationRegularlyAccordingToYourTreatmentPlan,
          ),
          _GuideCard(
            icon: Icons.warning_amber_outlined,
            title: context.l10n.doNotChangeTheDoseYourself,
            body: context.l10n.skippingDelayingOrTakingDosesTooCloseTogether,
          ),
          _GuideCard(
            icon: Icons.help_outline,
            title: context.l10n.ifYouForgetADose,
            body:
                context.l10n.instructionsVaryBetweenMedicationsCheckTheLabelOr,
          ),
          _GuideCard(
            icon: Icons.checklist_outlined,
            title: context.l10n.practicalGuide,
            body: context
                .l10n
                .fillCompartmentsAccordingToThePrescriptionAndOriginal,
          ),
          _GuideCard(
            icon: Icons.emergency_outlined,
            title: context.l10n.whenDoYouNeedUrgentHelp,
            body: context
                .l10n
                .contactLocalEmergencyServicesImmediatelyIfYouDevelop,
            isAlert: true,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.referenceNhsGuidanceOnDelayedDosesMedicationManagement,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.body,
    this.isAlert = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: isAlert ? scheme.errorContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isAlert ? scheme.onErrorContainer : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
