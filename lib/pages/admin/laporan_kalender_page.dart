// lib/pages/admin/laporan_kalender_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/api_service.dart';

class LaporanKalenderPage extends StatefulWidget {
  const LaporanKalenderPage({super.key});

  @override
  State<LaporanKalenderPage> createState() => _LaporanKalenderPageState();
}

class _LaporanKalenderPageState extends State<LaporanKalenderPage> {
  static const String _semua = 'all';

  final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');

  // Data filter
  List<dynamic> _cabangList = [];
  List<dynamic> _satpamList = [];
  String _selectedCabangId = _semua;
  String _selectedSatpamId = _semua;

  // Kalender
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<String, dynamic> _ringkasanByTanggal = {};
  bool _isLoadingKalender = true;
  int _kalenderReq = 0;

  // Detail tanggal terpilih
  List<dynamic> _detailSatpam = [];
  bool _isLoadingDetail = true;
  int _detailReq = 0;

  @override
  void initState() {
    super.initState();
    _fetchFilter();
    _fetchKalender();
    _fetchDetail();
  }

  // ---------- Pengambilan data ----------

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchFilter() async {
    try {
      final data =
          await ApiService.fetchKalenderFilter(idCabang: _selectedCabangId);
      if (!mounted) return;
      setState(() {
        _cabangList = (data['cabang'] as List?) ?? [];
        _satpamList = (data['satpam'] as List?) ?? [];
      });
    } catch (e) {
      _showError('Gagal memuat filter: ${e.toString()}');
    }
  }

  Future<void> _fetchKalender() async {
    final req = ++_kalenderReq;
    setState(() => _isLoadingKalender = true);
    try {
      final data = await ApiService.fetchKalender(
        bulan: DateFormat('yyyy-MM').format(_focusedDay),
        idCabang: _selectedCabangId,
        idSatpam: _selectedSatpamId,
      );
      if (!mounted || req != _kalenderReq) return;
      final list = (data['tanggal'] as List?) ?? [];
      setState(() {
        _ringkasanByTanggal = {
          for (final r in list) r['tanggal'] as String: r,
        };
        _isLoadingKalender = false;
      });
    } catch (e) {
      if (!mounted || req != _kalenderReq) return;
      setState(() => _isLoadingKalender = false);
      _showError('Gagal memuat kalender: ${e.toString()}');
    }
  }

  Future<void> _fetchDetail() async {
    final req = ++_detailReq;
    setState(() => _isLoadingDetail = true);
    try {
      final data = await ApiService.fetchKalenderDetail(
        tanggal: _keyFormat.format(_selectedDay),
        idCabang: _selectedCabangId,
        idSatpam: _selectedSatpamId,
      );
      if (!mounted || req != _detailReq) return;
      setState(() {
        _detailSatpam = (data['satpam'] as List?) ?? [];
        _isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted || req != _detailReq) return;
      setState(() => _isLoadingDetail = false);
      _showError('Gagal memuat detail: ${e.toString()}');
    }
  }

  // ---------- Helper tanggal ----------

  bool _isFuture(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(day.year, day.month, day.day).isAfter(today);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilter(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) return _buildMobileView();
                return _buildDesktopView();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedCabangId,
              decoration: const InputDecoration(
                labelText: 'Cabang',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: _semua,
                  child: Text('Semua Cabang'),
                ),
                ..._cabangList.map<DropdownMenuItem<String>>((c) {
                  return DropdownMenuItem<String>(
                    value: c['id_cabang'].toString(),
                    child:
                        Text(c['nama'] ?? '-', overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (v) {
                if (v == null || v == _selectedCabangId) return;
                setState(() {
                  _selectedCabangId = v;
                  _selectedSatpamId =
                      _semua; // reset satpam saat cabang berubah
                });
                _fetchFilter();
                _fetchKalender();
                _fetchDetail();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedSatpamId,
              decoration: const InputDecoration(
                labelText: 'Satpam',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: _semua,
                  child: Text('Semua Satpam'),
                ),
                ..._satpamList.map<DropdownMenuItem<String>>((s) {
                  return DropdownMenuItem<String>(
                    value: s['id_user'].toString(),
                    child:
                        Text(s['nama'] ?? '-', overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (v) {
                if (v == null || v == _selectedSatpamId) return;
                setState(() => _selectedSatpamId = v);
                _fetchKalender();
                _fetchDetail();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan Mobile: kalender di atas, detail di bawah.
  Widget _buildMobileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCalendar(),
          _buildLegend(),
          _buildDetailSection(),
        ],
      ),
    );
  }

  /// Tampilan Desktop: kalender 60% (kiri), detail 40% (kanan).
  Widget _buildDesktopView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Lebar sel = (lebar area - margin kartu 32 - padding kartu 16) / 7
              final cellWidth = (constraints.maxWidth - 32 - 16) / 7;
              // Sisakan ruang untuk header, nama hari, dan legenda
              final maxByHeight = (constraints.maxHeight - 200) / 6;
              final byWidth = cellWidth * 0.8;
              final rowHeight = (byWidth < maxByHeight ? byWidth : maxByHeight)
                  .clamp(48.0, 100.0)
                  .toDouble();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCalendar(rowHeight: rowHeight),
                    _buildLegend(),
                  ],
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(child: _buildDetailSection()),
        ),
      ],
    );
  }

  Widget _buildCalendar({double rowHeight = 48}) {
    final now = DateTime.now();
    final fontSize = (rowHeight * 0.32).clamp(14.0, 24.0).toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(now.year, now.month + 1, 0), // akhir bulan ini
          focusedDay: _focusedDay,
          rowHeight: rowHeight,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: const CalendarStyle(outsideDaysVisible: false),
          enabledDayPredicate: (day) => !_isFuture(day),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
            _fetchDetail();
          },
          onPageChanged: (focused) {
            _focusedDay = focused;
            _fetchKalender();
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focused) =>
                _buildDayCell(day, fontSize: fontSize),
            todayBuilder: (context, day, focused) =>
                _buildDayCell(day, fontSize: fontSize),
            selectedBuilder: (context, day, focused) =>
                _buildDayCell(day, isSelected: true, fontSize: fontSize),
            disabledBuilder: (context, day, focused) =>
                _buildDayCell(day, fontSize: fontSize),
          ),
        ),
      ),
    );
  }

  /// Satu sel tanggal: hijau = ada patroli, merah = tidak ada patroli,
  /// abu-abu = belum terjadi / sedang memuat.
  /// Satu sel tanggal: hijau = ada patroli, merah = tidak ada patroli,
  /// abu-abu = belum terjadi / sedang memuat.
  Widget _buildDayCell(DateTime day,
      {bool isSelected = false, double fontSize = 14}) {
    final isToday = isSameDay(day, DateTime.now());
    final ringkasan = _ringkasanByTanggal[_keyFormat.format(day)];
    final hasPatrol = ringkasan != null;
    final adaTemuan =
        hasPatrol && ((ringkasan['jumlah_temuan'] ?? 0) as num) > 0;
    final dotSize = fontSize * 0.55;

    Color bg;
    Color fg = Colors.white;
    if (_isLoadingKalender || _isFuture(day)) {
      bg = Colors.grey.shade200;
      fg = Colors.black54;
    } else if (hasPatrol) {
      bg = Colors.green.shade600;
    } else {
      bg = Colors.red.shade400;
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: Colors.black87, width: 2.5)
            : (isToday ? Border.all(color: Colors.blue, width: 2) : null),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
          ),
          if (adaTemuan && !_isLoadingKalender)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String label, {bool circle = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circle ? null : BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          item(Colors.green.shade600, 'Ada patroli'),
          item(Colors.red.shade400, 'Tidak ada patroli'),
          item(Colors.grey.shade300, 'Belum terjadi'),
          item(Colors.amber, 'Ada temuan', circle: true),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(_selectedDay),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_isLoadingDetail)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_detailSatpam.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_busy, color: Colors.red.shade400),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Tidak ada patroli pada tanggal ini.'),
                  ),
                ],
              ),
            )
          else
            ..._detailSatpam.map(_buildSatpamCard),
        ],
      ),
    );
  }

  Widget _buildSatpamCard(dynamic satpam) {
    final List patroli = (satpam['patroli'] as List?) ?? [];
    final int jumlahTemuan = (satpam['jumlah_temuan'] ?? 0) as int;

    // Jam mulai titik pertama s/d jam selesai titik terakhir
    final String jamMulai = patroli.isNotEmpty
        ? (patroli.first['jam_mulai'] ?? '-').toString()
        : '-';
    final String jamSelesai = patroli.isNotEmpty
        ? (patroli.last['jam_selesai'] ?? patroli.last['jam_mulai'] ?? '-')
            .toString()
        : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key:
            ValueKey('${_keyFormat.format(_selectedDay)}-${satpam['id_user']}'),
        initiallyExpanded: false,
        leading: const CircleAvatar(child: Icon(Icons.security)),
        title: Text(
          satpam['nama'] ?? '-',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${satpam['cabang'] ?? '-'} • ${patroli.length} titik'
              '${jumlahTemuan > 0 ? ' • $jumlahTemuan temuan' : ''}',
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$jamMulai - $jamSelesai',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        children: patroli.map<Widget>(_buildPatroliTile).toList(),
      ),
    );
  }

  Widget _buildPatroliTile(dynamic p) {
    final bool adaTemuan = p['ada_temuan'] == true;
    final String catatan = (p['catatan'] ?? '').toString();

    return ListTile(
      dense: true,
      leading: Icon(
        adaTemuan ? Icons.warning : Icons.check_circle,
        color: adaTemuan ? Colors.red : Colors.green,
      ),
      title: Text(p['titik'] ?? '-'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${p['jam_mulai'] ?? '-'} - ${p['jam_selesai'] ?? '-'}'),
          if (adaTemuan && catatan.isNotEmpty)
            Text(
              'Catatan: $catatan',
              style: TextStyle(color: Colors.red.shade700),
            ),
        ],
      ),
    );
  }
}
