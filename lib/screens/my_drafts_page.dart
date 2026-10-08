import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/listing_draft_repository.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _draftsFuture = widget.repository.getAllDrafts();
  }

  Future<void> _deleteDraft(int id) async {
    try {
      await widget.repository.deleteDraft(id);
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบร่างประกาศแล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบร่างประกาศไม่สำเร็จ: $error')),
      );
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร่างประกาศของฉัน')),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('โหลดร่างประกาศไม่สำเร็จ: ${snapshot.error}'));
          }
          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(child: Text('ยังไม่มีร่างประกาศที่บันทึกไว้'));
          }
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return ListTile(
                title: Text(draft.title),
                subtitle: Text(
                  'หมวดหมู่: ${draft.category}\n'
                  'แก้ไขล่าสุด: ${_formatDateTime(draft.updatedAt)}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'ลบร่างประกาศ',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteDraft(draft.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
