import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wireguard_flutter/repository/models.dart';

import '../log.dart';
import 'common/buttons.dart';
import 'common/texts.dart';
import 'ui_constants.dart';

const initName = 'my-tunnel';
const initAddress = "10.0.0.5";
const initPort = "32";
const initDnsServer = "8.8.8.8";
const initPrivateKey = "oHJqkAb9DGvPpoRTxbEEXFvbFDsy62lYvHUhwcr5AVs=";
const initAllowedIp = "0.0.0.0/0";
const initPublicKey = "9CpWrA3ZtLuCQA7NVGaKv7xZAWga5A03Qxhq334yzwQ=";
const initEndpoint = "185.103.254.102:51820";

class TunnelDetails extends StatefulWidget {
  @override
  createState() => _TunnelDetailsState();
}

class _TunnelDetailsState extends State<TunnelDetails> {
  static const platform = const MethodChannel('tark.pro/wireguard-flutter');
  String _name = initName;
  String _address = initAddress;
  String _listenPort = initPort;
  String _dnsServer = initDnsServer;
  String _privateKey = initPrivateKey;
  String _peerAllowedIp = initAllowedIp;
  String _peerPublicKey = initPublicKey;
  String _peerEndpoint = initEndpoint;
  final _nameController = TextEditingController(
    text: initName,
  );
  final _addressController = TextEditingController(
    text: initAddress,
  );
  final _listenPortController = TextEditingController(
    text: initPort,
  );
  final _dnsServerController = TextEditingController(
    text: initDnsServer,
  );
  final _privateKeyController = TextEditingController(
    text: initPrivateKey,
  );
  final _peerAllowedIpController = TextEditingController(
    text: initAllowedIp,
  );
  final _peerPublicKeyController = TextEditingController(
    text: initPublicKey,
  );
  final _peerEndpointController = TextEditingController(
    text: initEndpoint,
  );
  bool _connected = false;
  bool _scrolledToTop = true;
  bool _gettingStats = true;
  Stats? _stats;
  Timer? _gettingStatsTimer;

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStateChange':
          try {
            final stats = StateChangeData.fromJson(jsonDecode(call.arguments));
            if (stats.tunnelState) {
              setState(() => _connected = true);
              _startGettingStats(context);
            } else {
              setState(() => _connected = false);
              _stopGettingStats();
            }
          } catch (e) {
            l('initState', 'error', e);
          }

          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Texts.semiBold(
          'Edit tunnel',
          color: Colors.black,
          textSize: AppSize.fontMedium,
        ),
        backgroundColor: Colors.grey[100],
        elevation: _scrolledToTop ? 0 : null,
      ),
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          setState(() => _scrolledToTop = notification.metrics.pixels == 0);
          return true;
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: AppPadding.allNormal,
                child: Column(
                  children: [
                    _divider('Stats'),
                    _statsWidget(_stats),
                    _divider('Tunnel'),
                    _input(
                      hint: 'Tunnel name',
                      enabled: false,
                      controller: _nameController,
                      onChanged: (v) => setState(() => _name = v),
                    ),
                    const Vertical.small(),
                    _input(
                      hint: 'Address',
                      enabled: !_connected,
                      controller: _addressController,
                      onChanged: (v) => setState(() => _address = v),
                    ),
                    const Vertical.small(),
                    _input(
                      hint: 'Listen port',
                      enabled: !_connected,
                      controller: _listenPortController,
                      onChanged: (v) => setState(() => _listenPort = v),
                    ),
                    const Vertical.small(),
                    _input(
                      hint: 'DNS server',
                      enabled: !_connected,
                      controller: _dnsServerController,
                      onChanged: (v) => setState(() => _dnsServer = v),
                    ),
                    const Vertical.small(),
                    _input(
                      hint: 'Private key',
                      enabled: !_connected,
                      controller: _privateKeyController,
                      onChanged: (v) => setState(() => _privateKey = v),
                    ),
                    _divider('Peer'),
                    _input(
                      hint: 'Peer allowed IP',
                      enabled: !_connected,
                      controller: _peerAllowedIpController,
                      onChanged: (v) => setState(() => _peerAllowedIp = v),
                    ),
                    const Vertical.small(),
                    _input(
                      hint: 'Peer public key',
                      enabled: !_connected,
                      controller: _peerPublicKeyController,
                      onChanged: (v) => setState(() => _peerPublicKey = v),
                    ),
                    const Vertical.small(),
                    _input(
                      hint: 'Peer endpoint',
                      enabled: !_connected,
                      controller: _peerEndpointController,
                      onChanged: (v) => setState(() => _peerEndpoint = v),
                    ),
                    Padding(
                      padding: AppPadding.top(60),
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: AppPadding.allNormal,
                child: Buttons(
                  text: _connected ? 'Disconnect' : 'Connect',
                  buttonColor: _connected ? Colors.red[400] : Colors.green[400],
                  onPressed: () => _onActionButtonPressed(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onActionButtonPressed(BuildContext context) {
    if (_name.isEmpty) {
      _showError(context, 'Enter the tunnel name');
      return;
    }
    if (_address.isEmpty) {
      _showError(context, 'Enter the address');
      return;
    }
    if (_listenPort.isEmpty) {
      _showError(context, 'Enter the listen port');
      return;
    }
    if (_dnsServer.isEmpty) {
      _showError(context, 'Enter the dns server');
      return;
    }
    if (_privateKey.isEmpty) {
      _showError(context, 'Enter the private key');
      return;
    }
    if (_peerAllowedIp.isEmpty) {
      _showError(context, 'Enter the peer allowed IP');
      return;
    }
    if (_peerPublicKey.isEmpty) {
      _showError(context, 'Enter the public key');
      return;
    }
    if (_peerEndpoint.isEmpty) {
      _showError(context, 'Enter the peer endpoint');
      return;
    }

    _setTunnelState(context);
  }

  Future _setTunnelState(BuildContext context) async {
    try {
      final result = await platform.invokeMethod(
        'setState',
        jsonEncode(SetStateParams(
          state: !_connected,
          tunnel: Tunnel(
            name: _name,
            address: _address,
            dnsServer: _dnsServer,
            listenPort: _listenPort,
            peerAllowedIp: _peerAllowedIp,
            peerEndpoint: _peerEndpoint,
            peerPublicKey: _peerPublicKey,
            privateKey: _privateKey,
          ),
        ).toJson()),
      );
      /*if (result == true) {
        setState(() => _connected = !_connected);
      }*/
    } on PlatformException catch (e) {
      l('_setState', e.toString());
      _showError(context, e.toString());
    }
  }

  _getTunnelNames(BuildContext context) async {
    try {
      final result = await platform.invokeMethod('getTunnelNames');
    } on PlatformException catch (e) {
      l('_getTunnelNames', e.toString());
      _showError(context, e.toString());
    }
  }

  _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Texts.semiBold(error, color: Colors.white),
      backgroundColor: Colors.red[400],
    ));
  }

  _showSuccess(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Texts.semiBold(
        error,
        color: Colors.white,
      ),
      backgroundColor: Colors.green[500],
    ));
  }

  _startGettingStats(BuildContext context) {
    _gettingStatsTimer?.cancel();
    _gettingStatsTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!_gettingStats) {
        timer.cancel();
      }
      try {
        final result = await platform.invokeMethod('getStats', _name);
        final stats = Stats.fromJson(jsonDecode(result));
        setState(() => _stats = stats);
      } catch (e) {
        // can't get scaffold context from initState. todo: fix this
        //_showError(context, e.toString());
      }
    });
  }

  _stopGettingStats() {
    setState(() => _gettingStats = false);
  }

  Widget _input({
    required String hint,
    required ValueChanged<String> onChanged,
    bool enabled = true,
    required TextEditingController controller,
  }) {
    return Container(
      padding: AppPadding.horizontalSmall,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        border: Border.fromBorderSide(
          BorderSide(
            color: enabled ? Colors.black12 : Colors.black.withOpacity(0.05),
            width: 1.0,
          ),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          const Vertical.micro(),
          Row(
            children: [
              Texts(
                hint,
                textSize: AppSize.fontSmall,
                color: Colors.black38,
                height: 1.5,
              ),
            ],
          ),
          TextField(
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              isDense: true,
            ),
            style: GoogleFonts.openSans(
              textStyle: TextStyle(fontWeight: FontWeight.w600),
              height: 1.0,
            ),
            controller: controller,
            onChanged: onChanged,
          ),
          const Vertical.micro(),
        ],
      ),
    );
  }

  Widget _divider(String title) {
    return Padding(
      padding: AppPadding.verticalNormal,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: AppPadding.rightNormal,
              child: Container(
                height: 0.5,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
          ),
          Texts.smallVery(
            title.toUpperCase(),
            color: Colors.black45,
          ),
          Expanded(
            child: Padding(
              padding: AppPadding.leftNormal,
              child: Container(
                height: 0.5,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsWidget(Stats? stats) {
    return Container(
      padding: AppPadding.horizontalSmall,
      //height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(
          BorderSide(
            color: Colors.black12,
            width: 1.0,
          ),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Vertical.micro(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Texts(
                      'Upload',
                      textSize: AppSize.fontSmall,
                      color: Colors.black38,
                      height: 1.5,
                    ),
                  ],
                ),
                Texts.semiBold(
                    _formatBytes(stats?.totalUpload.toInt() ?? 0, 0)),
                const Vertical.medium(),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Vertical.micro(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Texts(
                      'Download',
                      textSize: AppSize.fontSmall,
                      color: Colors.black38,
                      height: 1.5,
                    ),
                  ],
                ),
                Texts.semiBold(
                    _formatBytes(stats?.totalDownload.toInt() ?? 0, 0)),
                const Vertical.medium(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }
}
