import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/device.dart';
import '../services/device_repository.dart';
import 'device_form_screen.dart';
import 'home/delete_device_dialog.dart';
import 'home/device_list.dart';
import 'home/device_details_dialog.dart';
import 'home/empty_device_state.dart';
import 'home/home_controller.dart';
import 'home/home_header.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeController _controller;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    final repository = widget.repository;
    _controller = HomeController(
      repository,
      updates: repository is LiveDeviceRepository
          ? (repository as LiveDeviceRepository).updates
          : null,
    )..load();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _controller.dispose();
      _createController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm([Device? device]) async {
    if (_controller.busy) return;
    _controller.setFormOpen(true);
    final repository = _controller.repository;
    final saved = await Navigator.of(context).push<Device>(
      MaterialPageRoute(
        builder: (_) =>
            DeviceFormScreen(repository: repository, device: device),
      ),
    );
    if (!mounted) return;
    _controller.setFormOpen(false);
    if (saved != null && repository == _controller.repository) {
      if (device == null) {
        _controller.applySaved(saved);
      } else {
        _controller.applyUpdated(saved);
      }
    }
  }

  Future<void> _delete(Device device) async {
    if (_controller.busy) return;
    _controller.setFormOpen(true);
    final repository = _controller.repository;
    final confirmed = await confirmDeviceDeletion(context, device);
    if (!mounted) return;
    _controller.setFormOpen(false);
    if (confirmed != true) return;
    _controller.setDeleting(device.id);
    try {
      await repository.delete(device.id);
      if (!mounted) return;
      if (repository == _controller.repository) {
        _controller.removeDevice(device.id);
      }
      _controller.setDeleting(null);
    } catch (_) {
      if (!mounted) return;
      _controller.setDeleting(null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).deleteError)),
      );
    }
  }

  Future<void> _power(Device device, {required bool turnOn}) async {
    if (_controller.busy) return;
    final text = AppLocalizations.of(context);
    if (!turnOn) {
      _controller.setFormOpen(true);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(text.shutdownTitle),
          content: Text(text.shutdownDescription(device.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(text.powerOff),
            ),
          ],
        ),
      );
      if (!mounted) return;
      _controller.setFormOpen(false);
      if (confirmed != true) return;
    }
    _controller.setPowering(device.id);
    try {
      if (turnOn) {
        await _controller.repository.powerOn(device.id);
      } else {
        await _controller.repository.powerOff(device.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(turnOn ? text.powerOnAccepted : text.powerOffAccepted),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text.powerError)));
      }
    } finally {
      if (mounted) _controller.setPowering(null);
    }
  }

  Future<void> _checkSsh(Device device) async {
    try {
      await _controller.checkSsh(device.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).sshCheckError)),
        );
      }
    }
  }

  void _openSettings() => Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => const SettingsScreen()));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: CustomScrollView(
              slivers: [
                HomeHeader(
                  count: _controller.devices.length,
                  loadFailed: _controller.loadFailed,
                  onSettings: _openSettings,
                  onReload: _controller.busy ? null : _controller.load,
                  onAdd: _controller.busy ? null : () => _openForm(),
                ),
                if (_controller.hasLiveUpdates && !_controller.liveConnected)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Text(
                        AppLocalizations.of(context).liveDisconnected,
                      ),
                    ),
                  ),
                if (_controller.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_controller.devices.isEmpty && !_controller.loadFailed)
                  SliverToBoxAdapter(
                    child: EmptyDeviceState(
                      onAdd: _controller.busy ? null : () => _openForm(),
                    ),
                  )
                else
                  DeviceList(
                    devices: _controller.devices,
                    busy: _controller.busy,
                    deletingId: _controller.deletingId,
                    onEdit: (device) => showDeviceDetails(context, device),
                    onModify: widget.repository is EditableDeviceRepository
                        ? (device) => _openForm(device)
                        : null,
                    onPowerOn: (device) => _power(device, turnOn: true),
                    onPowerOff: (device) => _power(device, turnOn: false),
                    poweringId: _controller.poweringId,
                    checkingId: _controller.checkingId,
                    onCheckSsh: widget.repository is SshCheckRepository
                        ? _checkSsh
                        : null,
                    onDelete: _delete,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
