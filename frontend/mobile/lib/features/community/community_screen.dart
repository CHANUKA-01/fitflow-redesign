import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/catalogue.dart';
import '../../data/models.dart';

/// Circles. Defaults to the smallest private circle (R11) and states who can
/// see every post and draft in plain words (U01, ADR-004).
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _circleId = circles.first.id;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final circle = circleById(_circleId);
    final posts = s.postsIn(_circleId);

    return Scaffold(
      appBar: AppBar(title: const Text('Circles')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Post'),
        onPressed: () => _compose(context, circle),
      ),
      body: ListView(padding: pagePadding(context, 0, 96), children: [
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final c in circles)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  showCheckmark: false,
                  avatar: Icon(c.isPrivate ? Icons.lock_outline : Icons.public, size: 18),
                  label: Text(c.name),
                  selected: c.id == _circleId,
                  onSelected: (_) => setState(() => _circleId = c.id),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Card(
          color: (circle.isPrivate ? FF.teal : FF.amber).withValues(alpha: 0.10),
          child: ListTile(
            leading: Icon(circle.isPrivate ? Icons.lock_outline : Icons.public,
                color: circle.isPrivate ? FF.teal : FF.amber),
            title: Text(circle.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(circle.isPrivate
                ? 'Private circle · ${circle.members} members. Only members can see posts here.'
                : 'Public feed. Anyone using FitFlow can see posts here.'),
          ),
        ),
        const SizedBox(height: 12),
        if (posts.isEmpty)
          const Card(child: ListTile(title: Text('No posts yet. Share how your week is going.')))
        else
          for (final p in posts) _PostCard(post: p, circle: circle),
      ]),
    );
  }

  Future<void> _compose(BuildContext context, Circle initial) async {
    final postedTo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _Composer(initial: initial.isPrivate ? initial : circles.first),
    );
    if (postedTo != null) setState(() => _circleId = postedTo);
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.circle});

  final Post post;
  final Circle circle;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: post.mine ? FF.coral.withValues(alpha: 0.15) : t.colorScheme.primaryContainer,
                child: Text(post.author[0], style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.author, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(timeAgo(post.date), style: t.textTheme.bodySmall),
                ]),
              ),
              PopupMenuButton<String>(
                tooltip: 'Post options',
                onSelected: (v) {
                  if (v == 'delete') s.deletePost(post);
                  if (v == 'report') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks. The post was reported to the circle moderators.')),
                    );
                  }
                },
                itemBuilder: (_) => [
                  if (post.mine) const PopupMenuItem(value: 'delete', child: Text('Delete post')),
                  if (!post.mine) const PopupMenuItem(value: 'report', child: Text('Report post')),
                ],
              ),
            ]),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(post.text, style: t.textTheme.bodyLarge),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Pill(
                    audienceLabel(circle),
                    icon: circle.isPrivate ? Icons.lock_outline : Icons.public,
                    color: circle.isPrivate ? FF.teal : FF.amber,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => s.toggleLike(post),
                icon: Icon(post.liked ? Icons.favorite : Icons.favorite_border, color: post.liked ? FF.coral : null),
                label: Text('${post.likes}'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.initial});

  final Circle initial;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _text = TextEditingController();
  late Circle _audience = widget.initial;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('New post', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _audience.id,
          decoration: const InputDecoration(labelText: 'Who can see this?'),
          items: [
            for (final c in circles)
              DropdownMenuItem(
                value: c.id,
                child: Row(children: [
                  Icon(c.isPrivate ? Icons.lock_outline : Icons.public, size: 18),
                  const SizedBox(width: 8),
                  Text(c.name),
                ]),
              ),
          ],
          onChanged: (id) => setState(() => _audience = circleById(id!)),
        ),
        const SizedBox(height: 8),
        Pill(
          audienceLabel(_audience),
          icon: _audience.isPrivate ? Icons.lock_outline : Icons.public,
          color: _audience.isPrivate ? FF.teal : FF.amber,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          decoration: const InputDecoration(hintText: 'Share a win, a question or a challenge…'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _text.text.trim().isEmpty
                ? null
                : () {
                    AppScope.read(context).addPost(_text.text.trim(), _audience.id);
                    Navigator.pop(context, _audience.id);
                  },
            child: Text(_audience.isPrivate ? 'Post to ${_audience.name}' : 'Post publicly'),
          ),
        ),
      ]),
    );
  }
}
