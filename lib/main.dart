import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Color primaryColor = Colors.indigo;
  final Color accentColor = Colors.amber;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gezilecek Yerler',
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo)
            .copyWith(secondary: accentColor),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> places = [];
  String filterStatus = '';

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  // Veritabanından yerleri filtreye göre yükler.
  Future<void> _loadPlaces() async {
    final data = await dbHelper.getPlaces(
        filter: filterStatus.isEmpty ? null : filterStatus);
    setState(() {
      places = data;
    });
  }

  // Filtre seçildiğinde listeyi günceller.
  void _onFilterChanged(String? value) {
    setState(() {
      filterStatus = value ?? '';
    });
    _loadPlaces();
  }

  // Yeni yer ekleme ekranına yönlendirir.
  Future<void> _navigateToAddPlace() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlaceFormPage()),
    );
    _loadPlaces();
  }

  // Detay ekranına yönlendirir.
  Future<void> _navigateToDetail(Map<String, dynamic> place) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlaceDetailPage(place: place)),
    );
    _loadPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gezilecek Yerler"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: filterStatus.isEmpty ? null : filterStatus,
              underline: const SizedBox(),
              hint: const Text("Tümü", style: TextStyle(color: Colors.white)),
              dropdownColor: Colors.indigo,
              iconEnabledColor: Colors.white,
              onChanged: _onFilterChanged,
              items: <String>['gezdim', 'gezmek istiyorum']
                  .map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status, style: const TextStyle(color: Colors.white)),
                );
              }).toList()
                ..insert(
                  0,
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text("Tümü", style: TextStyle(color: Colors.white)),
                  ),
                ),
            ),
          )
        ],
      ),
      body: places.isEmpty
          ? const Center(
              child: Text("Henüz yer eklenmemiş.", style: TextStyle(fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: place['image_path'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(place['image_path']),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.place, size: 40, color: Colors.indigo),
                    title: Text(
                      place['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        place['visit_status'],
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToDetail(place),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPlace,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PlaceFormPage extends StatefulWidget {
  final Map<String, dynamic>? place; // Düzenleme için mevcut yer bilgisi

  const PlaceFormPage({Key? key, this.place}) : super(key: key);

  @override
  _PlaceFormPageState createState() => _PlaceFormPageState();
}

class _PlaceFormPageState extends State<PlaceFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _plannedDateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _visitStatus = 'gezmek istiyorum';
  String? _imagePath;

  final DatabaseHelper dbHelper = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.place != null) {
      _nameController.text = widget.place!['name'] ?? '';
      _descController.text = widget.place!['description'] ?? '';
      _plannedDateController.text = widget.place!['planned_date'] ?? '';
      _commentController.text = widget.place!['comment'] ?? '';
      _visitStatus = widget.place!['visit_status'] ?? 'gezmek istiyorum';
      _imagePath = widget.place!['image_path'];
    }
  }

  // Fotoğraf seçimi (galeri)
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  // Yer kaydetme (ekleme veya güncelleme)
  Future<void> _savePlace() async {
    Map<String, dynamic> newPlace = {
      'user_id': 1, // Örnek kullanıcı ID'si; gerçek uygulamada kullanıcı oturumu entegre edilebilir.
      'name': _nameController.text,
      'description': _descController.text,
      'visit_status': _visitStatus,
      'planned_date': _plannedDateController.text,
      'comment': _commentController.text,
      'image_path': _imagePath,
    };

    if (widget.place == null) {
      await dbHelper.insertPlace(newPlace);
    } else {
      await dbHelper.updatePlace(newPlace, widget.place!['id']);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place == null ? "Yeni Yer Ekle" : "Yeri Düzenle"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Fotoğraf seçme alanı
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                    image: _imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imagePath == null
                      ? Center(
                          child: Icon(Icons.camera_alt,
                              size: 50, color: Colors.grey[700]),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Yer Adı'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _visitStatus,
                items: const [
                  DropdownMenuItem(
                    child: Text("Gezmek istiyorum"),
                    value: "gezmek istiyorum",
                  ),
                  DropdownMenuItem(
                    child: Text("Gezdim"),
                    value: "gezdim",
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _visitStatus = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Ziyaret Durumu'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _plannedDateController,
                decoration: const InputDecoration(
                    labelText: 'Planlanan Tarih (Örn. Kasım)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: 'Yorum'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
ElevatedButton(
  onPressed: _savePlace,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blueGrey[900],
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: const Text(
    "Kaydet",
    style: TextStyle(
      fontSize: 18,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
),

              
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceDetailPage extends StatelessWidget {
  final Map<String, dynamic> place;
  final DatabaseHelper dbHelper = DatabaseHelper();

  PlaceDetailPage({Key? key, required this.place}) : super(key: key);

  Future<void> _deletePlace(BuildContext context) async {
    await dbHelper.deletePlace(place['id']);
    Navigator.pop(context);
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlaceFormPage(place: place)),
    );
    Navigator.pop(context); // Güncelleme sonrası ana sayfaya dönüş
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(place['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Silme onayı
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Emin misiniz?"),
                  content: const Text("Bu yeri silmek istediğinize emin misiniz?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("İptal"),
                    ),
                    TextButton(
                      onPressed: () {
                        _deletePlace(context);
                      },
                      child: const Text("Sil", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (place['image_path'] != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(place['image_path']),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  place['name'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text("Açıklama: ${place['description'] ?? '-'}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Ziyaret Durumu: ${place['visit_status']}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Planlanan Tarih: ${place['planned_date'] ?? '-'}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Yorum: ${place['comment'] ?? '-'}",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
