// lib/views/plant_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_plant_screen.dart';
import '../../services/notification_service.dart';

class PlantDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> plantData;

  const PlantDetailScreen({super.key, required this.docId, required this.plantData});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final Color primaryGreen = const Color(0xFF2E7D32);

  String _selectedLogType = 'water';
  final TextEditingController _noteController = TextEditingController();
  bool _isLogging = false;
  bool _isSettingSchedule = false;

  Timer? _uiTicker;

  late Stream<DocumentSnapshot> _plantStream;
  late Stream<QuerySnapshot> _careHistoryStream;

  @override
  void initState() {
    super.initState();
    _plantStream = FirebaseFirestore.instance.collection('users').doc(uid).collection('user_plants').doc(widget.docId).snapshots();
    _careHistoryStream = FirebaseFirestore.instance.collection('users').doc(uid).collection('user_plants').doc(widget.docId).collection('care_history').orderBy('createdAt', descending: true).snapshots();

    _uiTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} lúc ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showDeleteDialog(BuildContext context, String plantName) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Xóa cây này?"),
          content: Text("Bạn có chắc chắn muốn xóa '$plantName' khỏi vườn không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deletePlant(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
              child: const Text("XÓA CÂY", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlant(BuildContext context) async {
    if (uid == null) return;
    try {
      await NotificationService.cancelNotification(widget.docId.hashCode);
      await NotificationService.cancelNotification("${widget.docId}_water".hashCode);
      await NotificationService.cancelNotification("${widget.docId}_fertilize".hashCode);
      await NotificationService.cancelNotification("${widget.docId}_repot".hashCode);

      await FirebaseFirestore.instance.collection('users').doc(uid).collection('user_plants').doc(widget.docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa cây khỏi vườn!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi xóa: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- HÀM CÀI ĐẶT LỊCH TRÌNH (ĐÃ FIX LỖI ẨN) ---
  void _showScheduleSheet(BuildContext context, String plantName, int? wFreq, int? fFreq, int? rFreq) {
    const List<int?> validValues = [null, 10, 30, 86400, 172800, 259200, 432000, 604800, 1209600, 2592000, 7776000, 15552000];

    int? tempW = validValues.contains(wFreq) ? wFreq : null;
    int? tempF = validValues.contains(fFreq) ? fFreq : null;
    int? tempR = validValues.contains(rFreq) ? rFreq : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24, right: 24, top: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("Cài đặt lịch chăm sóc", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryGreen)),
                      const SizedBox(height: 24),

                      _buildDropdown("💧 Lịch tưới nước", tempW, (val) => setModalState(() => tempW = val)),
                      const SizedBox(height: 16),
                      _buildDropdown("🌿 Lịch bón phân", tempF, (val) => setModalState(() => tempF = val)),
                      const SizedBox(height: 16),
                      _buildDropdown("🪴 Lịch thay chậu", tempR, (val) => setModalState(() => tempR = val)),
                      const SizedBox(height: 32),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSettingSchedule ? null : () async {
                            setModalState(() => _isSettingSchedule = true);

                            try {
                              Map<String, dynamic> updates = {};

                              // Lên kịch bản cập nhật Firebase
                              if (tempW != wFreq) {
                                updates["wateringFrequency"] = tempW;
                                if (tempW != null) updates["lastWatered"] = FieldValue.serverTimestamp();
                              }

                              if (tempF != fFreq) {
                                updates["fertilizingFrequency"] = tempF;
                                if (tempF != null) updates["lastFertilized"] = FieldValue.serverTimestamp();
                              }

                              if (tempR != rFreq) {
                                updates["repottingFrequency"] = tempR;
                                if (tempR != null) updates["lastRepotted"] = FieldValue.serverTimestamp();
                              }

                              // BƯỚC 1: LƯU FIREBASE TRƯỚC TIÊN (Chắc chắn thành công)
                              if (updates.isNotEmpty) {
                                await FirebaseFirestore.instance.collection('users').doc(uid).collection('user_plants').doc(widget.docId).update(updates);
                              }

                              // BƯỚC 2: CÀI ĐẶT THÔNG BÁO CỤC BỘ (Tách riêng để không gây chết ứng dụng)
                              try {
                                if (tempW != wFreq) {
                                  if (tempW == null) {
                                    await NotificationService.cancelNotification("${widget.docId}_water".hashCode.abs());
                                  } else {
                                    await NotificationService.scheduleNotification(
                                      id: "${widget.docId}_water".hashCode.abs(),
                                      title: "💧 Đã đến lịch tưới nước!",
                                      body: "Cây '$plantName' đang khát, hãy tưới nước ngay nhé!",
                                      secondsFromNow: tempW!,
                                    );
                                  }
                                }
                                if (tempF != fFreq) {
                                  if (tempF == null) {
                                    await NotificationService.cancelNotification("${widget.docId}_fertilize".hashCode.abs());
                                  } else {
                                    await NotificationService.scheduleNotification(
                                      id: "${widget.docId}_fertilize".hashCode.abs(),
                                      title: "🌿 Lịch bón phân!",
                                      body: "Đến lúc bổ sung dinh dưỡng cho '$plantName' rồi.",
                                      secondsFromNow: tempF!,
                                    );
                                  }
                                }
                                if (tempR != rFreq) {
                                  if (tempR == null) {
                                    await NotificationService.cancelNotification("${widget.docId}_repot".hashCode.abs());
                                  } else {
                                    await NotificationService.scheduleNotification(
                                      id: "${widget.docId}_repot".hashCode.abs(),
                                      title: "🪴 Lịch thay chậu!",
                                      body: "Cây '$plantName' cần được thay chậu hoặc làm tơi đất.",
                                      secondsFromNow: tempR!,
                                    );
                                  }
                                }
                              } catch (notifError) {
                                // Nếu điện thoại chặn thông báo, chỉ in ra màn hình cảnh báo, không làm sập tiến trình
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lưu lịch thành công nhưng hệ thống chặn quyền thông báo: $notifError"), backgroundColor: Colors.orange));
                                }
                              }

                            } catch (e) {
                              // Bắt lỗi toàn cục và hiện lên UI
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi hệ thống: $e"), backgroundColor: Colors.red));
                              }
                            } finally {
                              setModalState(() => _isSettingSchedule = false);
                              if (ctx.mounted) Navigator.pop(ctx);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSettingSchedule
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("LƯU LỊCH TRÌNH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildDropdown(String label, int? currentValue, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int?>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text("Không cài đặt", style: TextStyle(color: Colors.grey))),
        DropdownMenuItem(value: 10, child: Text("Thử nghiệm: 10 giây")),
        DropdownMenuItem(value: 30, child: Text("Thử nghiệm: 30 giây")),
        DropdownMenuItem(value: 86400, child: Text("Mỗi ngày")),
        DropdownMenuItem(value: 172800, child: Text("2 ngày / lần")),
        DropdownMenuItem(value: 259200, child: Text("3 ngày / lần")),
        DropdownMenuItem(value: 432000, child: Text("5 ngày / lần")),
        DropdownMenuItem(value: 604800, child: Text("1 tuần / lần")),
        DropdownMenuItem(value: 1209600, child: Text("2 tuần / lần")),
        DropdownMenuItem(value: 2592000, child: Text("1 tháng / lần")),
        DropdownMenuItem(value: 7776000, child: Text("3 tháng / lần")),
        DropdownMenuItem(value: 15552000, child: Text("6 tháng / lần")),
      ],
      onChanged: onChanged,
    );
  }

  void _showAddLogSheet(BuildContext context, String plantName, int? wFreq, int? fFreq, int? rFreq) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24, right: 24, top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Ghi chép chăm sóc", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryGreen)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedLogType,
                      items: const [
                        DropdownMenuItem(value: 'water', child: Text("💧 Tưới nước")),
                        DropdownMenuItem(value: 'fertilize', child: Text("🌿 Bón phân")),
                        DropdownMenuItem(value: 'repot', child: Text("🪴 Thay chậu")),
                        DropdownMenuItem(value: 'note', child: Text("📝 Ghi chú / Quan sát")),
                      ],
                      decoration: InputDecoration(
                        labelText: "Hành động",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (value) => setModalState(() => _selectedLogType = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Ghi chú thêm (Tùy chọn)",
                        hintText: "Ví dụ: Tưới 200ml nước...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLogging ? null : () async {
                          setModalState(() => _isLogging = true);
                          await _saveCareLog(plantName, wFreq, fFreq, rFreq);
                          setModalState(() => _isLogging = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLogging
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("LƯU NHẬT KÝ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }
        );
      },
    ).whenComplete(() {
      _noteController.clear();
      _selectedLogType = 'water';
    });
  }

  Future<void> _saveCareLog(String plantName, int? wFreq, int? fFreq, int? rFreq) async {
    if (uid == null) return;
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference logRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('user_plants').doc(widget.docId).collection('care_history').doc();
      batch.set(logRef, {
        "type": _selectedLogType,
        "notes": _noteController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      DocumentReference plantRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('user_plants').doc(widget.docId);

      if (_selectedLogType == 'water') {
        batch.update(plantRef, {"lastWatered": FieldValue.serverTimestamp()});
        if (wFreq != null) {
          try {
            await NotificationService.scheduleNotification(
              id: "${widget.docId}_water".hashCode.abs(),
              title: "💧 Đã đến lịch tưới nước!",
              body: "Cây '$plantName' đang khát, hãy tưới nước cho cây nhé!",
              secondsFromNow: wFreq,
            );
          } catch(e) {}
        }
      } else if (_selectedLogType == 'fertilize') {
        batch.update(plantRef, {"lastFertilized": FieldValue.serverTimestamp()});
        if (fFreq != null) {
          try {
            await NotificationService.scheduleNotification(
              id: "${widget.docId}_fertilize".hashCode.abs(),
              title: "🌿 Lịch bón phân!",
              body: "Đến lúc bổ sung dinh dưỡng cho '$plantName' rồi.",
              secondsFromNow: fFreq,
            );
          } catch(e) {}
        }
      } else if (_selectedLogType == 'repot') {
        batch.update(plantRef, {"lastRepotted": FieldValue.serverTimestamp()});
        if (rFreq != null) {
          try {
            await NotificationService.scheduleNotification(
              id: "${widget.docId}_repot".hashCode.abs(),
              title: "🪴 Lịch thay chậu!",
              body: "Cây '$plantName' cần được thay chậu hoặc làm tơi đất để rễ phát triển tốt hơn.",
              secondsFromNow: rFreq,
            );
          } catch(e) {}
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Lỗi lưu nhật ký: $e");
    }
  }

  Widget _getLogIcon(String type) {
    switch (type) {
      case 'water': return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: const Icon(Icons.water_drop, color: Colors.blue, size: 20));
      case 'fertilize': return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.brown.shade50, shape: BoxShape.circle), child: const Icon(Icons.eco, color: Colors.brown, size: 20));
      case 'repot': return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle), child: const Icon(Icons.sync, color: Colors.purple, size: 20));
      default: return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.edit_note, color: Colors.grey, size: 20));
    }
  }

  String _getLogTypeName(String type) {
    switch (type) {
      case 'water': return "Đã tưới nước";
      case 'fertilize': return "Đã bón phân";
      case 'repot': return "Đã thay chậu";
      default: return "Ghi chú";
    }
  }

  String _formatDuration(int seconds) {
    if (seconds >= 86400) return "${seconds ~/ 86400} ngày";
    if (seconds >= 3600) return "${seconds ~/ 3600} giờ";
    if (seconds >= 60) return "${seconds ~/ 60} phút";
    return "$seconds giây";
  }

  Widget _buildSingleBanner(String title, int frequency, Timestamp? lastAction, MaterialColor colorSwatch, IconData icon, VoidCallback onTap) {
    if (lastAction == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colorSwatch.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: colorSwatch),
              const SizedBox(width: 12),
              Expanded(child: Text("Hãy $title lần đầu để kích hoạt lịch!", style: TextStyle(color: colorSwatch.shade800))),
            ],
          ),
        ),
      );
    }

    DateTime lastD = lastAction.toDate();
    DateTime nextD = lastD.add(Duration(seconds: frequency));
    DateTime now = DateTime.now();
    int secondsLeft = nextD.difference(now).inSeconds;

    Color bannerColor;
    Color textColor;
    String message;

    if (secondsLeft < 0) {
      String overdueStr = _formatDuration(secondsLeft.abs());
      bannerColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      message = "Đã quá hạn $title $overdueStr!";
      icon = Icons.warning_amber_rounded;
    } else {
      String timeStr = _formatDuration(secondsLeft);
      bannerColor = colorSwatch.shade50;
      textColor = colorSwatch.shade800;
      message = "$title sau $timeStr nữa...";
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bannerColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(Map<String, dynamic> liveData, String plantName) {
    int? wFreq = (liveData['wateringFrequency'] as num?)?.toInt();
    int? fFreq = (liveData['fertilizingFrequency'] as num?)?.toInt();
    int? rFreq = (liveData['repottingFrequency'] as num?)?.toInt();

    List<Widget> banners = [];

    if (wFreq != null) {
      banners.add(_buildSingleBanner("Tưới nước", wFreq, liveData['lastWatered'], Colors.blue, Icons.water_drop, () => _showScheduleSheet(context, plantName, wFreq, fFreq, rFreq)));
    }
    if (fFreq != null) {
      banners.add(_buildSingleBanner("Bón phân", fFreq, liveData['lastFertilized'], Colors.brown, Icons.eco, () => _showScheduleSheet(context, plantName, wFreq, fFreq, rFreq)));
    }
    if (rFreq != null) {
      banners.add(_buildSingleBanner("Thay chậu", rFreq, liveData['lastRepotted'], Colors.purple, Icons.sync, () => _showScheduleSheet(context, plantName, wFreq, fFreq, rFreq)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Lịch trình chăm sóc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.settings, color: primaryGreen),
              onPressed: () => _showScheduleSheet(context, plantName, wFreq, fFreq, rFreq),
            )
          ],
        ),

        if (banners.isEmpty)
          GestureDetector(
            onTap: () => _showScheduleSheet(context, plantName, wFreq, fFreq, rFreq),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("Chưa cài đặt nhắc nhở chăm sóc.", style: TextStyle(color: Colors.grey))),
                  const Text("Cài đặt", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        else
          ...banners,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _plantStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!snapshot.hasData || !snapshot.data!.exists) return const Scaffold();

        var liveData = snapshot.data!.data() as Map<String, dynamic>;
        String plantName = liveData['customName'] ?? 'Cây trồng';

        int? wFreq = (liveData['wateringFrequency'] as num?)?.toInt();
        int? fFreq = (liveData['fertilizingFrequency'] as num?)?.toInt();
        int? rFreq = (liveData['repottingFrequency'] as num?)?.toInt();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: primaryGreen),
            title: Text("Chi tiết cây", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditPlantScreen(docId: widget.docId, currentPlantData: liveData)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteDialog(context, plantName),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Image.network(
                    liveData['imageUrl'] ?? 'https://via.placeholder.com/300',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plantName,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      _buildScheduleSection(liveData, plantName),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(
                              liveData['status'] == 'healthy' ? Icons.favorite : Icons.local_hospital,
                              color: liveData['status'] == 'healthy' ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Trạng thái", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(
                                  liveData['status'] == 'healthy' ? 'Đang khỏe mạnh' : 'Cần chú ý / Có bệnh',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sổ tay chăm sóc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: () => _showAddLogSheet(context, plantName, wFreq, fFreq, rFreq),
                            icon: Icon(Icons.add_circle, color: primaryGreen),
                            label: Text("Ghi chép", style: TextStyle(color: primaryGreen)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: _careHistoryStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
                              child: Text("Chưa có ghi chép nào.\nHãy tưới nước cho cây nhé!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                            );
                          }
                          var logs = snapshot.data!.docs;
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: logs.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              var log = logs[index].data() as Map<String, dynamic>;
                              var createdAt = log['createdAt'] as Timestamp?;
                              var dateStr = createdAt != null ? _formatDate(createdAt.toDate()) : 'Đang xử lý...';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: _getLogIcon(log['type'] ?? 'note'),
                                title: Text(_getLogTypeName(log['type'] ?? 'note'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (log['notes'] != null && log['notes'].toString().isNotEmpty)
                                      Padding(padding: const EdgeInsets.only(top: 4, bottom: 4), child: Text(log['notes'], style: TextStyle(color: Colors.grey.shade800))),
                                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}