import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:sixam_mart/features/support/controllers/support_voice_controller.dart';
import 'package:sixam_mart/features/support/domain/models/support_voice_model.dart';
import 'package:sixam_mart/features/support/services/support_call_audio_service.dart';
import 'package:sixam_mart/features/support/services/support_call_notification_service.dart';

/// Owns the SIP media for the whole application.
///
/// Keeping this outside a route lets the call keep running while the dashboard
/// renders its compact controls when needed.
class SupportSipCallController extends GetxController
    implements GetxService, SipUaHelperListener {
  SIPUAHelper? _helper;
  Call? _sipCall;
  MediaStream? _localStream;
  Timer? _durationTimer;
  Timer? _retryTimer;
  Timer? _connectionTimeoutTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  SupportSipLaunch? _launch;
  SupportVoiceCall? _pendingCall;
  Duration _elapsed = Duration.zero;
  String _status = '';
  String? _error;
  bool _dialStarted = false;
  bool _incomingAnswered = false;
  bool _connected = false;
  bool _muted = false;
  bool _speakerEnabled = false;
  bool _closing = false;
  bool _pendingActionInProgress = false;
  bool _callMinimized = false;
  bool _audioSessionActive = false;
  int _audioRouteRevision = 0;
  UaSettings? _settings;
  int _retryAttempt = 0;

  SupportVoiceController get _voice => Get.find<SupportVoiceController>();
  SIPUAHelper get _activeHelper => _helper ??= SIPUAHelper();
  bool get hasActiveCall =>
      (_launch != null || _pendingCall != null) && !_closing;
  bool get hasPendingCall =>
      _pendingCall != null && _launch == null && !_closing;
  bool get isPendingActionInProgress => _pendingActionInProgress;
  bool get isCallMinimized => _callMinimized;
  bool get canControlMedia => _launch != null && !_closing;
  bool get isConnected => _connected;
  bool get isMuted => _muted;
  bool get isSpeakerEnabled => _speakerEnabled;
  String? get error => _error;
  String get peerName {
    final name =
        (_launch?.call.peerDisplayName ?? _pendingCall?.peerDisplayName)
            ?.trim() ??
        '';
    return name.isEmpty ? 'support_team'.tr : name;
  }

  String get incomingCallerLabel {
    final type =
        (_pendingCall?.recipientType ?? _launch?.call.recipientType ?? '')
            .trim()
            .toLowerCase();
    final fromDeliveryMan =
        type == 'deliveryman' ||
        type == 'delivery_man' ||
        type == 'driver' ||
        type.contains('مندوب');
    return fromDeliveryMan
        ? 'incoming_call_from_deliveryman'.tr
        : 'incoming_call_from_support'.tr;
  }

  String get statusLabel {
    if (_connected) return 'call_in_progress'.tr;
    if (_status == 'ringing') return 'call_ringing'.tr;
    if (_status == 'waiting') return 'call_waiting_for_other_party'.tr;
    return 'call_connecting'.tr;
  }

  String get durationLabel {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _incoming =>
      _launch!.call.direction.toLowerCase() == 'incoming' ||
      !_launch!.session.shouldDial;
  bool get _shouldDial => !_incoming && _launch!.session.shouldDial;

  /// Shows the outgoing call surface while the store/deliveryman is still
  /// being alerted. SIP credentials are issued only after the participant
  /// accepts, so media controls remain disabled until [start] is called.
  void showPendingCall(SupportVoiceCall call) {
    if (call.direction.toLowerCase() == 'incoming') return;
    _callMinimized = false;
    // Never replace an already visible call surface with a duplicate push or
    // notification tap. A new call can only be shown after the old one ends.
    if (_closing || hasActiveCall || _pendingActionInProgress) return;
    // A previous call may have completed while its asynchronous teardown was
    // finishing. Re-open the local state for the next outgoing mashwar/store
    // call so the pending screen is not skipped.
    _closing = false;
    _pendingCall = call;
    _launch = null;
    _status = 'ringing';
    _error = null;
    _elapsed = Duration.zero;
    _durationTimer?.cancel();
    _durationTimer = null;
    update();
  }

  /// Accept an incoming support call from the app-owned call surface.
  Future<void> acceptPendingCall() async {
    final pending = _pendingCall;
    if (pending == null || _closing || _pendingActionInProgress) return;
    _pendingActionInProgress = true;
    _status = 'connecting';
    update();
    try {
      final accepted = await _voice.acceptIncomingCall(
        pending.id,
        recordingConsent: false,
      );
      if (accepted == null || !accepted.isAccepted) {
        _error = 'could_not_accept_call'.tr;
        update();
        return;
      }
      SupportCallNotificationService.instance.markCallAnswered(pending.id);
      // The accept endpoint commits the call before the SIP credentials are
      // available. On fast devices the next request sees them immediately,
      // while slower devices briefly return a response without a session.
      // Poll briefly instead of showing a false "تعذر تجهيز الاتصال" error.
      SupportSipLaunch? launch;
      for (var attempt = 0; attempt < 4 && launch == null; attempt++) {
        launch = await _voice.getSipCallSession(
          pending.id,
          timeout: const Duration(seconds: 6),
        );
        if (launch == null && attempt < 3) {
          await Future<void>.delayed(
            Duration(milliseconds: 250 * (attempt + 1)),
          );
        }
      }
      if (launch == null) {
        _error = 'could_not_prepare_call'.tr;
        update();
        return;
      }
      await start(launch);
    } catch (error) {
      _error = error.toString();
      update();
    } finally {
      _pendingActionInProgress = false;
      update();
    }
  }

  Future<void> declinePendingCall() async {
    final pending = _pendingCall;
    if (pending == null || _closing || _pendingActionInProgress) return;
    _pendingActionInProgress = true;
    _closing = true;
    try {
      await _voice.declineIncomingCall(pending.id);
    } catch (_) {
      // The local surface must still close if the network is unavailable.
    } finally {
      _pendingCall = null;
      _pendingActionInProgress = false;
      _closing = false;
      update();
    }
  }

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.contains(ConnectivityResult.none)) return;
      if (hasActiveCall && !_connected)
        _scheduleRegistrationRetry(immediate: true);
    });
  }

  /// Starts exactly one media session. Repeated notification taps simply keep
  /// the currently running call alive instead of starting a duplicate leg.
  Future<bool> start(SupportSipLaunch launch) async {
    _callMinimized = false;
    if (_launch != null && hasActiveCall)
      return _launch!.call.id == launch.call.id;
    _resetForLaunch(launch);
    // SIPUAHelper cannot be safely re-registered after stop() on all Android
    // devices. A fresh helper fixes the common "first support call works,
    // second one only rings" failure while retaining the global controller.
    final SIPUAHelper helper = SIPUAHelper();
    _helper = helper;
    helper.addSipUaHelperListener(this);
    update();
    try {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        throw Exception('microphone_permission_required'.tr);
      }
      // Audio focus and the foreground service are important, but
      // they must not delay SIP registration. Let them initialise alongside
      // signalling so ringing begins as soon as the PBX accepts the session.
      unawaited(_beginAudioInParallel(launch));

      final session = launch.session;
      final settings = UaSettings()
        ..transportType = TransportType.WS
        ..webSocketUrl = session.websocketUrl
        ..uri = session.sipUri
        ..host = session.domain
        ..realm = session.domain
        ..authorizationUser = session.authorizationUser
        ..password = session.password
        ..displayName = session.displayName
        ..contact_uri = session.sipUri
        ..userAgent = '6elsobh Customer App'
        ..register = true
        ..register_expires = 300
        ..dtmfMode = DtmfMode.RFC2833
        ..sessionTimers = true
        ..iceServers = session.iceServers;
      settings.webSocketSettings.allowBadCertificate = false;
      _settings = settings;
      // Do not leave the customer on an endless "connecting" screen when
      // the SIP gateway, websocket, or PBX leg is unavailable.  The timer
      // covers both registration and the outgoing dial phase.
      _armConnectionTimeout(launch);
      // Publish the initial state before starting SIP. Some platforms notify
      // registration synchronously from helper.start(); setting this after
      // await could overwrite the quick transition to "ringing".
      _status = 'connecting';
      update();
      await helper.start(settings);
      if (_closing || !identical(_launch, launch)) return false;
      return true;
    } catch (e) {
      _error = e.toString();
      update();
      await end(closeRemote: false);
      return false;
    }
  }

  void _armConnectionTimeout(SupportSipLaunch launch) {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_closing || _connected || !identical(_launch, launch)) return;
      _error = 'call_connection_timeout'.tr;
      update();
      // Keep the message visible briefly, then clean up the SIP leg and the
      // server-side pending call so the next attempt starts cleanly.
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!_closing && !_connected && identical(_launch, launch)) {
          unawaited(end());
        }
      });
    });
  }

  Future<void> _beginAudioInParallel(SupportSipLaunch launch) async {
    try {
      await SupportCallAudioService.begin(
        callId: launch.call.id,
        peerName: launch.call.peerDisplayName,
        reference: launch.call.orderReference ?? 'support_team'.tr,
        outgoing: _shouldDial,
      );
      if (_closing || !identical(_launch, launch)) {
        await SupportCallAudioService.end();
        return;
      }
      _audioSessionActive = true;
      _refreshAudioRoute(afterWebRtcStarts: true);
    } catch (_) {
      // SIP can still establish media on devices where the optional native
      // foreground/audio layer is temporarily unavailable.
    }
  }

  void _resetForLaunch(SupportSipLaunch launch) {
    _connectionTimeoutTimer?.cancel();
    _launch = launch;
    _pendingCall = null;
    _elapsed = Duration.zero;
    _durationTimer?.cancel();
    _durationTimer = null;
    _status = 'connecting';
    _error = null;
    _dialStarted = false;
    _incomingAnswered = false;
    _connected = false;
    _muted = false;
    _speakerEnabled = false;
    _closing = false;
    _retryAttempt = 0;
    _retryTimer?.cancel();
  }

  Future<void> _dial() async {
    if (_dialStarted || _closing || _launch == null) return;
    _dialStarted = true;
    _status = 'ringing';
    update();
    final session = _launch!.session;
    final started = await _activeHelper.call(
      session.target,
      voiceOnly: true,
      headers: <String>[
        'X-Support-Token: ${session.supportToken}',
        'X-Support-Call-ID: ${session.callId}',
        if (session.orderId != null) 'X-Order-ID: ${session.orderId}',
      ],
    );
    if (!started) {
      _error = 'could_not_start_call'.tr;
      update();
      await end();
    }
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    if (_closing || _launch == null) return;
    if (state.state == RegistrationStateEnum.REGISTERED) {
      if (_shouldDial) {
        unawaited(_dial());
      } else {
        _status = 'waiting';
        update();
      }
    } else if (state.state == RegistrationStateEnum.REGISTRATION_FAILED) {
      _error = state.cause?.toString() ?? 'call_registration_failed'.tr;
      update();
      _scheduleRegistrationRetry();
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    if (!_closing &&
        !_connected &&
        state.state == TransportStateEnum.DISCONNECTED) {
      _error = 'call_service_unavailable'.tr;
      update();
      _scheduleRegistrationRetry();
    }
  }

  /// Retries only while the call has not connected. This recovers a SIP
  /// registration interrupted by Wi-Fi/mobile switching without renegotiating
  /// an already established call.
  void _scheduleRegistrationRetry({bool immediate = false}) {
    if (_closing || _connected || _launch == null || _settings == null) return;
    if (_retryTimer?.isActive ?? false) return;
    if (_retryAttempt >= 3) return;
    final retryIndex = _retryAttempt++;
    final delay = immediate
        ? Duration.zero
        : Duration(seconds: <int>[1, 3, 7][retryIndex]);
    _retryTimer = Timer(delay, () async {
      if (_closing || _connected || _settings == null) return;
      try {
        await _activeHelper.start(_settings!);
      } catch (_) {
        _scheduleRegistrationRetry();
      }
    });
  }

  @override
  void callStateChanged(Call call, CallState state) {
    _sipCall = call;
    if (_closing || _launch == null) return;
    if (_incoming &&
        !_incomingAnswered &&
        call.direction == Direction.incoming &&
        state.state == CallStateEnum.CALL_INITIATION) {
      _incomingAnswered = true;
      call.answer(_activeHelper.buildCallOptions(true));
    }
    switch (state.state) {
      case CallStateEnum.STREAM:
        if (state.originator == Originator.local) _localStream = state.stream;
        // STREAM can arrive as early media while the PSTN leg is still
        // ringing. Do not start the billed/in-call timer here; wait for
        // ACCEPTED/CONFIRMED, which means the other party actually answered.
        _refreshAudioRoute(afterWebRtcStarts: true);
        break;
      case CallStateEnum.PROGRESS:
      case CallStateEnum.CONNECTING:
      case CallStateEnum.CALL_INITIATION:
        _status = _shouldDial ? 'ringing' : 'connecting';
        update();
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        _connectionTimeoutTimer?.cancel();
        _startDurationTimer();
        // Enable Android's proximity screen-off wake lock as soon as the SIP
        // leg is connected.  Keep it disabled while speakerphone is selected;
        // switching back to the earpiece re-enables it below.
        unawaited(SupportCallAudioService.setProximityScreen(!_speakerEnabled));
        _refreshAudioRoute(afterWebRtcStarts: true);
        update();
        break;
      case CallStateEnum.FAILED:
        _error = state.cause?.toString() ?? 'call_failed'.tr;
        update();
        unawaited(_finishAfterSip());
        break;
      case CallStateEnum.ENDED:
        unawaited(_finishAfterSip());
        break;
      default:
        break;
    }
  }

  void _startDurationTimer() {
    if (_durationTimer != null) return;
    _connected = true;
    _status = 'connected';
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      update();
    });
    update();
  }

  Future<void> toggleMute() async {
    final call = _sipCall;
    if (call == null) return;
    _muted ? call.unmute(true, false) : call.mute(true, false);
    _muted = !_muted;
    update();
  }

  Future<void> toggleSpeaker() async {
    _speakerEnabled = !_speakerEnabled;
    // Invalidate delayed route repairs from the previous selection before
    // applying the new choice.
    _audioRouteRevision++;
    await _applyAudioRoute();
    update();
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
    for (final delay in <Duration>[
      Duration.zero,
      const Duration(milliseconds: 300),
      const Duration(milliseconds: 900),
      const Duration(milliseconds: 1800),
      const Duration(milliseconds: 3000),
      const Duration(milliseconds: 4500),
    ]) {
      Future<void>.delayed(delay, () {
        if (!_closing && revision == _audioRouteRevision) {
          unawaited(_applyAudioRoute());
        }
      });
    }
  }

  Future<void> _finishAfterSip() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await end();
  }

  Future<void> end({bool closeRemote = true}) async {
    _callMinimized = false;
    if (_closing) return;
    _closing = true;
    final launch = _launch;
    final pending = _pendingCall;
    _retryTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    _durationTimer = null;
    if (closeRemote) _sipCall?.hangup();
    if (launch != null) {
      final bool incoming = launch.call.direction.toLowerCase() == 'incoming';
      // Keep a local activity record for outgoing support/deliveryman calls.
      // Incoming answered calls are also recorded here so they are not later
      // misclassified as missed when the remote end sends support_call_ended.
      unawaited(
        recordSupportCall(
          launch.call.id,
          callerName: launch.call.peerDisplayName,
          status: incoming ? (_connected ? 'answered' : 'missed') : 'outgoing',
        ),
      );
      try {
        // Remote reconciliation must never keep the local call screen stuck
        // if the API is slow or temporarily unreachable.
        await _voice
            .closeCall(launch.call.id, wasAccepted: _connected)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // A temporary API failure must not retain the native call or block
        // the user's next call. The server reconciles the stale record later.
      }
    } else if (pending != null) {
      try {
        await _voice
            .closeCall(pending.id, wasAccepted: false)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Keep teardown local even when cancelling the pending call fails.
      }
    }
    try {
      await _disposeMedia();
    } finally {
      _launch = null;
      _pendingCall = null;
      _sipCall = null;
      _connected = false;
      _muted = false;
      _speakerEnabled = false;
      _status = '';
      _closing = false;
      update();
    }
  }

  void minimizeCall() {
    if (!hasActiveCall || hasPendingCall) return;
    _callMinimized = true;
    update();
  }

  void restoreCall() {
    if (!hasActiveCall) return;
    _callMinimized = false;
    update();
  }

  Future<void> _disposeMedia() async {
    final SIPUAHelper? helper = _helper;
    _helper = null;
    _settings = null;
    helper?.removeSipUaHelperListener(this);
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    helper?.stop();
    if (_audioSessionActive) {
      _audioSessionActive = false;
      await SupportCallAudioService.end();
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}
  @override
  void onNewNotify(Notify ntf) {}
  @override
  void onNewReinvite(ReInvite event) {}

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    unawaited(end(closeRemote: false));
    super.onClose();
  }
}
