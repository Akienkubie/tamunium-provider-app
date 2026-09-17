import 'package:flutter/material.dart';
import 'dispatcher_shortlist_screen.dart';

class DispatcherShellScreen extends StatefulWidget {
  const DispatcherShellScreen({super.key});

  @override
  State<DispatcherShellScreen> createState() => _DispatcherShellScreenState();
}

class _DispatcherShellScreenState extends State<DispatcherShellScreen> {
  int _selectedIndex = 0;

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    (Icons.inbox_outlined, Icons.inbox, 'Requests'),
    (Icons.people_outline, Icons.people, 'Providers'),
    (Icons.work_outline, Icons.work, 'Jobs'),
    (Icons.payments_outlined, Icons.payments, 'Payments'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Reports'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  String get _title => _items[_selectedIndex].$3;

  void _select(int index) {
    Navigator.of(context).pop();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TAMUNIUM Central · $_title'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), tooltip: 'Open Central menu', onPressed: () => Scaffold.of(context).openDrawer())),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                color: const Color(0xFF061A2B),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.hub_outlined, color: Color(0xFFE8B15A), size: 38),
                  SizedBox(height: 12),
                  Text('TAMUNIUM Central', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('The operating brain', style: TextStyle(color: Colors.white70)),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _items.length,
                  itemBuilder: (context, index) => ListTile(
                    selected: _selectedIndex == index,
                    leading: Icon(_selectedIndex == index ? _items[index].$2 : _items[index].$1),
                    title: Text(_items[index].$3),
                    onTap: () => _select(index),
                  ),
                ),
              ),
              const Divider(height: 1),
              const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerLeft, child: Text('Staff operations', style: TextStyle(fontSize: 12, color: Colors.grey)))),
            ],
          ),
        ),
      ),
      body: _body,
    );
  }

  Widget get _body {
    if (_selectedIndex == 1) return const DispatcherShortlistScreen(embedInShell: true);
    final descriptions = [
      ('Good morning', 'Monitor requests, workforce, jobs, and ecosystem health from one operating loop.', Icons.insights_outlined),
      ('Provider directory', 'Review verified providers, skills, ratings, availability, and provider reputation.', Icons.people_outline),
      ('Active jobs', 'Monitor dispatched, accepted, in-progress, completed, and disputed work.', Icons.work_outline),
      ('Payments', 'Review pending earnings, approvals, platform fees, and provider payouts.', Icons.payments_outlined),
      ('Reports', 'Operational analytics and service performance reports will appear here.', Icons.bar_chart_outlined),
      ('Settings', 'Central rules, service categories, staff controls, and notification preferences.', Icons.settings_outlined),
    ];
    if (_selectedIndex == 0) return const _CentralOverview();
    final item = descriptions[_selectedIndex - 1];
    return _ComingSoonPage(title: item.$1, description: item.$2, icon: item.$3);
  }
}

class _CentralOverview extends StatelessWidget {
  const _CentralOverview();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Good morning,', style: Theme.of(context).textTheme.titleMedium),
        Text('TAMUNIUM Central', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Here is what is happening across your service ecosystem today.'),
        const SizedBox(height: 24),
        const Row(children: [Expanded(child: _MetricCard(label: 'Open requests', value: '—', icon: Icons.inbox_outlined)), SizedBox(width: 10), Expanded(child: _MetricCard(label: 'Active jobs', value: '—', icon: Icons.work_outline))]),
        const SizedBox(height: 10),
        const Row(children: [Expanded(child: _MetricCard(label: 'Verified providers', value: '—', icon: Icons.verified_outlined)), SizedBox(width: 10), Expanded(child: _MetricCard(label: 'System health', value: 'Live', icon: Icons.health_and_safety_outlined))]),
        const SizedBox(height: 24),
        const Card(child: ListTile(leading: Icon(Icons.hub_outlined), title: Text('One ecosystem. One operating loop.'), subtitle: Text('Open the menu to manage requests, providers, jobs, payments, and reports.'))),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), Text(label, style: Theme.of(context).textTheme.bodySmall)])));
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  const _ComingSoonPage({required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16), Text(title, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), Text(description, textAlign: TextAlign.center), const SizedBox(height: 20), const Chip(label: Text('Module coming next'))])));
}
