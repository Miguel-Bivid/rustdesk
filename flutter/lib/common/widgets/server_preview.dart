import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';

/// Read-only summary of the servers this client uses, so support staff can
/// tell at a glance whether the build still points at the public default.
class ServerPreview extends StatelessWidget {
  const ServerPreview({Key? key}) : super(key: key);

  static String _shortKey(String key) =>
      key.length > 16 ? '${key.substring(0, 8)}…${key.substring(key.length - 6)}' : key;

  @override
  Widget build(BuildContext context) {
    final idServer = bind.mainGetOptionSync(key: 'custom-rendezvous-server');
    final relayServer = bind.mainGetOptionSync(key: 'relay-server');
    final apiServer = bind.mainGetOptionSync(key: 'api-server');
    final key = bind.mainGetOptionSync(key: 'key');
    final muted = Theme.of(context).hintColor;

    Widget row(IconData icon, String label, String value, {bool isSet = true}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: MyTheme.accent),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(translate(label), style: TextStyle(color: muted)),
          ),
          Expanded(
            child: SelectableText(
              value,
              maxLines: 1,
              style: TextStyle(
                fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
                color: isSet ? null : muted,
              ),
            ),
          ),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyTheme.accent.withOpacity(0.35)),
        color: MyTheme.accent.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              translate('Connected servers'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            FutureBuilder<bool>(
              future: bind.mainIsUsingPublicServer(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final isPublic = snapshot.data!;
                return _Badge(
                  text: translate(
                      isPublic ? 'Default public server' : 'Custom server'),
                  color: isPublic ? Colors.orange.shade700 : MyTheme.accent,
                  icon: isPublic ? Icons.warning_amber_rounded : Icons.verified,
                );
              },
            ),
          ]),
          const SizedBox(height: 10),
          row(Icons.dns_outlined, 'ID Server',
              idServer.isEmpty ? translate('Default public server') : idServer,
              isSet: idServer.isNotEmpty),
          row(Icons.swap_horiz, 'Relay Server',
              relayServer.isEmpty ? translate('Automatic') : relayServer,
              isSet: relayServer.isNotEmpty),
          row(Icons.api_outlined, 'API Server',
              apiServer.isEmpty ? translate('Not set') : apiServer,
              isSet: apiServer.isNotEmpty),
          row(Icons.key_outlined, 'Server key',
              key.isEmpty ? translate('Not set') : _shortKey(key),
              isSet: key.isNotEmpty),
          if (isDesktop)
            Obx(() {
              final status = stateGlobal.svcStatus.value;
              return row(
                Icons.circle,
                'Status',
                translate(status == SvcStatus.ready
                    ? 'Ready'
                    : status == SvcStatus.connecting
                        ? 'Connecting...'
                        : 'not_ready_status'),
              );
            }),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Badge({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
