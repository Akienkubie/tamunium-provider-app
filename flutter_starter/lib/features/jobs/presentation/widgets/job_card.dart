import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/job_model.dart';
import 'status_chip.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final dateFmt = job.scheduledStart != null
        ? DateFormat('EEE, MMM d · h:mm a').format(job.scheduledStart!.toLocal())
        : 'Unscheduled';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job.id, style: Theme.of(context).textTheme.labelMedium),
                  StatusChip(status: job.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job.jobType ?? 'Job',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 6),
                  Text(dateFmt, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              if (job.rateAmount != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${currency.format(job.rateAmount)}${job.pricingType == 'Hourly' ? ' / hr' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
