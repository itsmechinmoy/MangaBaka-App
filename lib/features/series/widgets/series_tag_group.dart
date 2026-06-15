import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';

class SeriesTagGroup extends StatelessWidget {
  final String header;
  final Map<String, List<String>> subGroups;

  const SeriesTagGroup({
    super.key,
    required this.header,
    required this.subGroups,
  });

  @override
  Widget build(BuildContext context) {
    final entries = subGroups.entries.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header.toUpperCase(),
            style: AppTypography.monoLabel(
              color: AppConstants.textMutedColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                _buildSubGroupItem(entries[i], isLast: i == entries.length - 1),
                if (i != entries.length - 1)
                  _buildDividerRow(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDividerRow() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1.5,
                  color: AppConstants.accentColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Divider(
            height: 24,
            thickness: 1,
            color: AppConstants.borderColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSubGroupItem(MapEntry<String, List<String>> entry, {required bool isLast}) {
    final subheader = entry.key;
    final tags = entry.value;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? 10 : null,
                  child: Container(
                    width: 1.5,
                    color: AppConstants.accentColor,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 9.25,
                  child: Container(
                    width: 16,
                    height: 1.5,
                    color: AppConstants.accentColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subheader.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 8),
                    child: Text(
                      subheader,
                      style: AppTypography.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textMutedColor,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                ],
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) => _buildTagChip(tag)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final tagParts = tag.split(' > ');
    return ChipBase(
      borderColor: AppConstants.borderColor,
      backgroundColor: AppConstants.secondaryBackground,
      borderRadius: AppConstants.denseRadius,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      label: Text.rich(
        TextSpan(
          children: [
            if (tagParts.length > 1) ...[
              TextSpan(
                text: '${tagParts.sublist(0, tagParts.length - 1).join(' > ')} > ',
                style: AppTypography.sans(
                  color: AppConstants.textMutedColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            TextSpan(
              text: tagParts.last,
              style: AppTypography.sans(
                color: AppConstants.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
