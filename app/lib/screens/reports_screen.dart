import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../store.dart';
import '../theme.dart';
import '../utils.dart';

/// Reports screen.
///
/// Avg cycle / avg period / next expected, "Mostly regular" insight,
/// cycle-length bar chart with 28-day average dashed line, History with
/// Year + Month filters, "Showing X of Y", See all / Show less,
/// tap a row to expand, symptoms, and a clean one-page PDF for the doctor.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.state,
    this.onGoToCalendar,
  });

  final AppState state;
  final VoidCallback? onGoToCalendar;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int? _filterYear;
  String _filterMonth = 'All';
  bool _showAll = false;
  int? _expandedId;
  bool _pdfReady = false;

  static const _months = [
    'All',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  List<Map<String, dynamic>> get _filtered {
    final cycles = widget.state.cyclesForReports;
    final year = _filterYear;
    return cycles.where((c) {
      final range = c['range'] as dynamic;
      final start = range.start as DateTime;
      if (year != null && start.year != year) return false;
      if (_filterMonth != 'All' &&
          fmtShortMonth(start) != _filterMonth) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cycles = state.cyclesForReports;
    final years = cycles
        .map((c) => (c['range'] as dynamic).start.year as int)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (_filterYear == null && years.isNotEmpty) {
      _filterYear = years.first;
    }

    final filtered = _filtered;
    final shown = _showAll ? filtered : filtered.take(5).toList();

    // Symptom counts: number of CYCLES each symptom appeared in.
    final symptomCounts = state.symptomCycleCounts;
    final symptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSymptom =
        symptoms.isEmpty ? 1 : symptoms.first.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Reports',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'YOUR CYCLE, SIMPLY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: PB.muted,
                  ),
                ),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFBD9D6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: PB.rose,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (cycles.isEmpty) ...[
          PBCard(
            child: Column(
              children: [
                const Icon(
                  Icons.bar_chart_outlined,
                  size: 36,
                  color: PB.rose,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No cycles yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Log your first period on the Calendar tab.\nYour reports will appear here once you have a cycle or two.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: PB.muted, height: 1.55),
                ),
                const SizedBox(height: 12),
                if (widget.onGoToCalendar != null)
                  RosePillButton(
                    label: 'Go to Calendar',
                    onPressed: widget.onGoToCalendar,
                  ),
              ],
            ),
          ),
        ] else ...[
          // Stats
          Row(
            children: [
              _StatCard(
                label: 'Avg cycle',
                value: '${state.avgCycle} days',
                sub:
                    'Last ${cycles.length} cycle${cycles.length == 1 ? '' : 's'}',
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Avg period',
                value: '${state.avgPeriod} days',
                sub: 'Usually 4–5',
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Next expected',
                value: state.expectedNext != null
                    ? fmtDayMonth(state.expectedNext!)
                    : '—',
                // Overdue: "15 days late", never "in -15 days".
                sub: state.expectedNext != null
                    ? state.daysToGoLabel
                    : '',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cycle length chart
          PBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cycle length',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Last ${cycles.length} cycle${cycles.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PB.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: PB.greenBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: PB.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cycles.any(
                                (c) => (c['status'] as String) != 'On time',
                              )
                                  ? 'Mostly regular'
                                  : 'Regular',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF234D38),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.regularityInsight,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5A7A68),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _CycleChart(cycles: cycles, avgCycle: state.avgCycle),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // History
          PBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'History',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Tap a cycle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PB.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Small Year pills at intrinsic width — NOT a
                // full-width rose bar (v1.0.0 bug, screenshot).
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: years
                      .map(
                        (y) => _FilterPill(
                          label: '$y',
                          selected: _filterYear == y,
                          onTap: () => setState(() {
                            _filterYear = y;
                            _showAll = false;
                            _expandedId = null;
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _months
                        .map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _FilterPill(
                              label: m,
                              selected: _filterMonth == m,
                              onTap: () => setState(() {
                                _filterMonth = m;
                                _showAll = false;
                                _expandedId = null;
                              }),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Showing ${shown.length} of ${filtered.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PB.muted,
                  ),
                ),
                const SizedBox(height: 6),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No cycles in $_filterMonth ${_filterYear ?? ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: PB.muted,
                        ),
                      ),
                    ),
                  )
                else
                  ...shown.map((c) => _HistoryRow(
                        cycle: c,
                        expanded: _expandedId == c['range'].hashCode,
                        onTap: () => setState(() {
                          final id = c['range'].hashCode;
                          _expandedId = _expandedId == id ? null : id;
                        }),
                      )),
                if (filtered.length > 5) ...[
                  const SizedBox(height: 12),
                  // Plain rose text button, full width, no border.
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        _showAll
                            ? 'Show less'
                            : 'See all · ${filtered.length} cycles',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: PB.rose,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Symptoms
          PBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'What you felt most',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Last 3 cycles',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PB.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (symptoms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'No symptoms logged yet. Tap a day on the Calendar and add how you feel.',
                      style: TextStyle(
                        fontSize: 13,
                        color: PB.softText,
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  ...symptoms.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 92,
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8ECE9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: e.value / maxSymptom,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: PB.rose,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 62,
                            child: Text(
                              '${e.value} cycle${e.value == 1 ? '' : 's'}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: PB.softText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (state.mealsThisWeekTotal > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Meals this week: ${state.mealsThisWeekDone} of ${state.mealsThisWeekTotal} done — steady, not perfect, and that\'s fine.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: PB.softText,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // PDF for doctor
          PBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Take this to your doctor',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A clean one-page summary — dates, cycle lengths, and symptoms. No jargon, no extra detail.',
                  style: TextStyle(
                    fontSize: 14,
                    color: PB.softText,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),
                RosePillButton(
                  label: 'Download PDF for doctor',
                  onPressed: () => _downloadPdf(context),
                ),
                const SizedBox(height: 10),
                GhostPillButton(
                  label: 'Share report',
                  onPressed: () => _downloadPdf(context, shareOnly: true),
                ),
                if (_pdfReady) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _pdfReady = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: PB.greenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: PB.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'PDF ready — one page, no jargon',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF234D38),
                              ),
                            ),
                          ),
                          const Text(
                            'Dismiss',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: PB.rose,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _downloadPdf(
    BuildContext context, {
    bool shareOnly = false,
  }) async {
    final state = widget.state;
    final cycles = state.cyclesForReports;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PeriBuds — Cycle Summary',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated ${fmtDayMonthYear(DateTime.now())} · For discussion with your doctor',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Average cycle: ${state.avgCycle} days   ·   Average period: ${state.avgPeriod} days',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                state.expectedNext != null
                    ? 'Next period expected: ${fmtDayMonthYear(state.expectedNext!)}'
                    : 'Next period: not predicted yet',
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                state.regularityInsight,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: ['Period', 'Length', 'Cycle', 'Notes']
                        .map(
                          (h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  ...cycles.map((c) {
                    final range = c['range'] as dynamic;
                    return pw.TableRow(
                      children: [
                        fmtRangeLong(range.start as DateTime,
                            range.end as DateTime),
                        '${(range.end as DateTime).difference(range.start as DateTime).inDays + 1} days',
                        c['cycleLen'] != null
                            ? '${c['cycleLen']} days'
                            : '—',
                        c['status'] as String,
                      ]
                          .map(
                            (v) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                v,
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Symptoms logged: ${state.symptomsByDay.values.expand((e) => e).toSet().join(', ').ifEmpty('None logged')}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'This summary is based on the periods you logged in PeriBuds. It is not a medical diagnosis.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/peribuds-cycle-summary.pdf');
      await file.writeAsBytes(await doc.save());
      setState(() => _pdfReady = true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My PeriBuds cycle summary',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make the PDF: $e')),
        );
      }
    }
  }
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF502332).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: PB.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: PB.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PB.rose : Colors.white,
          border: Border.all(
            color: selected ? PB.rose : const Color(0xFFE8C9C4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: PB.rose.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : PB.ink,
          ),
        ),
      ),
    );
  }
}

class _CycleChart extends StatelessWidget {
  const _CycleChart({required this.cycles, required this.avgCycle});

  final List<Map<String, dynamic>> cycles;
  final int avgCycle;

  @override
  Widget build(BuildContext context) {
    // Last 6 cycles, oldest → newest. A cycle whose length is not known
    // yet (the first logged period) still gets a bar, at the average
    // length — the chart is never empty while a cycle is logged.
    final last6 = cycles.length > 6
        ? cycles.sublist(cycles.length - 6)
        : cycles;
    final ordered = last6.reversed.toList();
    const maxV = 30.0;
    const barArea = 90.0;
    if (ordered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Log your first period and your length chart will appear here.',
          style: TextStyle(fontSize: 13, color: PB.softText),
        ),
      );
    }
    // Y of the average line: top of a bar of average length.
    final avgTop = 18.0 + barArea * (1 - avgCycle / maxV);
    return SizedBox(
      height: 128,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: avgTop,
            height: 2,
            child: CustomPaint(painter: _DashedLinePainter()),
          ),
          Positioned(
            right: 0,
            top: (avgTop - 15).clamp(0.0, 112.0),
            child: Text(
              'Average $avgCycle',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PB.rose,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: ordered.asMap().entries.map((entry) {
              final idx = entry.key;
              final c = entry.value;
              final range = c['range'] as dynamic;
              final len = c['cycleLen'] as int? ?? avgCycle;
              // Bars alternate dark rose / light pink; the newest bar
              // (current cycle) is always dark rose — as approved.
              final isNewest = idx == ordered.length - 1;
              final barColor =
                  (isNewest || idx % 2 == 0) ? PB.rose : PB.roseLight;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$len',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: PB.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: (len / maxV * barArea).clamp(10.0, barArea),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fmtShortMonth(range.start as DateTime),
                      style: const TextStyle(
                        fontSize: 11,
                        color: PB.muted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 2px dashed rose line for the chart's average.
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PB.rose
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.cycle,
    required this.expanded,
    required this.onTap,
  });

  final Map<String, dynamic> cycle;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final range = cycle['range'] as dynamic;
    final start = range.start as DateTime;
    final end = range.end as DateTime;
    final status = cycle['status'] as String;
    final late = status != 'On time';
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBD9D6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        fmtShortMonth(start).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8F2F3D),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${start.day}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: Color(0xFF8F2F3D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fmtRangeLong(start, end),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${end.difference(start).inDays + 1} days · ${cycle['cycleLen'] != null ? '${cycle['cycleLen']}-day cycle' : 'first cycle'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PB.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: late ? PB.amberBg : PB.greenBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: late ? PB.amberText : PB.green,
                    ),
                  ),
                ),
              ],
            ),
            if (expanded)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: PB.rosePale,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Text(
                  'Period ${fmtRangeShort(start, end)} · Ovulation ${fmtDayMonth(cycle['ovulation'] as DateTime)} · Fertile ${fmtDayMonth(cycle['fertileStart'] as DateTime)}–${fmtDayMonth(cycle['fertileEnd'] as DateTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: PB.softText,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF8ECE9)),
          ],
        ),
      ),
    );
  }
}
