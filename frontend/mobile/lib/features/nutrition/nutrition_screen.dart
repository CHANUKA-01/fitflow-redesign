import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/catalogue.dart';
import '../../data/models.dart';

/// Camera-first nutrition (R08) with a review step showing per-item
/// confidence and editable portions (R09, U08). Photos are analysed on the
/// device and deleted afterwards (ADR-003, NFR5).
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context);
    final today = s.mealsOn(DateTime.now());
    final kcal = today.fold<double>(0, (a, m) => a + m.kcal);
    double sum(double Function(FoodItem) f) => today.fold(0, (a, m) => a + m.items.fold(0, (b, i) => b + f(i)));

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: ListView(padding: pagePadding(context, 0, 24), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Today', style: t.textTheme.labelLarge),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${kcal.round()}',
                    style: t.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: FF.teal)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 6),
                  child: Text('/ ${s.kcalTarget} kcal', style: t.textTheme.titleMedium),
                ),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (kcal / s.kcalTarget).clamp(0, 1).toDouble(),
                  minHeight: 10,
                  color: FF.teal,
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _Macro('Protein', sum((i) => i.protein)),
                _Macro('Carbs', sum((i) => i.carbs)),
                _Macro('Fat', sum((i) => i.fat)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: FF.teal,
          borderRadius: BorderRadius.circular(FF.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(FF.radius),
            onTap: () => startMealCapture(context),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.photo_camera, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Snap your meal',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Analysed on your phone. You check it before saving.',
                        style: TextStyle(color: Colors.white70)),
                  ]),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_note),
          label: const Text('Add food manually'),
          onPressed: () => showManualEntry(context),
        ),
        for (final slot in MealSlot.values) ...[
          SectionTitle(slot.label,
              trailing: Text(
                '${today.where((m) => m.slot == slot).fold<double>(0, (a, m) => a + m.kcal).round()} kcal',
                style: t.textTheme.labelLarge,
              )),
          ..._mealsFor(context, today.where((m) => m.slot == slot).toList()),
        ],
      ]),
    );
  }

  List<Widget> _mealsFor(BuildContext context, List<Meal> meals) {
    if (meals.isEmpty) {
      return [
        Card(
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.restaurant_outlined),
            title: Text('Nothing logged', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ];
    }
    return [
      for (final m in meals)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              leading: Icon(m.fromPhoto ? Icons.photo_camera_outlined : Icons.edit_note, color: FF.teal),
              title: Text(m.items.map((i) => i.food.name).join(', '), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${m.kcal.round()} kcal · ${timeAgo(m.date)}'),
              trailing: IconButton(
                tooltip: 'Remove meal',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => AppScope.read(context).removeMeal(m),
              ),
            ),
          ),
        ),
    ];
  }
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.grams);

  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${grams.round()} g', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

MealSlot _slotNow() {
  final h = DateTime.now().hour;
  if (h < 11) return MealSlot.breakfast;
  if (h < 15) return MealSlot.lunch;
  if (h < 18) return MealSlot.snack;
  return MealSlot.dinner;
}

/// Camera → on-device analysis → review. Falls back to the gallery when no
/// camera is available (e.g. some emulators).
Future<void> startMealCapture(BuildContext context) async {
  final picker = ImagePicker();
  final nav = Navigator.of(context);
  XFile? photo;
  try {
    photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 80);
  } catch (_) {
    photo = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
  }
  if (photo == null) return;
  final bytes = await photo.length();
  // Stand-in for the TFLite model (ADR-003): choose a plate deterministically
  // from the image so the same photo always gives the same result.
  final plate = recognisedPlates[bytes % recognisedPlates.length];
  final items = [
    for (final (name, conf) in plate)
      () {
        final f = foodByName(name);
        return FoodItem(food: f, grams: f.typicalGrams, confidence: conf);
      }(),
  ];
  await nav.push(MaterialPageRoute(builder: (_) => MealReviewScreen(photo: File(photo!.path), items: items)));
}

Future<void> showManualEntry(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MealReviewScreen(items: [])),
    );

class MealReviewScreen extends StatefulWidget {
  const MealReviewScreen({super.key, required this.items, this.photo, this.image});

  /// Captured photo; deleted when the screen closes.
  final File? photo;

  /// Overrides how the photo is displayed (used by the store-screenshot test).
  final ImageProvider? image;
  final List<FoodItem> items;

  @override
  State<MealReviewScreen> createState() => _MealReviewScreenState();
}

class _MealReviewScreenState extends State<MealReviewScreen> {
  late final List<FoodItem> _items = [...widget.items];
  MealSlot _slot = _slotNow();
  bool _analysing = true;

  @override
  void initState() {
    super.initState();
    if (widget.photo == null && widget.image == null) {
      _analysing = false;
    } else {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _analysing = false);
      });
    }
  }

  @override
  void dispose() {
    // The photo is never kept: delete it whether the meal was saved or not.
    widget.photo?.delete().ignore();
    super.dispose();
  }

  double get _kcal => _items.fold(0, (a, i) => a + i.kcal);

  Future<void> _addFood() async {
    final food = await showModalBottomSheet<Food>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FoodPicker(),
    );
    if (food != null) setState(() => _items.add(FoodItem(food: food, grams: food.typicalGrams)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final fromPhoto = widget.photo != null || widget.image != null;
    return Scaffold(
      appBar: AppBar(title: Text(fromPhoto ? 'Check your meal' : 'Add food')),
      body: _analysing
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Analysing on this device…', style: t.textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text('Your photo is not uploaded.'),
              ]),
            )
          : ListView(padding: pagePadding(context, 0, 24), children: [
              if (fromPhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(FF.radius),
                  child: Image(
                    image: widget.image ?? FileImage(widget.photo!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                const AiNotice(
                  'Food recognition ran on your phone. The photo will be deleted when you leave this screen. '
                  'Check each item — estimates marked "Please check" are less certain.',
                ),
              ],
              const SizedBox(height: 12),
              SegmentedButton<MealSlot>(
                showSelectedIcon: false,
                segments: [for (final m in MealSlot.values) ButtonSegment(value: m, label: Text(m.label))],
                selected: {_slot},
                onSelectionChanged: (v) => setState(() => _slot = v.first),
              ),
              const SizedBox(height: 12),
              for (final item in _items) _ItemCard(
                item: item,
                onChanged: () => setState(() {}),
                onRemove: () => setState(() => _items.remove(item)),
              ),
              OutlinedButton.icon(onPressed: _addFood, icon: const Icon(Icons.add), label: const Text('Add an item')),
              const SizedBox(height: 16),
              Text('Total ${_kcal.round()} kcal',
                  style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _items.isEmpty
                    ? null
                    : () {
                        AppScope.read(context).addMeal(_slot, _items, fromPhoto: fromPhoto);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${_slot.label} saved · ${_kcal.round()} kcal')),
                        );
                      },
                child: const Text('Save meal'),
              ),
            ]),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onChanged, required this.onRemove});

  final FoodItem item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = item.confidence;
    final (label, color) = switch (c) {
      null => ('Added by you', FF.indigo),
      >= 0.8 => ('High confidence ${(c * 100).round()}%', FF.teal),
      >= 0.6 => ('Medium confidence ${(c * 100).round()}%', FF.amber),
      _ => ('Please check · ${(c * 100).round()}%', FF.coral),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FF.radius),
          side: BorderSide(color: c != null && c < 0.6 ? FF.coral : Colors.transparent, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(item.food.name, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              IconButton(tooltip: 'Remove ${item.food.name}', onPressed: onRemove, icon: const Icon(Icons.close)),
            ]),
            Pill(label, color: color, icon: c == null ? Icons.edit : Icons.auto_awesome),
            const SizedBox(height: 8),
            Row(children: [
              IconButton.filledTonal(
                tooltip: 'Smaller portion',
                onPressed: () {
                  if (item.grams > 10) item.grams -= 10;
                  onChanged();
                },
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 72,
                child: Text('${item.grams} g',
                    textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              IconButton.filledTonal(
                tooltip: 'Larger portion',
                onPressed: () {
                  item.grams += 10;
                  onChanged();
                },
                icon: const Icon(Icons.add),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('${item.kcal.round()} kcal', style: t.textTheme.titleSmall),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _FoodPicker extends StatefulWidget {
  const _FoodPicker();

  @override
  State<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends State<_FoodPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final results = foods.where((f) => f.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Search foods', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(
          child: ListView(children: [
            for (final f in results)
              ListTile(
                title: Text(f.name),
                subtitle: Text('${f.kcalPer100.round()} kcal per 100 g · usual portion ${f.typicalGrams} g'),
                onTap: () => Navigator.pop(context, f),
              ),
          ]),
        ),
      ]),
    );
  }
}
