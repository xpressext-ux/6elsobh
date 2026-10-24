import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:sixam_mart/features/support/controllers/support_voice_controller.dart';
import 'package:sixam_mart/features/support/domain/models/support_voice_model.dart';
import 'package:sixam_mart/features/support/services/support_call_audio_service.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class IssabelSupportCallScreen extends StatefulWidget {
  final SupportSipLaunch launch;

  const IssabelSupportCallScreen({super.key, required this.launch});

  @override
  State<IssabelSupportCallScreen> createState() =>
      _IssabelSupportCallScreenState();
}

class _IssabelSupportCallScreenState extends State<IssabelSupportCallScreen>
    implements SipUaHelperListener {
  final SIPUAHelper _helper = SIPUAHelper();
  Call? _sipCall;
  MediaStream? _localStream;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;
  String _status = 'preparing_secure_call';
  String? _error;
  bool _dialStarted = false;
  bool _incomingAnswered = false;
  bool _connected = false;
  bool _muted = false;
  bool _speakerEnabled = false;
  bool _closing = false;
  bool _audioSessionActive = false;
  int _audioRouteRevision = 0;

  SupportVoiceController get _controller => Get.find<SupportVoiceController>();
  SupportSipSession get _session => widget.launch.session;

  /// A call started by a PBX extension is an incoming call even if an older
  /// server response does not include `should_dial: false` yet.  Never start
  /// a second, outgoing support call for that case.
  bool get _isIncomingExtensionCall {
    return widget.launch.call.direction.toLowerCase() == 'incoming' ||
        !_session.shouldDial;
  }

  bool get _shouldDial => !_isIncomingExtensionCall && _session.shouldDial;

  String get _incomingEmployeeName {
    final String name = widget.launch.call.peerDisplayName.trim();
    return name.isEmpty ? 'support_team'.tr : name;
  }

  bool get _incomingFromDeliveryMan {
    final type = (widget.launch.call.recipientType ?? '').trim().toLowerCase();
    return type == 'deliveryman' ||
        type == 'delivery_man' ||
        type == 'driver' ||
        type.contains('مندوب');
  }

  @override
  void initState() {
    super.initState();
    _helper.addSipUaHelperListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_connect()));
  }

  Future<void> _connect() async {
    try {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        throw Exception('microphone_permission_required'.tr);
      }

      await SupportCallAudioService.begin(
        callId: widget.launch.call.id,
        peerName: widget.launch.call.peerDisplayName,
        reference: widget.launch.call.orderReference ?? 'support_team'.tr,
        outgoing: _shouldDial,
      );
      _audioSessionActive = true;
      // The SIP/WebRTC engine can take audio focus a moment after startup.
      // created. Apply the selected route again once that happens instead of
      // leaving the support call on a stale earpiece route.
      _refreshAudioRoute(afterWebRtcStarts: true);

      final settings = UaSettings()
        ..transportType = TransportType.WS
        ..webSocketUrl = _session.websocketUrl
        ..uri = _session.sipUri
        ..host = _session.domain
        ..realm = _session.domain
        ..authorizationUser = _session.authorizationUser
        ..password = _session.password
        ..displayName = _session.displayName
        ..contact_uri = _session.sipUri
        ..userAgent = '6elsobh Customer App'
        ..register = true
        ..register_expires = 300
        ..dtmfMode = DtmfMode.RFC2833
        ..sessionTimers = true
        ..iceServers = _session.iceServers;
      settings.webSocketSettings.allowBadCertificate = false;
      await _helper.start(settings);
      if (mounted) setState(() => _status = 'connecting_to_support');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _dial() async {
    if (_dialStarted || _closing) return;
    _dialStarted = true;
    if (mounted) setState(() => _status = 'ringing_support_team');
    final started = await _helper.call(
      _session.target,
      voiceOnly: true,
      headers: <String>[
        'X-Support-Token: ${_session.supportToken}',
        'X-Support-Call-ID: ${_session.callId}',
        if (_session.orderId != null) 'X-Order-ID: ${_session.orderId}',
      ],
    );
    if (!started && mounted) {
      setState(() => _error = 'could_not_start_support_call'.tr);
      // A failed dial must not leave a reusable SIP credential or a queued
      // support call behind on the server.
      unawaited(_finishFromSip());
    }
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    if (!mounted) return;
    if (state.state == RegistrationStateEnum.REGISTERED) {
      if (_shouldDial) {
        unawaited(_dial());
      } else {
        setState(() => _status = 'waiting_for_peer');
      }
    } else if (state.state == RegistrationStateEnum.REGISTRATION_FAILED) {
      setState(
        () => _error = state.cause?.toString() ?? 'sip_registration_failed'.tr,
      );
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    if (!mounted || _closing) return;
    if (state.state == TransportStateEnum.DISCONNECTED && !_connected) {
      setState(() => _error = 'sip_gateway_unavailable'.tr);
    }
  }

  @override
  void callStateChanged(Call call, CallState state) {
    _sipCall = call;
    if (!mounted) return;
    if (_isIncomingExtensionCall &&
        !_incomingAnswered &&
        call.direction == Direction.incoming &&
        state.state == CallStateEnum.CALL_INITIATION) {
      _incomingAnswered = true;
      call.answer(_helper.buildCallOptions(true));
    }
    switch (state.state) {
      case CallStateEnum.STREAM:
        if (state.originator == Originator.local) {
          _localStream = state.stream;
        }
        // Some Android/SIP combinations emit STREAM without a subsequent
        // ACCEPTED/CONFIRMED callback.  STREAM means media is established,
        // so start the visible call clock here as a safe fallback.
        _startDurationTimer();
        // A stream event is emitted after WebRTC owns AudioManager on outgoing
        // support calls. Never force the earpiece here: it used to undo the
        // speaker button only for support calls.
        _refreshAudioRoute(afterWebRtcStarts: true);
        break;
      case CallStateEnum.PROGRESS:
      case CallStateEnum.CONNECTING:
      case CallStateEnum.CALL_INITIATION:
        setState(
          () => _status = _shouldDial
              ? 'ringing_support_team'
              : 'connecting_to_support',
        );
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        _startDurationTimer();
        setState(() => _status = 'connected_securely');
        break;
      case CallStateEnum.FAILED:
        setState(() => _error = state.cause?.toString() ?? 'call_failed'.tr);
        unawaited(_finishFromSip());
        break;
      case CallStateEnum.ENDED:
        unawaited(_finishFromSip());
        break;
      case CallStateEnum.MUTED:
      case CallStateEnum.UNMUTED:
      case CallStateEnum.HOLD:
      case CallStateEnum.UNHOLD:
      case CallStateEnum.NONE:
      case CallStateEnum.REFER:
        break;
    }
  }

  void _startDurationTimer() {
    if (_durationTimer != null) return;
    _connected = true;
    // The earpiece is the default route. Keep the proximity wake-lock active
    // for every connected call; speakerphone disables it below.
    unawaited(SupportCallAudioService.setProximityScreen(!_speakerEnabled));
    _refreshAudioRoute(afterWebRtcStarts: true);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _toggleMute() async {
    final call = _sipCall;
    if (call == null) return;
    if (_muted) {
      call.unmute(true, false);
    } else {
      call.mute(true, false);
    }
    if (mounted) setState(() => _muted = !_muted);
  }

  Future<void> _toggleSpeaker() async {
    final next = !_speakerEnabled;
    if (mounted) setState(() => _speakerEnabled = next);
    // Apply one route change at a time; repeated delayed route writes can
    // otherwise make the call jump between speaker and earpiece.
    _audioRouteRevision++;
    await _applyAudioRoute();
  }

  Future<void> _applyAudioRoute() async {
    await SupportCallAudioService.setSpeaker(_speakerEnabled);
    await SupportCallAudioService.setProximityScreen(
      _connected && !_speakerEnabled,
    );
  }

  void _refreshAudioRoute({bool afterWebRtcStarts = false}) {
    final revision = ++_audioRouteRevision;
    unawaited(_applyAudioRoute());
    if (!afterWebRtcStarts) return;

    // flutter_webrtc/PJSIP can claim audio focus after the state callback.
    // Retrying briefly keeps both an outgoing support call and an incoming
    // SIP call on the route selected by the user.
    for (final delay in <Duration>[
      Duration.zero,
      const Duration(milliseconds: 300),
      const Duration(milliseconds: 900),
      const Duration(milliseconds: 1800),
    ]) {
      Future<void>.delayed(delay, () {
        if (!_closing && mounted && revision == _audioRouteRevision) {
          unawaited(_applyAudioRoute());
        }
      });
    }
  }

  Future<void> _hangUp() async {
    if (_closing) return;
    _sipCall?.hangup();
    await _finishAndClose();
  }

  Future<void> _finishFromSip() async {
    if (_closing) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _finishAndClose();
  }

  Future<void> _finishAndClose() async {
    if (_closing) return;
    _closing = true;
    _durationTimer?.cancel();
    try {
      await _controller.closeCall(
        widget.launch.call.id,
        wasAccepted: _connected,
      );
    } catch (_) {
      // Local cleanup remains mandatory even if the user loses connectivity
      // while ending the call; server reconciliation will close the stale leg.
    } finally {
      await _disposeSip();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _disposeSip() async {
    _helper.removeSipUaHelperListener(this);
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    _helper.stop();
    if (_audioSessionActive) {
      _audioSessionActive = false;
      await SupportCallAudioService.end();
    }
  }

  String get _durationLabel {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _statusLabel {
    if (_connected || _status == 'connected_securely') {
      return 'call_in_progress'.tr;
    }
    final String translated = _status.tr.trim();
    return translated.isEmpty || translated == _status
        ? 'call_connecting'.tr
        : translated;
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  @override
  void dispose() {
    _durationTimer?.cancel();
    _helper.removeSipUaHelperListener(this);
    _helper.stop();
    if (_audioSessionActive) {
      _audioSessionActive = false;
      unawaited(SupportCallAudioService.end());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_hangUp());
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    onPressed: _hangUp,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 122,
                  height: 122,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: <Color>[colors.primary, colors.primaryContainer],
                    ),
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(
                      color: _connected
                          ? colors.tertiary
                          : colors.outlineVariant,
                      width: 2,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.primary.withValues(alpha: .22),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    size: 62,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Text(
                  _isIncomingExtensionCall
                      ? 'incoming_call'.tr
                      : 'support_team'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeOverLarge,
                  ),
                ),
                if (_isIncomingExtensionCall) ...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    _incomingFromDeliveryMan
                        ? 'incoming_call_from_deliveryman'.tr
                        : 'incoming_call_from_support'.tr,
                    textAlign: TextAlign.center,
                    style: robotoMedium.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    _incomingEmployeeName,
                    textAlign: TextAlign.center,
                    style: robotoMedium,
                  ),
                ] else if (widget.launch.call.orderReference != null)
                  Text(
                    widget.launch.call.orderReference!,
                    style: robotoMedium.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                Text(
                  _connected ? 'call_in_progress'.tr : _statusLabel,
                  textAlign: TextAlign.center,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraLarge,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                  ),
                  child: Text(
                    _durationLabel,
                    style: robotoBold.copyWith(fontSize: 30, letterSpacing: 2),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Container(
                    padding: const EdgeInsets.all(
                      Dimensions.paddingSizeDefault,
                    ),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: robotoMedium.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallButton(
                      icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: 'microphone'.tr,
                      active: _muted,
                      enabled: _sipCall != null,
                      onTap: _toggleMute,
                    ),
                    _CallButton(
                      icon: Icons.call_end_rounded,
                      label: 'end'.tr,
                      destructive: true,
                      onTap: _hangUp,
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                Text(
                  'phone_number_hidden_from_both_parties'.tr,
                  textAlign: TextAlign.center,
                  style: robotoRegular.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;
  final bool destructive;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = destructive
        ? colors.error
        : active
        ? colors.primary
        : colors.surfaceContainerHighest;
    final foreground = destructive || active ? Colors.white : colors.onSurface;
    return Column(
      children: [
        IconButton.filled(
          onPressed: enabled ? onTap : null,
          style: IconButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            fixedSize: const Size(58, 58),
          ),
          icon: Icon(icon),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(label, style: robotoMedium),
      ],
    );
  }
}
