import 'package:flutter/material.dart';

void main() {
  runApp(const BuildCostApp());
}

class BuildCostApp extends StatelessWidget {
  const BuildCostApp({super.key});

  static const navy = Color(0xFF102A56);
  static const blue = Color(0xFF1E5EFF);
  static const orange = Color(0xFFFF8A00);
  static const bg = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BUILDCOST',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          primary: blue,
          secondary: orange,
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    HomePage(),
    ProjectsPage(),
    MaterialsPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F0FF),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Proyek'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Material'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BuildCostApp.blue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.construction, color: Colors.white, size: 27),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BUILDCOST', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: BuildCostApp.navy)),
                      Text('Construction Planning & Cost', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: null,
                    icon: Icon(Icons.notifications_none, color: BuildCostApp.navy),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text('Selamat datang 👋', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _NewProjectCard(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(child: Text('Proyek Terakhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BuildCostApp.navy))),
                  TextButton(onPressed: () {}, child: const Text('Lihat semua')),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(child: _ProjectCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            sliver: SliverToBoxAdapter(
              child: const Text('Fitur Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BuildCostApp.navy)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.12,
              children: [
                _FeatureCard(icon: Icons.architecture, title: 'Desain Proyek', subtitle: 'Pilih konsep desain', color: BuildCostApp.blue),
                _FeatureCard(icon: Icons.calculate_outlined, title: 'Hitung RAB', subtitle: 'Biaya & BOQ', color: BuildCostApp.orange),
                _FeatureCard(icon: Icons.inventory_2_outlined, title: 'Harga Material', subtitle: 'Database material', color: Colors.teal),
                _FeatureCard(icon: Icons.auto_awesome, title: 'Build AI', subtitle: 'Asisten proyek', color: Colors.deepPurple),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewProjectCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectPage())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [BuildCostApp.navy, BuildCostApp.blue]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: BuildCostApp.blue.withOpacity(.22), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.add_home_work_outlined, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buat Proyek Baru', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text('Mulai desain dan hitung estimasi biaya', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5EAF2))),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.house_outlined, color: BuildCostApp.blue, size: 32),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rumah Minimalis 6 × 9', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: BuildCostApp.navy)),
                    SizedBox(height: 5),
                    Text('Rumah • Wonosari', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.black45),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              const Expanded(child: Text('Estimasi biaya', style: TextStyle(fontSize: 12, color: Colors.black54))),
              Text('Rp203.500.000', style: TextStyle(fontWeight: FontWeight.w900, color: BuildCostApp.navy)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(value: .78, minHeight: 8, backgroundColor: Color(0xFFE9EDF5), color: BuildCostApp.orange),
          ),
          const SizedBox(height: 7),
          const Row(
            children: [
              Text('Progress proyek', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Spacer(),
              Text('78%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: BuildCostApp.orange)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFE6EAF1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 25),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: BuildCostApp.navy)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}

class CreateProjectPage extends StatelessWidget {
  const CreateProjectPage({super.key});

  final types = const [
    ('Rumah', Icons.house_outlined),
    ('Gedung', Icons.business_outlined),
    ('Pabrik', Icons.factory_outlined),
    ('Sekolah', Icons.school_outlined),
    ('Rumah Sakit', Icons.local_hospital_outlined),
    ('Hotel', Icons.hotel_outlined),
    ('Jalan', Icons.add_road),
    ('Jembatan', Icons.architecture),
    ('Bandara', Icons.flight_takeoff),
    ('Pelabuhan', Icons.directions_boat_outlined),
    ('Infrastruktur', Icons.construction_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Proyek Baru', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          const Text('Pilih Jenis Proyek', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: BuildCostApp.navy)),
          const SizedBox(height: 7),
          const Text('Pilih kategori yang paling sesuai dengan proyek Anda.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: types.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.25),
            itemBuilder: (context, i) {
              final item = types[i];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailFormPage(type: item.$1))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE3E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$2, color: BuildCostApp.blue, size: 30),
                      const Spacer(),
                      Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800, color: BuildCostApp.navy)),
                      const SizedBox(height: 4),
                      const Text('Pilih →', style: TextStyle(fontSize: 11, color: BuildCostApp.orange)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProjectDetailFormPage extends StatelessWidget {
  final String type;
  const ProjectDetailFormPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type, style: const TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Detail Proyek', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: BuildCostApp.navy)),
          const SizedBox(height: 18),
          _field('Nama Proyek', 'Contoh: Rumah Minimalis 6 × 9'),
          _field('Lokasi', 'Contoh: Wonosari'),
          Row(children: [Expanded(child: _field('Panjang (m)', '6')), const SizedBox(width: 12), Expanded(child: _field('Lebar (m)', '9'))]),
          Row(children: [Expanded(child: _field('Lantai', '1')), const SizedBox(width: 12), Expanded(child: _field('Anggaran', 'Rp'))]),
          const SizedBox(height: 10),
          const Text('Alur BUILDCOST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: BuildCostApp.navy)),
          const SizedBox(height: 12),
          const _FlowRow(icon: Icons.architecture, title: 'DESAIN', subtitle: 'Pilih konsep dan spesifikasi'),
          const _FlowRow(icon: Icons.calculate_outlined, title: 'BIAYA', subtitle: 'RAB & BOQ otomatis'),
          const _FlowRow(icon: Icons.trending_up, title: 'PROGRESS', subtitle: 'Pantau perkembangan proyek'),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BuildCostApp.orange, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignPage())),
            child: const Text('Lanjut Pilih Desain', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      decoration: InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
    ),
  );
}

class _FlowRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FlowRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(backgroundColor: const Color(0xFFEAF1FF), foregroundColor: BuildCostApp.blue, child: Icon(icon)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(subtitle),
  );
}

class DesignPage extends StatelessWidget {
  const DesignPage({super.key});

  @override
  Widget build(BuildContext context) {
    final designs = [
      ('Minimalis Modern', Icons.home_work_outlined),
      ('Modern Tropis', Icons.park_outlined),
      ('Klasik Elegan', Icons.account_balance_outlined),
      ('Industrial', Icons.factory_outlined),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Konsep Desain', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Konsep Desain', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: BuildCostApp.navy)),
          const SizedBox(height: 6),
          const Text('Gunakan template sebagai titik awal perencanaan proyek.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 18),
          ...designs.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE3E8F0))),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(width: 70, height: 70, decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(15)), child: Icon(d.$2, color: BuildCostApp.blue, size: 34)),
              title: Text(d.$1, style: const TextStyle(fontWeight: FontWeight.w800, color: BuildCostApp.navy)),
              subtitle: const Padding(padding: EdgeInsets.only(top: 5), child: Text('Preview konsep • Material • Estimasi')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          )),
          const SizedBox(height: 5),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Build AI — Coming Soon'),
          ),
        ],
      ),
    );
  }
}

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Daftar Proyek\n\nVersi berikutnya: filter, pencarian, status & dashboard proyek.', textAlign: TextAlign.center));
}

class MaterialsPage extends StatelessWidget {
  const MaterialsPage({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Database Material\n\nHarga material akan menjadi modul utama BUILDCOST.', textAlign: TextAlign.center));
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Akun & Pengaturan\n\nProfil, satuan, mata uang, backup dan paket BUILDCOST.', textAlign: TextAlign.center));
}
