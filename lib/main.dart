import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuildCostApp());
}

const Color navy = Color(0xFF102A56);
const Color blue = Color(0xFF1E5EFF);
const Color orange = Color(0xFFFF8A00);
const Color pageBg = Color(0xFFF5F7FB);

String rupiah(num value) {
  final s = value.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    b.write(s[i]);
    final left = s.length - i - 1;
    if (left > 0 && left % 3 == 0) b.write('.');
  }
  return 'Rp $b';
}

class BuildCostApp extends StatelessWidget {
  const BuildCostApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BUILDCOST',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: blue),
          scaffoldBackgroundColor: pageBg,
          appBarTheme: const AppBarTheme(
            backgroundColor: navy,
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        home: const AppShell(),
      );
}

class Project {
  String id, name, type, location, design;
  double length, width, progress, budget;
  int floors;

  Project({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.design,
    required this.length,
    required this.width,
    required this.floors,
    required this.progress,
    required this.budget,
  });

  double get area => length * width * floors;
  // Perkiraan awal: bukan pengganti analisis volume dan harga satuan profesional.
  double get estimate => budget > 0 ? budget : area * 3200000;

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'type': type, 'location': location,
        'design': design, 'length': length, 'width': width,
        'floors': floors, 'progress': progress, 'budget': budget,
      };

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: '${j['id'] ?? DateTime.now().microsecondsSinceEpoch}',
        name: '${j['name'] ?? 'Proyek Baru'}',
        type: '${j['type'] ?? 'Rumah'}',
        location: '${j['location'] ?? ''}',
        design: '${j['design'] ?? 'Minimalis Modern'}',
        length: (j['length'] as num? ?? 6).toDouble(),
        width: (j['width'] as num? ?? 9).toDouble(),
        floors: (j['floors'] as num? ?? 1).toInt(),
        progress: (j['progress'] as num? ?? 0).toDouble(),
        budget: (j['budget'] as num? ?? 0).toDouble(),
      );
}

class MaterialEntry {
  String name, unit;
  double price;
  MaterialEntry(this.name, this.unit, this.price);
  Map<String, dynamic> toJson() => {'name': name, 'unit': unit, 'price': price};
  factory MaterialEntry.fromJson(Map<String, dynamic> j) => MaterialEntry(
        '${j['name'] ?? ''}', '${j['unit'] ?? 'unit'}',
        (j['price'] as num? ?? 0).toDouble(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  bool loading = true;
  String userName = 'Pengguna BUILDCOST';
  List<Project> projects = [];
  List<MaterialEntry> materials = [
    MaterialEntry('Semen Portland 50 kg', 'sak', 75000),
    MaterialEntry('Pasir pasang', 'm³', 280000),
    MaterialEntry('Batu split', 'm³', 320000),
    MaterialEntry('Bata merah', 'buah', 1000),
    MaterialEntry('Besi beton 10 mm', 'batang', 78000),
    MaterialEntry('Keramik lantai', 'm²', 95000),
    MaterialEntry('Cat tembok', 'kg', 35000),
    MaterialEntry('Upah tukang', 'OH', 150000),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final p = prefs.getString('bc_projects_v2');
      if (p != null) {
        projects = (jsonDecode(p) as List)
            .map((e) => Project.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      final m = prefs.getString('bc_materials_v2');
      if (m != null) {
        materials = (jsonDecode(m) as List)
            .map((e) => MaterialEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      userName = prefs.getString('bc_user_v2') ?? userName;
    } catch (_) {
      // Jika data lama tidak valid, aplikasi tetap dibuka.
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bc_projects_v2', jsonEncode(projects.map((e) => e.toJson()).toList()));
    await prefs.setString('bc_materials_v2', jsonEncode(materials.map((e) => e.toJson()).toList()));
    await prefs.setString('bc_user_v2', userName);
  }

  Future<void> _form([Project? existing]) async {
    final result = await Navigator.push<Project>(
      context, MaterialPageRoute(builder: (_) => ProjectForm(existing: existing)),
    );
    if (result == null) return;
    final i = projects.indexWhere((p) => p.id == result.id);
    setState(() {
      if (i < 0) {
        projects.insert(0, result);
      } else {
        projects[i] = result;
      }
    });
    await _save();
  }

  Future<void> _detail(Project project) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetail(
          project: project,
          materials: materials,
          onSave: () async {
            if (mounted) setState(() {});
            await _save();
          },
          onEdit: () => _form(project),
        ),
      ),
    );
    if (mounted) setState(() {});
    await _save();
  }

  Future<void> _materialForm([int? index]) async {
    final old = index == null ? null : materials[index];
    final n = TextEditingController(text: old?.name ?? '');
    final u = TextEditingController(text: old?.unit ?? 'unit');
    final p = TextEditingController(text: old == null ? '' : old.price.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(old == null ? 'Tambah material' : 'Edit material'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Nama material')),
          const SizedBox(height: 10),
          TextField(controller: u, decoration: const InputDecoration(labelText: 'Satuan')),
          const SizedBox(height: 10),
          TextField(controller: p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga satuan (Rp)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true && n.text.trim().isNotEmpty) {
      final price = double.tryParse(p.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
      setState(() {
        final entry = MaterialEntry(n.text.trim(), u.text.trim().isEmpty ? 'unit' : u.text.trim(), price);
        if (index == null) {
          materials.add(entry);
        } else {
          materials[index] = entry;
        }
      });
      await _save();
    }
    n.dispose(); u.dispose(); p.dispose();
  }

  Future<void> _profile() async {
    final c = TextEditingController(text: userName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nama pengguna'),
        content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Nama')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      setState(() => userName = c.text.trim());
      await _save();
    }
    c.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _projectList(), _materialList(), _account()];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.architecture, color: navy),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BUILDCOST', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            Text('DESAIN • BIAYA • PROGRESS', style: TextStyle(fontSize: 9)),
          ]),
        ]),
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) : IndexedStack(index: tab, children: pages),
      floatingActionButton: tab == 0 || tab == 1
          ? FloatingActionButton.extended(
              onPressed: () => _form(),
              backgroundColor: orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Buat Proyek'),
            )
          : tab == 2
              ? FloatingActionButton(
                  onPressed: () => _materialForm(),
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment), label: 'Proyek'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Material'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }

  Widget _home() {
    final total = projects.fold<double>(0, (sum, p) => sum + p.estimate);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [navy, blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Halo, $userName', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          const Text('Rencanakan bangunan dengan lebih terukur.', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _stat('Proyek tersimpan', '${projects.length}')),
            const SizedBox(width: 10),
            Expanded(child: _stat('Estimasi total', rupiah(total))),
          ]),
        ]),
      ),
      const SizedBox(height: 22),
      _heading('Akses cepat', 'Mulai sekarang'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _quick(Icons.add_home_work, 'Buat proyek', () => _form())),
        const SizedBox(width: 10),
        Expanded(child: _quick(Icons.calculate_outlined, 'Buka RAB', () {
          if (projects.isEmpty) {
            _form();
          } else {
            _detail(projects.first);
          }
        })),
      ]),
      const SizedBox(height: 22),
      _heading('Proyek terbaru', 'Ketuk untuk detail'),
      const SizedBox(height: 10),
      if (projects.isEmpty)
        _empty('Belum ada proyek', 'Tekan tombol Buat Proyek untuk memulai.')
      else
        ...projects.take(5).map(_projectCard),
      const SizedBox(height: 88),
    ]);
  }

  Widget _projectList() => ListView(padding: const EdgeInsets.all(16), children: [
        _heading('Semua proyek', '${projects.length} tersimpan'),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          _empty('Belum ada proyek', 'Tambahkan proyek pertama kamu.')
        else
          ...projects.map(_projectCard),
        const SizedBox(height: 88),
      ]);

  Widget _materialList() => ListView(padding: const EdgeInsets.all(16), children: [
        _heading('Database material', 'Harga dapat diedit'),
        const SizedBox(height: 12),
        ...materials.asMap().entries.map((e) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFEAF0FF), child: Icon(Icons.inventory_2_outlined, color: blue)),
                title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${rupiah(e.value.price)} / ${e.value.unit}'),
                trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _materialForm(e.key)),
              ),
            )),
        const SizedBox(height: 88),
      ]);

  Widget _account() => ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(22)),
          child: const Column(children: [
            CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Icon(Icons.engineering, color: navy, size: 38)),
            SizedBox(height: 12),
            Text('BUILDCOST', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Construction Planning & Cost Platform', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 12),
        Card(elevation: 0, child: ListTile(leading: const Icon(Icons.person_outline), title: const Text('Nama pengguna'), subtitle: Text(userName), trailing: const Icon(Icons.edit), onTap: _profile)),
        const Card(elevation: 0, child: ListTile(leading: Icon(Icons.smart_toy_outlined), title: Text('Build AI'), subtitle: Text('Segera hadir setelah fitur utama stabil'), trailing: Icon(Icons.lock_outline))),
        const Card(elevation: 0, child: ListTile(leading: Icon(Icons.info_outline), title: Text('Tentang BUILDCOST'), subtitle: Text('Membantu merencanakan desain dan estimasi biaya bangunan.'))),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Catatan: estimasi RAB adalah perkiraan awal. Periksa harga lokal dan mintalah pemeriksaan tenaga profesional untuk perhitungan final.', style: TextStyle(color: Colors.black54)),
        ),
      ]);

  Widget _projectCard(Project p) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _detail(p),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              Container(
                width: 54, height: 62,
                decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 29),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${p.type} • ${p.length} × ${p.width} m • ${p.floors} lantai', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 5),
                Text(rupiah(p.estimate), style: const TextStyle(color: blue, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (p.progress / 100).clamp(0.0, 1.0), minHeight: 5)),
              ])),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    await _form(p);
                  } else {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus proyek?'),
                        content: Text('Proyek "${p.name}" akan dihapus dari perangkat.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                        ],
                      ),
                    );
                    if (yes == true) {
                      setState(() => projects.removeWhere((x) => x.id == p.id));
                      await _save();
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit proyek')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus proyek')),
                ],
              ),
            ]),
          ),
        ),
      );

  Widget _heading(String title, String subtitle) => Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: navy))),
        const SizedBox(width: 6),
        Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ]);

  Widget _stat(String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
      );

  Widget _quick(IconData icon, String label, VoidCallback onTap) => Card(
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Icon(icon, color: blue, size: 30),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );

  Widget _empty(String title, String desc) => Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            const Icon(Icons.add_home_work_outlined, color: blue, size: 42),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ]),
        ),
      );
}

class ProjectForm extends StatefulWidget {
  final Project? existing;
  const ProjectForm({super.key, this.existing});
  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final keyForm = GlobalKey<FormState>();
  late final TextEditingController name, location, length, width, floors, budget;
  late String type, design;
  late double progress;

  final types = const ['Rumah', 'Gedung', 'Pabrik', 'Sekolah', 'Rumah Sakit', 'Hotel', 'Jalan', 'Jembatan', 'Bandara', 'Pelabuhan', 'Infrastruktur'];
  final designs = const ['Minimalis Modern', 'Modern Tropis', 'Klasik Elegan', 'Industrial'];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    name = TextEditingController(text: p?.name ?? '');
    location = TextEditingController(text: p?.location ?? '');
    length = TextEditingController(text: '${p?.length ?? 6}');
    width = TextEditingController(text: '${p?.width ?? 9}');
    floors = TextEditingController(text: '${p?.floors ?? 1}');
    budget = TextEditingController(text: p == null || p.budget == 0 ? '' : p.budget.toStringAsFixed(0));
    type = p?.type ?? 'Rumah';
    design = p?.design ?? designs.first;
    progress = p?.progress ?? 0;
  }

  @override
  void dispose() {
    name.dispose(); location.dispose(); length.dispose(); width.dispose(); floors.dispose(); budget.dispose();
    super.dispose();
  }

  double parse(TextEditingController c, double fallback) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? fallback;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.existing == null ? 'Buat Proyek' : 'Edit Proyek')),
        body: Form(
          key: keyForm,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('DETAIL PROYEK', style: TextStyle(color: blue, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 12),
            TextFormField(controller: name, validator: (v) => v == null || v.trim().isEmpty ? 'Nama proyek wajib diisi' : null, decoration: const InputDecoration(labelText: 'Nama proyek', hintText: 'Contoh: Rumah Minimalis 6 × 9')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Jenis bangunan'),
              items: types.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => type = v ?? type),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: location, decoration: const InputDecoration(labelText: 'Lokasi proyek')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: length, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _required, decoration: const InputDecoration(labelText: 'Panjang (m)'))),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: width, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _required, decoration: const InputDecoration(labelText: 'Lebar (m)'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: floors, keyboardType: TextInputType.number, validator: _required, decoration: const InputDecoration(labelText: 'Jumlah lantai/tingkat'))),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: budget, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Anggaran opsional', prefixText: 'Rp '))),
            ]),
            const SizedBox(height: 20),
            const Text('KONSEP DESAIN', style: TextStyle(color: blue, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 8),
            ...designs.map(_designCard),
            const SizedBox(height: 12),
            Text('Progress pekerjaan: ${progress.toStringAsFixed(0)}%'),
            Slider(value: progress, min: 0, max: 100, divisions: 20, activeColor: blue, onChanged: (v) => setState(() => progress = v)),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: blue, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan Proyek'),
            ),
          ]),
        ),
      );

  String? _required(String? v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null;

  Widget _designCard(String value) {
    final selected = design == value;
    final icons = <String, IconData>{
      'Minimalis Modern': Icons.domain,
      'Modern Tropis': Icons.nature,
      'Klasik Elegan': Icons.account_balance,
      'Industrial': Icons.factory,
    };
    final descriptions = <String, String>{
      'Minimalis Modern': 'Garis tegas, sederhana, fungsional',
      'Modern Tropis': 'Nuansa alami dan ruang terbuka',
      'Klasik Elegan': 'Proporsi simetris dan detail elegan',
      'Industrial': 'Karakter kuat dengan material terekspos',
    };
    return Card(
      elevation: 0,
      color: selected ? const Color(0xFFEAF0FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: selected ? blue : Colors.grey.shade200),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: design,
        activeColor: blue,
        onChanged: (v) => setState(() => design = v ?? design),
        secondary: CircleAvatar(backgroundColor: navy, child: Icon(icons[value], color: Colors.white)),
        title: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(descriptions[value]!),
      ),
    );
  }

  void _save() {
    if (!keyForm.currentState!.validate()) return;
    final l = parse(length, 0);
    final w = parse(width, 0);
    final f = int.tryParse(floors.text) ?? 0;
    if (l <= 0 || w <= 0 || f <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ukuran dan jumlah lantai harus lebih dari nol.')));
      return;
    }
    Navigator.pop(context, Project(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.text.trim(),
      type: type,
      location: location.text.trim(),
      design: design,
      length: l,
      width: w,
      floors: f,
      progress: progress,
      budget: parse(budget, 0),
    ));
  }
}

class ProjectDetail extends StatefulWidget {
  final Project project;
  final List<MaterialEntry> materials;
  final Future<void> Function() onSave;
  final VoidCallback onEdit;
  const ProjectDetail({super.key, required this.project, required this.materials, required this.onSave, required this.onEdit});
  @override
  State<ProjectDetail> createState() => _ProjectDetailState();
}

class _ProjectDetailState extends State<ProjectDetail> {
  late double progress;

  static const List<(String, double)> workItems = [
    ('Persiapan dan pembersihan', .04),
    ('Pondasi dan pekerjaan tanah', .13),
    ('Struktur beton dan besi', .20),
    ('Dinding dan plester', .12),
    ('Atap dan rangka', .10),
    ('Lantai dan keramik', .08),
    ('Pintu, jendela, dan kusen', .08),
    ('Instalasi listrik dan air', .08),
    ('Plafon dan pengecatan', .08),
    ('Finishing dan cadangan', .09),
  ];

  @override
  void initState() {
    super.initState();
    progress = widget.project.progress;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Proyek'), actions: [
        IconButton(onPressed: widget.onEdit, icon: const Icon(Icons.edit_outlined)),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, blue]), borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.type.toUpperCase(), style: const TextStyle(color: Colors.white70, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
            if (p.location.isNotEmpty) Text(p.location, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 18),
            Text(rupiah(p.estimate), style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
            const Text('Estimasi biaya awal', style: TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _metric('Luas perkiraan', '${p.area.toStringAsFixed(1)} m²', Icons.square_foot)),
          const SizedBox(width: 10),
          Expanded(child: _metric('Konsep desain', p.design, Icons.architecture)),
        ]),
        const SizedBox(height: 20),
        const Text('Progress proyek', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: navy)),
        Text('${progress.toStringAsFixed(0)}% selesai'),
        Slider(
          value: progress, min: 0, max: 100, divisions: 20, activeColor: blue,
          onChanged: (v) => setState(() => progress = v),
          onChangeEnd: (v) async {
            p.progress = v;
            await widget.onSave();
          },
        ),
        const SizedBox(height: 12),
        const Text('Rencana Anggaran Biaya (RAB)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: navy)),
        const SizedBox(height: 4),
        const Text('Pembagian ini merupakan estimasi kasar, bukan RAB final berbasis volume dan analisis harga satuan.', style: TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 10),
        ...workItems.map((item) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 7),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(children: [
                  Expanded(child: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('${(item.$2 * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(width: 10),
                  Text(rupiah(p.estimate * item.$2), style: const TextStyle(fontWeight: FontWeight.bold, color: blue)),
                ]),
              ),
            )),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Contoh harga material tersimpan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...widget.materials.take(5).map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(child: Text(m.name)),
                      Text('${rupiah(m.price)}/${m.unit}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  )),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: widget.onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Edit detail proyek')),
      ]),
    );
  }

  Widget _metric(String title, String value, IconData icon) => Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: blue),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ),
      );
}
