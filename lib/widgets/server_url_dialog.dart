import 'package:flutter/material.dart';
import '../config/backend_config.dart';

/// Reusable dialog to configure and test the backend server URL.
class ServerUrlDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const ServerUrlDialog({this.onSaved});

  @override
  State<ServerUrlDialog> createState() => _ServerUrlDialogState();
}

class _ServerUrlDialogState extends State<ServerUrlDialog> {
  late final TextEditingController _controller;
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await BackendConfig.getBaseUrl();
    if (mounted) {
      setState(() {
        _controller.text = url;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    setState(() => _saving = true);
    await BackendConfig.setBaseUrl(url);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      widget.onSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server URL saved. Try the AI Assistant again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Server URL'),
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Phone & laptop on SAME Wi‑Fi (turn off mobile data on phone)\n'
                    '2. Server running on laptop: node server.js\n'
                    '3. If Test fails: On laptop, right-click OPEN_FIREWALL.bat → Run as administrator',
                    style: TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://10.78.148.144:3000',
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _saving || _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _testing || _loading ? null : () async {
            final url = _controller.text.trim();
            if (url.isEmpty) return;
            setState(() => _testing = true);
            final err = await BackendConfig.testConnection(url);
            if (!mounted) return;
            setState(() => _testing = false);
            if (err == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connection successful!'), backgroundColor: Colors.green),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connection failed: $err'), backgroundColor: Colors.red, duration: const Duration(seconds: 6)),
              );
            }
          },
          child: _testing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Test'),
        ),
        TextButton(
          onPressed: _saving || _loading ? null : () async {
            await BackendConfig.resetToDefault();
            if (mounted) {
              _controller.text = defaultBaseUrl;
              setState(() {});
            }
          },
          child: const Text('Reset'),
        ),
        FilledButton(
          onPressed: _saving || _loading ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}
