import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuildCostApp());
}

// ============================================================
// WARNA DAN UTILITAS
// ============================================================

const Color bcNavy = Color(0xFF102A56);
const Color bcBlue = Color(0xFF1E5EFF);
const Color bcOrange = Color(0xFFFF8A00);
const Color bcBackground = Color(0xFFF5F7FB);
const Color bcGreen = Color(0xFF16A36A);
const Color bcRed = Color(0xFFE5484D);

String rupiah(num value) {
  final String raw = value.round().toString();
  final StringBuffer result = StringBuffer();

  for (int i = 0; i < raw.length; i++) {
    result.write(raw[i]);

    final int remaining = raw.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) {
      result.write('.');
    }
  }

  return 'Rp ${result.toString()}';
}

double parseNumber(String value) {
  String text = value.trim().replaceAll('Rp', '').replaceAll(' ', '');

  if (text.isEmpty) return 0;

  if (text.contains(',') && text.contains('.')) {
    if (text.lastIndexOf(',') > text.lastIndexOf('.')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '');
    }
  } else if (text.contains(',')) {
    text = text.replaceAll(',', '.');
  } else if (RegExp(r'^-?\d{1,3}(\.\d{3})+$').hasMatch(text)) {
    text = text.replaceAll('.', '');
  }

  return double.tryParse(text) ?? 0;
}

// ============================================================
// MODEL ITEM RAB
// ============================================================

class RabItem {
  String name;
  String unit;
  double volume;
  double price;

  RabItem({
    required this.name,
    required this.unit,
    required this.volume,
    required this.price,
  });

  double get total => volume * price;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'volume': volume,
      'price': price,
    };
  }

  factory RabItem.fromJson(Map<String, dynamic> json) {
    return RabItem(
      name: '${json['name'] ?? 'Pekerjaan'}',
      unit: '${json['unit'] ?? 'unit'}',
      volume: (json['volume'] as num? ?? 0).toDouble(),
      price: (json['price'] as num? ?? 0).toDouble(),
    );
  }
}

// ============================================================
// MODEL PROYEK
// ============================================================

class BuildProject {
  String id;
  String name;
  String type;
  String location;
  String design;

  double length;
  double width;
  double progress;
  double contingency;

  int floors;

  List<RabItem> items;

  BuildProject({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.design,
    required this.length,
    required this.width,
    required this.floors,
    required this.progress,
    required this.contingency,
    required this.items,
  });

  double get area => length * width * floors;

  double get subtotal {
    return items.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
  }

  double get reserve => subtotal * contingency / 100;

  double get total => subtotal + reserve;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': location,
      'design': design,
      'length': length,
      'width': width,
      'floors': floors,
      'progress': progress,
      'contingency': contingency,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory BuildProject.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems =
        (json['items'] as List?) ?? [];

    return BuildProject(
      id: '${json['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      name: '${json['name'] ?? 'Proyek Baru'}',
      type: '${json['type'] ?? 'Rumah'}',
      location: '${json['location'] ?? ''}',
      design: '${json['design'] ?? 'Minimalis Modern'}',
      length: (json['length'] as num? ?? 6).toDouble(),
      width: (json['width'] as num? ?? 9).toDouble(),
      floors: (json['floors'] as num? ?? 1).toInt(),
      progress: (json['progress'] as num? ?? 0).toDouble(),
      contingency: (json['contingency'] as num? ?? 5).toDouble(),
      items: rawItems.map((item) {
        return RabItem.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList(),
    );
  }
}

// ============================================================
// MODEL MATERIAL
// ============================================================

class BuildMaterial {
  String name;
  String unit;
  double price;

  BuildMaterial({
    required this.name,
    required this.unit,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'price': price,
    };
  }

  factory BuildMaterial.fromJson(Map<String, dynamic> json) {
    return BuildMaterial(
      name: '${json['name'] ?? 'Material'}',
      unit: '${json['unit'] ?? 'unit'}',
      price: (json['price'] as num? ?? 0).toDouble(),
    );
  }
}

// ============================================================
// APLIKASI
// ============================================================

class BuildCostApp extends StatelessWidget {
  const BuildCostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUILDCOST',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: bcBlue,
          primary: bcBlue,
          secondary: bcOrange,
        ),
        scaffoldBackgroundColor: bcBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: bcNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE0E6EF),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFFE8EDF5),
            ),
          ),
        ),
      ),
      home: const BuildCostHome(),
    );
  }
}

// ============================================================
// HALAMAN UTAMA
// ============================================================

class BuildCostHome extends StatefulWidget {
  const BuildCostHome({super.key});

  @override
  State<BuildCostHome> createState() => _BuildCostHomeState();
}

class _BuildCostHomeState extends State<BuildCostHome> {
  int selectedTab = 0;
  bool loading = true;

  String username = 'Pengguna';

  List<BuildProject> projects = [];
  List<BuildMaterial> materials = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  List<BuildMaterial> defaultMaterials() {
    return [
      BuildMaterial(
        name: 'Semen Portland',
        unit: 'sak',
        price: 75000,
      ),
      BuildMaterial(
        name: 'Pasir pasang',
        unit: 'm³',
        price: 280000,
      ),
      BuildMaterial(
        name: 'Batu split',
        unit: 'm³',
        price: 320000,
      ),
      BuildMaterial(
        name: 'Bata merah',
        unit: 'buah',
        price: 1000,
      ),
      BuildMaterial(
        name: 'Besi beton 10 mm',
        unit: 'batang',
        price: 78000,
      ),
      BuildMaterial(
        name: 'Keramik lantai',
        unit: 'm²',
        price: 95000,
      ),
      BuildMaterial(
        name: 'Cat tembok',
        unit: 'kg',
        price: 35000,
      ),
      BuildMaterial(
        name: 'Upah tukang',
        unit: 'OH',
        price: 150000,
      ),
    ];
  }

  Future<void> loadData() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    try {
      final String savedProjects =
          prefs.getString('bc_projects_v3') ?? '[]';

      final String savedMaterials =
          prefs.getString('bc_materials_v3') ?? '';

      final dynamic decodedProjects =
          jsonDecode(savedProjects);

      projects = (decodedProjects as List).map((item) {
        return BuildProject.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();

      if (savedMaterials.isNotEmpty) {
        final dynamic decodedMaterials =
            jsonDecode(savedMaterials);

        materials = (decodedMaterials as List).map((item) {
          return BuildMaterial.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }

      if (materials.isEmpty) {
        materials = defaultMaterials();
      }

      username =
          prefs.getString('bc_user_v3') ?? 'Pengguna';
    } catch (error) {
      materials = defaultMaterials();
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> saveData() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'bc_projects_v3',
      jsonEncode(
        projects.map((project) => project.toJson()).toList(),
      ),
    );

    await prefs.setString(
      'bc_materials_v3',
      jsonEncode(
        materials.map((material) => material.toJson()).toList(),
      ),
    );

    await prefs.setString('bc_user_v3', username);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      dashboardPage(),
      projectListPage(),
      materialPage(),
      accountPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.architecture, size: 30),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUILDCOST',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'DESAIN • RAB • PROGRESS',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: selectedTab,
              children: pages,
            ),
      floatingActionButton: selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: () => openProjectForm(),
              backgroundColor: bcOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Buat Proyek'),
            )
          : selectedTab == 2
              ? FloatingActionButton(
                  onPressed: () => openMaterialForm(),
                  backgroundColor: bcOrange,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Proyek',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Material',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
 // ============================================================
// DASHBOARD BUILDCOST
// ============================================================

  Widget dashboardPage() {
    final double totalBudget = projects.fold<double>(
      0,
      (sum, project) => sum + project.total,
    );

    final double averageProgress = projects.isEmpty
        ? 0
        : projects.fold<double>(
              0,
              (sum, project) => sum + project.progress,
            ) /
            projects.length;

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [bcNavy, bcBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLATFORM PERENCANAAN KONSTRUKSI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Halo, $username!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rencanakan bangunan, hitung anggaran, '
                  'dan pantau progres dalam satu aplikasi.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => openProjectForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Proyek Baru'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bcOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedTab = 1;
                          });
                        },
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Lihat Proyek'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white70,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Ringkasan Proyek',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: bcNavy,
            ),
          ),

          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.48,
            children: [
              summaryCard(
                title: 'Total Proyek',
                value: '${projects.length}',
                subtitle: 'Proyek tersimpan',
                icon: Icons.apartment,
                color: bcBlue,
              ),
              summaryCard(
                title: 'Total Estimasi',
                value: compactRupiah(totalBudget),
                subtitle: 'Anggaran seluruh proyek',
                icon: Icons.account_balance_wallet,
                color: bcOrange,
              ),
              summaryCard(
                title: 'Rata-rata Progress',
                value: '${averageProgress.toStringAsFixed(0)}%',
                subtitle: 'Kemajuan proyek',
                icon: Icons.trending_up,
                color: bcGreen,
              ),
              summaryCard(
                title: 'Data Material',
                value: '${materials.length}',
                subtitle: 'Material tersimpan',
                icon: Icons.inventory_2,
                color: const Color(0xFF7956D8),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Proyek Terbaru',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: bcNavy,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedTab = 1;
                  });
                },
                child: const Text('Lihat Semua'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (projects.isEmpty)
            emptyState(
              icon: Icons.domain_add,
              title: 'Belum Ada Proyek',
              message:
                  'Mulai dengan membuat proyek bangunan pertamamu.',
              buttonText: 'Buat Proyek Pertama',
              onPressed: () => openProjectForm(),
            )
          else
            ...projects.reversed.take(3).map(
                  (project) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: projectCard(project),
                  ),
                ),

          const SizedBox(height: 20),

          const Text(
            'Fitur BUILDCOST',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: bcNavy,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: featureCard(
                  icon: Icons.design_services,
                  title: 'Konsep Desain',
                  subtitle: 'Pratinjau bangunan',
                  color: bcBlue,
                  onTap: () {
                    setState(() {
                      selectedTab = 1;
                    });
                    if (projects.isNotEmpty) {
                      openProjectDetail(projects.last);
                    } else {
                      openProjectForm();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: featureCard(
                  icon: Icons.receipt_long,
                  title: 'RAB',
                  subtitle: 'Estimasi anggaran',
                  color: bcOrange,
                  onTap: () {
                    setState(() {
                      selectedTab = 1;
                    });
                    if (projects.isNotEmpty) {
                      openRab(projects.last);
                    } else {
                      openProjectForm();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

// ============================================================
// KARTU STATISTIK
// ============================================================

  String compactRupiah(double value) {
    if (value >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)} M';
    }

    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
    }

    if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)} rb';
    }

    return rupiah(value);
  }

  Widget summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const Spacer(),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: bcNavy,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// KARTU FITUR
// ============================================================

  Widget featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8EDF5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 30,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: bcNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// TAMPILAN KOSONG
// ============================================================

  Widget emptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 52,
            color: bcBlue,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: bcNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }

// ============================================================
// DAFTAR PROYEK
// ============================================================

  Widget projectListPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Manajemen Proyek',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: bcNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kelola bangunan, desain, anggaran, dan progres.',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        if (projects.isEmpty)
          emptyState(
            icon: Icons.apartment,
            title: 'Belum Ada Proyek',
            message:
                'Buat proyek untuk mulai menyusun rencana bangunan.',
            buttonText: 'Tambah Proyek',
            onPressed: () => openProjectForm(),
          )
        else
          ...projects.reversed.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: projectCard(project),
            ),
          ),
        const SizedBox(height: 90),
      ],
    );
  }

// ============================================================
// KARTU PROYEK
// ============================================================

  Widget projectCard(BuildProject project) {
    return InkWell(
      onTap: () => openProjectDetail(project),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE4EAF3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bcBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: bcBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: bcNavy,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${project.type} • ${project.design}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      openProjectForm(project: project);
                    } else if (value == 'delete') {
                      confirmDeleteProject(project);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Proyek'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus Proyek'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.black45,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    project.location.isEmpty
                        ? 'Lokasi belum diisi'
                        : project.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimasi Anggaran',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Flexible(
                  child: Text(
                    rupiah(project.total),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: bcBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (project.progress / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFE8EDF5),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  bcGreen,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${project.progress.toStringAsFixed(0)}% selesai',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  '${project.length} × ${project.width} m • ${project.floors} lantai',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Lihat Detail',
                  style: TextStyle(
                    color: bcBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  color: bcBlue,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// FORM TAMBAH DAN EDIT PROYEK
// ============================================================

  Future<void> openProjectForm({
    BuildProject? project,
  }) async {
    final bool editing = project != null;

    final TextEditingController nameController =
        TextEditingController(text: project?.name ?? '');

    final TextEditingController locationController =
        TextEditingController(text: project?.location ?? '');

    final TextEditingController lengthController =
        TextEditingController(
      text: (project?.length ?? 6).toString(),
    );

    final TextEditingController widthController =
        TextEditingController(
      text: (project?.width ?? 9).toString(),
    );

    final List<String> types = [
      'Rumah',
      'Ruko',
      'Gedung',
      'Jalan',
      'Jembatan',
      'Gudang',
      'Hotel',
      'Bandara',
      'Lainnya',
    ];

    final List<String> designs = [
      'Minimalis Modern',
      'Modern Tropis',
      'Klasik Elegan',
      'Industrial',
      'Kontemporer',
      'Futuristik',
    ];

    String selectedType = project?.type ?? 'Rumah';
    String selectedDesign =
        project?.design ?? 'Minimalis Modern';

    int floors = project?.floors ?? 1;
    double contingency = project?.contingency ?? 5;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                editing ? 'Edit Proyek' : 'Buat Proyek Baru',
                style: const TextStyle(
                  color: bcNavy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama proyek',
                          hintText: 'Contoh: Rumah Keluarga',
                          prefixIcon: Icon(Icons.apartment),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi proyek',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Jenis proyek',
                        ),
                        items: types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDesign,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Konsep desain',
                        ),
                        items: designs.map((design) {
                          return DropdownMenuItem(
                            value: design,
                            child: Text(design),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedDesign = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: lengthController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Panjang (m)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: widthController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Lebar (m)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Jumlah lantai',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: floors > 1
                                ? () {
                                    setDialogState(() {
                                      floors--;
                                    });
                                  }
                                : null,
                            icon: const Icon(
                              Icons.remove_circle_outline,
                            ),
                          ),
                          Text(
                            '$floors',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          IconButton(
                            onPressed: floors < 100
                                ? () {
                                    setDialogState(() {
                                      floors++;
                                    });
                                  }
                                : null,
                            icon: const Icon(
                              Icons.add_circle_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Cadangan biaya',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${contingency.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: bcBlue,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: contingency,
                        min: 0,
                        max: 20,
                        divisions: 20,
                        label: '${contingency.toStringAsFixed(0)}%',
                        onChanged: (value) {
                          setDialogState(() {
                            contingency = value;
                          });
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Luas yang ditampilkan merupakan '
                        'perkiraan berdasarkan dimensi dan '
                        'jumlah lantai. Metode pengukuran '
                        'untuk jalan, jembatan, dan proyek '
                        'khusus perlu disesuaikan.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () async {
                    final String name = nameController.text.trim();
                    final double length =
                        parseNumber(lengthController.text);
                    final double width =
                        parseNumber(widthController.text);

                    if (name.isEmpty ||
                        length <= 0 ||
                        width <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Isi nama dan dimensi dengan benar.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (editing) {
                      project.name = name;
                      project.location =
                          locationController.text.trim();
                      project.type = selectedType;
                      project.design = selectedDesign;
                      project.length = length;
                      project.width = width;
                      project.floors = floors;
                      project.contingency = contingency;
                    } else {
                      final BuildProject newProject = BuildProject(
                        id: DateTime.now()
                            .microsecondsSinceEpoch
                            .toString(),
                        name: name,
                        type: selectedType,
                        location: locationController.text.trim(),
                        design: selectedDesign,
                        length: length,
                        width: width,
                        floors: floors,
                        progress: 0,
                        contingency: contingency,
                        items: [],
                      );

                      projects.add(newProject);
                    }

                    await saveData();

                    if (!mounted) return;

                    setState(() {});

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          editing
                              ? 'Proyek berhasil diperbarui.'
                              : 'Proyek berhasil dibuat.',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    editing ? 'Simpan Perubahan' : 'Buat Proyek',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    locationController.dispose();
    lengthController.dispose();
    widthController.dispose();
  }

// ============================================================
// KONFIRMASI HAPUS PROYEK
// ============================================================

  Future<void> confirmDeleteProject(
    BuildProject project,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Proyek?'),
          content: Text(
            'Proyek "${project.name}" dan data RAB di dalamnya '
            'akan dihapus dari aplikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: bcRed,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      projects.removeWhere((item) => item.id == project.id);
    });

    await saveData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proyek berhasil dihapus.'),
      ),
    );
  }
 // ============================================================
// BAGIAN 3: DETAIL PROYEK, PREVIEW DESAIN, DAN PROGRES
// Tempel di dalam class _BuildCostHomeState
// ============================================================

Future<void> openProjectDetail(BuildProject project) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProjectDetailPage(
        project: project,
        onEdit: () async {
          if (!mounted) return;
          await openProjectForm(project: project);
        },
        onOpenRab: () async {
          if (!mounted) return;
          await openRab(project);
        },
        onProgressChanged: (value) async {
          project.progress = value;
          await saveData();
          if (mounted) setState(() {});
        },
      ),
    ),
  );

  if (mounted) setState(() {});
}

Future<void> openRab(BuildProject project) async {
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => RabPage(
        project: project,
        onSave: saveData,
      ),
    ),
  );
  if (mounted) setState(() {});
}



// ============================================================
// BAGIAN 5A: MANAJEMEN MATERIAL DAN AKUN
// Letakkan di dalam class _BuildCostHomeState
// ============================================================

String materialSearch = '';

Widget materialPage() {
  final query = materialSearch.trim().toLowerCase();

  final filteredMaterials = materials.where((material) {
    return material.name.toLowerCase().contains(query) ||
        material.unit.toLowerCase().contains(query);
  }).toList();

  return ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [bcNavy, bcBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DATABASE MATERIAL',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Harga Material Bangunan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${materials.length} material tersimpan',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Perbarui harga sesuai survei toko dan kondisi '
                      'daerah proyek. Harga di aplikasi merupakan '
                      'referensi yang dapat diubah.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        onChanged: (value) {
          setState(() => materialSearch = value);
        },
        decoration: InputDecoration(
          hintText: 'Cari material, misalnya semen...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: materialSearch.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    setState(() => materialSearch = '');
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Daftar Material',
              style: TextStyle(
                color: bcNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '${filteredMaterials.length} item',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (filteredMaterials.isEmpty)
        emptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Material tidak ditemukan',
          message: 'Tambahkan material baru atau ubah kata pencarian.',
          buttonText: 'Tambah Material',
          onPressed: () => openMaterialForm(),
        )
      else
        ...filteredMaterials.map(_materialCard),
    ],
  );
}

Widget _materialCard(BuildMaterial material) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE6EAF0)),
    ),
    child: Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: bcBlue.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: bcBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                material.name,
                style: const TextStyle(
                  color: bcNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Satuan: ${material.unit}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${rupiah(material.price)} / ${material.unit}',
                style: const TextStyle(
                  color: bcBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              openMaterialForm(material: material);
            } else if (value == 'delete') {
              _deleteMaterial(material);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: bcRed),
                  SizedBox(width: 8),
                  Text('Hapus'),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> openMaterialForm({BuildMaterial? material}) async {
  final nameController = TextEditingController(
    text: material?.name ?? '',
  );
  final unitController = TextEditingController(
    text: material?.unit ?? 'sak',
  );
  final priceController = TextEditingController(
    text: material == null ? '' : material.price.toString(),
  );

  final formKey = GlobalKey<FormState>();

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          material == null ? 'Tambah Material' : 'Edit Material',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama material',
                    hintText: 'Contoh: Semen Portland',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama material wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    hintText: 'sak, kg, m, m², m³, unit',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Satuan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Harga per satuan (Rp)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (parseNumber(value ?? '') < 0) {
                      return 'Harga tidak boleh negatif';
                    }
                    if ((value ?? '').trim().isEmpty) {
                      return 'Harga wajib diisi';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );

  if (result == true) {
    final newMaterial = BuildMaterial(
      name: nameController.text.trim(),
      unit: unitController.text.trim(),
      price: parseNumber(priceController.text),
    );

    setState(() {
      if (material == null) {
        materials.add(newMaterial);
      } else {
        final index = materials.indexOf(material);
        if (index >= 0) {
          materials[index] = newMaterial;
        }
      }
    });

    await saveData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            material == null
                ? 'Material berhasil ditambahkan.'
                : 'Material berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  nameController.dispose();
  unitController.dispose();
  priceController.dispose();
}

Future<void> _deleteMaterial(BuildMaterial material) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus material?'),
      content: Text(
        'Material "${material.name}" akan dihapus dari daftar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bcRed,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    setState(() => materials.remove(material));
    await saveData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material berhasil dihapus.'),
        ),
      );
    }
  }
}

// ============================================================
// HALAMAN AKUN DAN PENGATURAN
// ============================================================

Widget accountPage() {
  return ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [bcNavy, bcBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              username,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'BUILDCOST V3',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Ringkasan Data',
        style: TextStyle(
          color: bcNavy,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: summaryCard(
              title: 'Proyek',
              value: '${projects.length}',
              subtitle: 'Proyek tersimpan',
              icon: Icons.apartment_outlined,
              color: bcBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: summaryCard(
              title: 'Material',
              value: '${materials.length}',
              subtitle: 'Material tersimpan',
              icon: Icons.inventory_2_outlined,
              color: bcOrange,
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      const Text(
        'Pengaturan',
        style: TextStyle(
          color: bcNavy,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      _accountMenuTile(
        icon: Icons.person_outline,
        title: 'Ubah Nama Pengguna',
        subtitle: 'Atur nama yang tampil di aplikasi',
        onTap: _changeUsername,
      ),
      _accountMenuTile(
        icon: Icons.storage_outlined,
        title: 'Penyimpanan Lokal',
        subtitle: 'Data disimpan di perangkat ini',
        onTap: _showStorageInfo,
      ),
      _accountMenuTile(
        icon: Icons.info_outline,
        title: 'Tentang BUILDCOST',
        subtitle: 'Informasi versi dan fungsi aplikasi',
        onTap: _showAbout,
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE6EAF0)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.shield_outlined,
              color: bcGreen,
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Data proyek dan material pada versi ini disimpan secara '
                'lokal di perangkat. Data belum otomatis tersinkron '
                'ke akun online atau perangkat lain.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _accountMenuTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bcBlue.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: bcBlue),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: bcNavy,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.black45,
      ),
      onTap: onTap,
    ),
  );
}

Future<void> _changeUsername() async {
  final controller = TextEditingController(text: username);

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Nama Pengguna'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 40,
        decoration: const InputDecoration(
          labelText: 'Nama',
          hintText: 'Masukkan nama pengguna',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          Navigator.pop(dialogContext, value.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              dialogContext,
              controller.text.trim(),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );

  controller.dispose();

  if (result != null && result.trim().isNotEmpty) {
    setState(() => username = result.trim());

    await saveData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama pengguna berhasil disimpan.'),
        ),
      );
    }
  }
}

void _showStorageInfo() {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Penyimpanan Lokal'),
      content: const Text(
        'BUILDCOST menggunakan SharedPreferences untuk menyimpan '
        'data proyek, material, dan nama pengguna di perangkat ini. '
        'Data tidak otomatis tersedia di perangkat lain. '
        'Menghapus data aplikasi atau menghapus aplikasi dapat '
        'menghilangkan data lokal.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Mengerti'),
        ),
      ],
    ),
  );
}

void _showAbout() {
  showAboutDialog(
    context: context,
    applicationName: 'BUILDCOST',
    applicationVersion: '3.0',
    applicationLegalese: 'Construction Planning & Cost Platform',
    children: const [
      SizedBox(height: 12),
      Text(
        'Aplikasi perencanaan proyek, pengelolaan material, '
        'dan estimasi Rencana Anggaran Biaya.',
      ),
      SizedBox(height: 8),
      Text(
        'Hasil estimasi perlu diperiksa dan disesuaikan dengan '
        'spesifikasi teknis serta harga lapangan.',
      ),
    ],
  );
}

}

// ============================================================
// HALAMAN DETAIL PROYEK
// ============================================================

class ProjectDetailPage extends StatefulWidget {
  final BuildProject project;
  final Future<void> Function() onEdit;
  final Future<void> Function() onOpenRab;
  final Future<void> Function(double) onProgressChanged;

  const ProjectDetailPage({
    super.key,
    required this.project,
    required this.onEdit,
    required this.onOpenRab,
    required this.onProgressChanged,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late double progressValue;

  @override
  void initState() {
    super.initState();
    progressValue = widget.project.progress.clamp(0, 100).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Scaffold(
      backgroundColor: bcBackground,
      appBar: AppBar(
        title: const Text('Detail Proyek'),
        actions: [
          IconButton(
            tooltip: 'Edit proyek',
            onPressed: () async {
              await widget.onEdit();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _projectHero(project),
          const SizedBox(height: 18),
          _sectionTitle('Ringkasan Proyek'),
          const SizedBox(height: 10),
          _infoGrid(project),
          const SizedBox(height: 22),
          _sectionTitle('Konsep Desain'),
          const SizedBox(height: 10),
          DesignPreviewCard(project: project),
          const SizedBox(height: 22),
          _sectionTitle('Progres Pembangunan'),
          const SizedBox(height: 10),
          _progressCard(),
          const SizedBox(height: 22),
          _sectionTitle('Estimasi Anggaran'),
          const SizedBox(height: 10),
          _budgetCard(project),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => widget.onOpenRab(),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text(
                'BUKA RENCANA ANGGARAN BIAYA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: bcOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _projectHero(BuildProject project) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [bcNavy, bcBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              project.type.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            project.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: Colors.white70,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  project.location.isEmpty
                      ? 'Lokasi belum diisi'
                      : project.location,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'ESTIMASI TOTAL ANGGARAN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            rupiah(project.total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Estimasi awal — sesuaikan dengan harga dan kondisi lapangan.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: bcNavy,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _infoGrid(BuildProject project) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _infoTile(
          Icons.square_foot,
          'Luas perkiraan',
          '${project.area.toStringAsFixed(1)} m²',
        ),
        _infoTile(
          Icons.layers_outlined,
          'Jumlah lantai',
          '${project.floors} lantai',
        ),
        _infoTile(
          Icons.architecture_outlined,
          'Panjang',
          '${project.length} m',
        ),
        _infoTile(
          Icons.straighten_outlined,
          'Lebar',
          '${project.width} m',
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bcBlue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: bcBlue, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: bcNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres saat ini',
                style: TextStyle(
                  color: bcNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${progressValue.round()}%',
                style: const TextStyle(
                  color: bcBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progressValue / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8EDF5),
              valueColor: const AlwaysStoppedAnimation<Color>(bcGreen),
            ),
          ),
          const SizedBox(height: 10),
          Slider(
            value: progressValue,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: bcBlue,
            label: '${progressValue.round()}%',
            onChanged: (value) {
              setState(() => progressValue = value);
            },
            onChangeEnd: (value) async {
              await widget.onProgressChanged(value);
            },
          ),
          const SizedBox(height: 4),
          const Text(
            'Geser indikator sesuai kondisi pembangunan di lapangan.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await widget.onProgressChanged(progressValue);
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progres proyek berhasil disimpan.'),
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan Progres'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard(BuildProject project) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        children: [
          _budgetRow('Subtotal pekerjaan', rupiah(project.subtotal)),
          const SizedBox(height: 10),
          _budgetRow(
            'Cadangan (${project.contingency.toStringAsFixed(0)}%)',
            rupiah(project.reserve),
          ),
          const Divider(height: 25),
          _budgetRow(
            'Total estimasi',
            rupiah(project.total),
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _budgetRow(
    String title,
    String value, {
    bool emphasized = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: emphasized ? bcNavy : Colors.black54,
              fontSize: emphasized ? 14 : 12,
              fontWeight:
                  emphasized ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            color: emphasized ? bcBlue : bcNavy,
            fontSize: emphasized ? 16 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// KARTU PRATINJAU KONSEP DESAIN
// ============================================================

class DesignPreviewCard extends StatelessWidget {
  final BuildProject project;

  const DesignPreviewCard({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: CustomPaint(
                painter: BuildingPreviewPainter(
                  type: project.type,
                  design: project.design,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.design,
                  style: const TextStyle(
                    color: bcNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${project.type} • ${project.floors} lantai • '
                  '${project.area.toStringAsFixed(1)} m²',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: bcOrange,
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Ini pratinjau konseptual sederhana, bukan gambar '
                        'kerja arsitektur atau struktur yang siap dibangun.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ILUSTRASI BANGUNAN SEDERHANA DENGAN CUSTOM PAINTER
// ============================================================

class BuildingPreviewPainter extends CustomPainter {
  final String type;
  final String design;

  BuildingPreviewPainter({
    required this.type,
    required this.design,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFFEAF1FA);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    final skyPaint = Paint()..color = const Color(0xFFDCEBFA);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.67),
      skyPaint,
    );

    final groundPaint = Paint()..color = const Color(0xFFD6E3D5);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * 0.76,
        size.width,
        size.height * 0.24,
      ),
      groundPaint,
    );

    final sunPaint = Paint()..color = const Color(0xFFFFD27A);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.19),
      size.width * 0.065,
      sunPaint,
    );

    final isRoad = type.toLowerCase().contains('jalan');
    final isBridge = type.toLowerCase().contains('jembatan');
    final isAirport = type.toLowerCase().contains('bandara');
    final isTall = type.toLowerCase().contains('gedung') ||
        type.toLowerCase().contains('hotel');

    if (isRoad) {
      _drawRoad(canvas, size);
    } else if (isBridge) {
      _drawBridge(canvas, size);
    } else if (isAirport) {
      _drawAirport(canvas, size);
    } else {
      _drawBuilding(canvas, size, tall: isTall);
    }

    final borderPaint = Paint()
      ..color = bcNavy.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );
  }

  void _drawBuilding(Canvas canvas, Size size, {required bool tall}) {
    final centerX = size.width * 0.5;
    final baseY = size.height * 0.80;
    final floors = tall ? 4 : 2;
    final buildingWidth = size.width * (tall ? 0.42 : 0.56);
    final floorHeight = size.height * (tall ? 0.115 : 0.16);
    final buildingHeight = floorHeight * floors;
    final left = centerX - buildingWidth / 2;
    final top = baseY - buildingHeight;

    final wallColor = design.toLowerCase().contains('klasik')
        ? const Color(0xFFE9D7B8)
        : const Color(0xFFF5F7FA);

    final wallPaint = Paint()..color = wallColor;
    canvas.drawRect(
      Rect.fromLTWH(left, top, buildingWidth, buildingHeight),
      wallPaint,
    );

    final shadowPaint = Paint()..color = const Color(0xFFD1D9E3);
    canvas.drawRect(
      Rect.fromLTWH(left + buildingWidth * 0.78, top, buildingWidth * 0.22,
          buildingHeight),
      shadowPaint,
    );

    final roofPaint = Paint()..color = bcNavy;
    final isClassic = design.toLowerCase().contains('klasik');
    if (isClassic) {
      final roofPath = Path()
        ..moveTo(left - 5, top + 4)
        ..lineTo(centerX, top - size.height * 0.09)
        ..lineTo(left + buildingWidth + 5, top + 4)
        ..close();
      canvas.drawPath(roofPath, roofPaint);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(left - 3, top - 5, buildingWidth + 6, 7),
        roofPaint,
      );
    }

    final windowPaint = Paint()..color = const Color(0xFF78B9E8);
    final windowWidth = buildingWidth * 0.19;
    final windowHeight = floorHeight * 0.36;

    for (int floor = 0; floor < floors; floor++) {
      final y = top + floor * floorHeight + floorHeight * 0.25;

      for (int col = 0; col < 3; col++) {
        final x = left + buildingWidth * 0.12 +
            col * (buildingWidth * 0.29);

        canvas.drawRect(
          Rect.fromLTWH(x, y, windowWidth, windowHeight),
          windowPaint,
        );
      }
    }

    final doorPaint = Paint()..color = bcOrange;
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - buildingWidth * 0.10,
        baseY - floorHeight * 0.65,
        buildingWidth * 0.20,
        floorHeight * 0.65,
      ),
      doorPaint,
    );

    final foundationPaint = Paint()..color = const Color(0xFF8B99AA);
    canvas.drawRect(
      Rect.fromLTWH(left - 9, baseY, buildingWidth + 18, 5),
      foundationPaint,
    );

    if (design.toLowerCase().contains('tropis')) {
      final plantPaint = Paint()..color = const Color(0xFF4D8A58);
      canvas.drawCircle(
        Offset(left - 15, baseY - 12),
        12,
        plantPaint,
      );
      canvas.drawCircle(
        Offset(left + buildingWidth + 15, baseY - 12),
        12,
        plantPaint,
      );
    }
  }

  void _drawRoad(Canvas canvas, Size size) {
    final roadPaint = Paint()..color = const Color(0xFF667384);
    final roadRect = Rect.fromLTWH(
      0,
      size.height * 0.45,
      size.width,
      size.height * 0.35,
    );
    canvas.drawRect(roadRect, roadPaint);

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    const dashCount = 7;
    for (int i = 0; i < dashCount; i++) {
      final x = size.width * (i + 0.5) / dashCount;
      canvas.drawLine(
        Offset(x, size.height * 0.625),
        Offset(x + size.width * 0.045, size.height * 0.625),
        linePaint,
      );
    }
  }

  void _drawBridge(Canvas canvas, Size size) {
    final waterPaint = Paint()..color = const Color(0xFF91CDE8);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * 0.58,
        size.width,
        size.height * 0.24,
      ),
      waterPaint,
    );

    final deckPaint = Paint()..color = const Color(0xFF77879A);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.44,
        size.width * 0.84,
        size.height * 0.09,
      ),
      deckPaint,
    );

    final supportPaint = Paint()
      ..color = bcNavy
      ..strokeWidth = 5;

    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.49),
      Offset(size.width * 0.30, size.height * 0.78),
      supportPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.70, size.height * 0.49),
      Offset(size.width * 0.70, size.height * 0.78),
      supportPaint,
    );

    final railPaint = Paint()
      ..color = bcOrange
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(size.width * 0.10, size.height * 0.40),
      Offset(size.width * 0.90, size.height * 0.40),
      railPaint,
    );
  }

  void _drawAirport(Canvas canvas, Size size) {
    final terminalPaint = Paint()..color = const Color(0xFFF5F7FA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.43,
          size.width * 0.68,
          size.height * 0.31,
        ),
        const Radius.circular(8),
      ),
      terminalPaint,
    );

    final glassPaint = Paint()..color = const Color(0xFF78B9E8);
    for (int i = 0; i < 6; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * (0.21 + i * 0.095),
          size.height * 0.51,
          size.width * 0.065,
          size.height * 0.13,
        ),
        glassPaint,
      );
    }

    final roofPaint = Paint()..color = bcNavy;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.13,
        size.height * 0.40,
        size.width * 0.74,
        size.height * 0.045,
      ),
      roofPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BuildingPreviewPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.design != design;
  }
}
 // ============================================================
// BAGIAN 4: RAB, CRUD ITEM, EKSPOR PDF DAN EXCEL
// ============================================================

class RabPage extends StatefulWidget {
  final BuildProject project;
  final Future<void> Function() onSave;

  const RabPage({
    super.key,
    required this.project,
    required this.onSave,
  });

  @override
  State<RabPage> createState() => _RabPageState();
}

class _RabPageState extends State<RabPage> {
  bool exporting = false;

  BuildProject get project => widget.project;

  @override
  void initState() {
    super.initState();

    // Membuat contoh RAB pertama kali jika belum ada.
    if (project.items.isEmpty) {
      project.items.addAll(_defaultRabItems(project));
    }
  }

  List<RabItem> _defaultRabItems(BuildProject p) {
    final type = p.type.toLowerCase();
    final area = p.area;

    // Harga berikut adalah angka ilustratif awal.
    // Pengguna perlu menyesuaikannya dengan harga setempat.
    if (type.contains('jalan')) {
      return [
        RabItem(
          name: 'Persiapan dan pembersihan lahan',
          unit: 'm²',
          volume: area,
          price: 15000,
        ),
        RabItem(
          name: 'Pekerjaan tanah dan pemadatan',
          unit: 'm²',
          volume: area,
          price: 45000,
        ),
        RabItem(
          name: 'Lapis pondasi jalan',
          unit: 'm²',
          volume: area,
          price: 85000,
        ),
        RabItem(
          name: 'Perkerasan jalan',
          unit: 'm²',
          volume: area,
          price: 150000,
        ),
      ];
    }

    if (type.contains('jembatan')) {
      return [
        RabItem(
          name: 'Pekerjaan persiapan',
          unit: 'ls',
          volume: 1,
          price: 5000000,
        ),
        RabItem(
          name: 'Pekerjaan tanah dan pondasi',
          unit: 'ls',
          volume: 1,
          price: 25000000,
        ),
        RabItem(
          name: 'Struktur bawah jembatan',
          unit: 'ls',
          volume: 1,
          price: 35000000,
        ),
        RabItem(
          name: 'Struktur atas jembatan',
          unit: 'ls',
          volume: 1,
          price: 45000000,
        ),
      ];
    }

    if (type.contains('bandara')) {
      return [
        RabItem(
          name: 'Pekerjaan persiapan',
          unit: 'ls',
          volume: 1,
          price: 25000000,
        ),
        RabItem(
          name: 'Pekerjaan tanah',
          unit: 'm²',
          volume: area,
          price: 75000,
        ),
        RabItem(
          name: 'Pekerjaan struktur',
          unit: 'm²',
          volume: area,
          price: 2500000,
        ),
        RabItem(
          name: 'Pekerjaan finishing',
          unit: 'm²',
          volume: area,
          price: 1000000,
        ),
      ];
    }

    if (type.contains('gedung') ||
        type.contains('hotel')) {
      return [
        RabItem(
          name: 'Pekerjaan persiapan',
          unit: 'm²',
          volume: area,
          price: 50000,
        ),
        RabItem(
          name: 'Pekerjaan pondasi dan struktur',
          unit: 'm²',
          volume: area,
          price: 1100000,
        ),
        RabItem(
          name: 'Pekerjaan dinding dan plester',
          unit: 'm²',
          volume: area * 2.5,
          price: 150000,
        ),
        RabItem(
          name: 'Pekerjaan atap',
          unit: 'm²',
          volume: p.length * p.width,
          price: 250000,
        ),
        RabItem(
          name: 'Pekerjaan finishing',
          unit: 'm²',
          volume: area,
          price: 450000,
        ),
      ];
    }

    // Contoh awal untuk rumah, ruko, gudang, dan jenis lain.
    return [
      RabItem(
        name: 'Pekerjaan persiapan',
        unit: 'm²',
        volume: area,
        price: 25000,
      ),
      RabItem(
        name: 'Pekerjaan pondasi',
        unit: 'm²',
        volume: area,
        price: 250000,
      ),
      RabItem(
        name: 'Pekerjaan struktur beton',
        unit: 'm²',
        volume: area,
        price: 450000,
      ),
      RabItem(
        name: 'Pekerjaan dinding dan plester',
        unit: 'm²',
        volume: area * 2.5,
        price: 125000,
      ),
      RabItem(
        name: 'Pekerjaan atap',
        unit: 'm²',
        volume: p.length * p.width,
        price: 250000,
      ),
      RabItem(
        name: 'Pekerjaan lantai',
        unit: 'm²',
        volume: area,
        price: 150000,
      ),
      RabItem(
        name: 'Pekerjaan finishing',
        unit: 'm²',
        volume: area,
        price: 200000,
      ),
    ];
  }

  Future<void> _save() async {
    await widget.onSave();
    if (mounted) setState(() {});
  }

  Future<void> _openItemForm({RabItem? item}) async {
    final nameController = TextEditingController(
      text: item?.name ?? '',
    );
    final unitController = TextEditingController(
      text: item?.unit ?? 'm²',
    );
    final volumeController = TextEditingController(
      text: item == null ? '1' : item.volume.toString(),
    );
    final priceController = TextEditingController(
      text: item == null ? '0' : item.price.toString(),
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            item == null ? 'Tambah Item RAB' : 'Edit Item RAB',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama pekerjaan',
                      hintText: 'Contoh: Pekerjaan pondasi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama pekerjaan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Satuan',
                      hintText: 'm², m³, m, kg, unit, ls',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Satuan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: volumeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Volume',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (parseNumber(value ?? '') < 0) {
                        return 'Volume tidak boleh negatif';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Harga satuan (Rp)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (parseNumber(value ?? '') < 0) {
                        return 'Harga tidak boleh negatif';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newItem = RabItem(
        name: nameController.text.trim(),
        unit: unitController.text.trim(),
        volume: parseNumber(volumeController.text),
        price: parseNumber(priceController.text),
      );

      setState(() {
        if (item == null) {
          project.items.add(newItem);
        } else {
          final index = project.items.indexOf(item);
          if (index >= 0) {
            project.items[index] = newItem;
          }
        }
      });

      await _save();
    }

    nameController.dispose();
    unitController.dispose();
    volumeController.dispose();
    priceController.dispose();
  }

  Future<void> _deleteItem(RabItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus item?'),
        content: Text(
          'Item "${item.name}" akan dihapus dari RAB.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bcRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        project.items.remove(item);
      });
      await _save();
    }
  }

  Future<void> _exportPdf() async {
    if (exporting) return;

    setState(() => exporting = true);

    try {
      final document = pw.Document();

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pdfContext) => [
            pw.Text(
              'BUILDCOST',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Laporan Rencana Anggaran Biaya',
              style: const pw.TextStyle(fontSize: 13),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Proyek: ${project.name}'),
            pw.Text('Jenis: ${project.type}'),
            pw.Text('Lokasi: ${project.location.isEmpty ? "-" : project.location}'),
            pw.Text(
              'Dimensi: ${project.length} m × ${project.width} m '
              '• ${project.floors} lantai',
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: [
                'No',
                'Uraian pekerjaan',
                'Volume',
                'Satuan',
                'Harga satuan',
                'Jumlah',
              ],
              data: [
                for (int i = 0; i < project.items.length; i++)
                  [
                    '${i + 1}',
                    project.items[i].name,
                    project.items[i].volume.toStringAsFixed(2),
                    project.items[i].unit,
                    rupiah(project.items[i].price),
                    rupiah(project.items[i].total),
                  ],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 250,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _pdfTotalRow('Subtotal', rupiah(project.subtotal)),
                    _pdfTotalRow(
                      'Cadangan (${project.contingency.toStringAsFixed(0)}%)',
                      rupiah(project.reserve),
                    ),
                    pw.Divider(),
                    _pdfTotalRow(
                      'TOTAL ANGGARAN',
                      rupiah(project.total),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 22),
            pw.Text(
              'Catatan: Angka dalam laporan ini merupakan estimasi. '
              'Validasi volume, harga material, upah, pajak, dan kondisi '
              'lapangan sebelum digunakan sebagai dokumen anggaran final.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );

      final bytes = await document.save();
      final directory = await getTemporaryDirectory();
      final safeName = project.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File(
        '${directory.path}/RAB_$safeName.pdf',
      );

      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'RAB proyek ${project.name}',
      );
    } catch (error) {
      _showMessage('Gagal membuat PDF: $error');
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  pw.Widget _pdfTotalRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel() async {
    if (exporting) return;

    setState(() => exporting = true);

    try {
      final workbook = xl.Excel.createExcel();
      final sheet = workbook['RAB'];

      sheet.appendRow([
        xl.TextCellValue('BUILDCOST - RENCANA ANGGARAN BIAYA'),
      ]);
      sheet.appendRow([
        xl.TextCellValue('Nama Proyek'),
        xl.TextCellValue(project.name),
      ]);
      sheet.appendRow([
        xl.TextCellValue('Jenis Proyek'),
        xl.TextCellValue(project.type),
      ]);
      sheet.appendRow([
        xl.TextCellValue('Lokasi'),
        xl.TextCellValue(project.location),
      ]);
      sheet.appendRow([
        xl.TextCellValue('Dimensi'),
        xl.TextCellValue(
          '${project.length} x ${project.width} m',
        ),
      ]);
      sheet.appendRow([]);

      sheet.appendRow([
        xl.TextCellValue('No'),
        xl.TextCellValue('Uraian Pekerjaan'),
        xl.TextCellValue('Volume'),
        xl.TextCellValue('Satuan'),
        xl.TextCellValue('Harga Satuan'),
        xl.TextCellValue('Jumlah'),
      ]);

      for (int i = 0; i < project.items.length; i++) {
        final item = project.items[i];

        sheet.appendRow([
          xl.IntCellValue(i + 1),
          xl.TextCellValue(item.name),
          xl.DoubleCellValue(item.volume),
          xl.TextCellValue(item.unit),
          xl.DoubleCellValue(item.price),
          xl.DoubleCellValue(item.total),
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow([
        xl.TextCellValue('Subtotal'),
        xl.DoubleCellValue(project.subtotal),
      ]);
      sheet.appendRow([
        xl.TextCellValue(
          'Cadangan (${project.contingency.toStringAsFixed(0)}%)',
        ),
        xl.DoubleCellValue(project.reserve),
      ]);
      sheet.appendRow([
        xl.TextCellValue('TOTAL ANGGARAN'),
        xl.DoubleCellValue(project.total),
      ]);

      final bytes = workbook.encode();

      if (bytes == null) {
        throw Exception('Data Excel gagal dibuat.');
      }

      final directory = await getTemporaryDirectory();
      final safeName = project.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File(
        '${directory.path}/RAB_$safeName.xlsx',
      );

      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'RAB Excel proyek ${project.name}',
      );
    } catch (error) {
      _showMessage('Gagal membuat Excel: $error');
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bcBackground,
      appBar: AppBar(
        title: const Text('RAB Proyek'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Ekspor laporan',
            onSelected: (value) {
              if (value == 'pdf') {
                _exportPdf();
              } else if (value == 'excel') {
                _exportExcel();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined),
                    SizedBox(width: 10),
                    Text('Ekspor PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined),
                    SizedBox(width: 10),
                    Text('Ekspor Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openItemForm(),
        backgroundColor: bcOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Item'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _projectSummary(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daftar Pekerjaan',
                  style: TextStyle(
                    color: bcNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${project.items.length} item',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (project.items.isEmpty)
            _emptyRab()
          else
            ...project.items.asMap().entries.map(
              (entry) => _rabItemCard(
                entry.key + 1,
                entry.value,
              ),
            ),
          const SizedBox(height: 18),
          _totalCard(),
          const SizedBox(height: 16),
          _exportButtons(),
          const SizedBox(height: 12),
          const Text(
            'Harga awal merupakan ilustrasi, bukan harga resmi. '
            'Periksa volume, satuan, harga bahan, upah, pajak, dan '
            'spesifikasi teknis sebelum memakai RAB untuk pelaksanaan.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [bcNavy, bcBlue],
        ),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROYEK',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            project.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${project.type} • ${project.area.toStringAsFixed(1)} m²',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'TOTAL ESTIMASI',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rupiah(project.total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rabItemCard(int number, RabItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bcBlue.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: bcBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: bcNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') {
                    _openItemForm(item: item);
                  } else if (value == 'delete') {
                    _deleteItem(item);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${item.volume.toStringAsFixed(2)} ${item.unit} × '
            '${rupiah(item.price)}',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jumlah',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              Flexible(
                child: Text(
                  rupiah(item.total),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: bcBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyRab() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: bcBlue,
            size: 45,
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada item RAB',
            style: TextStyle(
              color: bcNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Tekan tombol Tambah Item untuk mulai membuat anggaran.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        children: [
          _totalRow('Subtotal pekerjaan', rupiah(project.subtotal)),
          const SizedBox(height: 12),
          _totalRow(
            'Cadangan ${project.contingency.toStringAsFixed(0)}%',
            rupiah(project.reserve),
          ),
          const Divider(height: 28),
          _totalRow(
            'TOTAL ANGGARAN',
            rupiah(project.total),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? bcNavy : Colors.black54,
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: bold ? bcBlue : bcNavy,
              fontSize: bold ? 18 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _exportButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: exporting ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: exporting ? null : _exportExcel,
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Excel'),
          ),
        ),
      ],
    );
  }
}
