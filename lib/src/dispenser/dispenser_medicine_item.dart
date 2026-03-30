import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart'; // Client access এর জন্য

class Medicine {
  int? itemId;
  String name;
  int stock;
  String dose;
  int prescribedQty;
  int dispenseQty;
  bool isAlternative;
  int? originalItemId;

  Medicine({
    required this.itemId,
    required this.name,
    required this.stock,
    required this.dose,
    required this.prescribedQty,
    required this.dispenseQty,
    this.isAlternative = false,
    this.originalItemId,
  });
}

class MedicineItem extends StatefulWidget {
  final Medicine medicine;
  final Client client; // Serverpod client pass করতে হবে
  final void Function(Medicine) onChanged;

  const MedicineItem({
    super.key,
    required this.medicine,
    required this.client,
    required this.onChanged,
  });

  @override
  State<MedicineItem> createState() => _MedicineItemState();
}

class _MedicineItemState extends State<MedicineItem> {
  bool _isSearching = false;
  List<InventoryItemInfo> _searchResults = [];
  final TextEditingController _altSearchController = TextEditingController();
  late final TextEditingController _qtyController;

  int _maxQty() {
    final med = widget.medicine;
    // Never dispense more than prescribed.
    final byPrescription = med.prescribedQty > 0 ? med.prescribedQty : 0;
    if (med.itemId == null) return byPrescription;

    // Also cap by available stock to avoid backend failure.
    final byStock = med.stock > 0 ? med.stock : 0;
    return byPrescription < byStock ? byPrescription : byStock;
  }

  int _currentQty() {
    // Must allow 0 (skip dispensing) and preserve it.
    return widget.medicine.dispenseQty;
  }

  void _setQty(int next) {
    final max = _maxQty();
    final safe = next.clamp(0, max);
    widget.medicine.dispenseQty = safe;
    final text = safe.toString();
    if (_qtyController.text != text) {
      _qtyController.text = text;
      _qtyController.selection = TextSelection.collapsed(offset: text.length);
    }
    widget.onChanged(widget.medicine);
  }

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: _currentQty().toString());
  }

  @override
  void didUpdateWidget(covariant MedicineItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = _currentQty().toString();
    if (_qtyController.text != text) {
      _qtyController.text = text;
      _qtyController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  @override
  void dispose() {
    _altSearchController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _searchAlternative(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = []; // সার্চ বক্স ফাঁকা হলে লিস্ট ক্লিয়ার করে দিবে
      });
      return;
    }
    final results = await widget.client.dispenser.searchInventoryItems(query);
    setState(() {
      _searchResults = results;
    });
  }

  void _selectAlternative(InventoryItemInfo item) async {
    // শুধু তখনই originalItemId set করো যদি এটি আগে null থাকে
    if (widget.medicine.originalItemId == null &&
        widget.medicine.itemId != null) {
      // check inventory validity
      final validOriginal = await widget.client.dispenser.getStockByFirstWord(
        widget.medicine.name,
      );
      widget.medicine.originalItemId = validOriginal?.itemId;
    }

    // নতুন alternative medicine set
    setState(() {
      widget.medicine.itemId = item.itemId;
      widget.medicine.name = item.itemName;
      widget.medicine.stock = item.currentQuantity;
      widget.medicine.isAlternative = true;
      _isSearching = false;
      _searchResults.clear();
    });

    widget.onChanged(widget.medicine);
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicine;
    final bool itemNotFound = med.itemId == null;
    final bool outOfStock = med.stock <= 0;

    final max = _maxQty();
    final qty = _currentQty().clamp(0, max);
    final danger = itemNotFound || outOfStock;
    final stockColor = danger ? Colors.red : Colors.green;
    final bg = danger ? Colors.red.shade50 : Colors.white;

    Widget chip(String text, {required Color color, IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: danger
                          ? [Colors.red.shade400, Colors.orange.shade400]
                          : [Colors.green.shade500, Colors.teal.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medication, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name + (med.isAlternative ? ' (Alt)' : ''),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: danger ? Colors.red.shade800 : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (itemNotFound)
                            chip(
                              'NOT IN INVENTORY',
                              color: Colors.red,
                              icon: Icons.error_outline,
                            )
                          else
                            chip(
                              'Stock: ${med.stock}',
                              color: stockColor,
                              icon: outOfStock
                                  ? Icons.warning_amber
                                  : Icons.check_circle,
                            ),
                          chip(
                            'Prescribed: ${med.prescribedQty}',
                            color: Colors.indigo,
                            icon: Icons.assignment_turned_in,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dose: ${med.dose}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _isSearching ? 'Close' : 'Change / Alternative',
                  onPressed: () => setState(() => _isSearching = !_isSearching),
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.swap_horiz,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: (outOfStock || _isSearching)
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _altSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search alternative medicine...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _altSearchController.text.trim().isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _altSearchController.clear();
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: _searchAlternative,
                  ),
                  if (_altSearchController.text.trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: _searchResults.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No alternatives found',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.black.withOpacity(0.06),
                              ),
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];
                                final ok = item.currentQuantity > 0;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    item.itemName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Stock: ${item.currentQuantity}',
                                    style: TextStyle(
                                      color: ok
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Colors.grey.shade500,
                                  ),
                                  onTap: () => _selectAlternative(item),
                                );
                              },
                            ),
                    ),
                ],
              ),
              secondChild: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Stock OK — tap swap icon to change alternative.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Text(
                    'Dispense Qty',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Decrease',
                  onPressed: () => _setQty(qty - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      final next = int.tryParse(val.trim()) ?? 0;
                      _setQty(next);
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Increase',
                  onPressed: () => _setQty(qty + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ $max',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
