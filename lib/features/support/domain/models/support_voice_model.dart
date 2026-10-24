class SupportVoiceOptions {
  final bool enabled;
  final bool showDeliverymanPhone;
  final bool showDeliverymanSipCall;
  final bool showStorePhone;
  final bool recordingEnabled;
  final bool recordingReady;
  final bool recordingConsentRequired;
  final bool agentsAvailable;
  final bool sipEnabled;
  final bool sipReady;
  final String issabelQueue;
  final SupportVoiceCall? activeCall;

  const SupportVoiceOptions({
    required this.enabled,
    required this.showDeliverymanPhone,
    required this.showDeliverymanSipCall,
    required this.showStorePhone,
    required this.recordingEnabled,
    required this.recordingReady,
    required this.recordingConsentRequired,
    required this.agentsAvailable,
    required this.sipEnabled,
    required this.sipReady,
    required this.issabelQueue,
    required this.activeCall,
  });

  factory SupportVoiceOptions.fromJson(Map<String, dynamic> json) {
    return SupportVoiceOptions(
      enabled: json['enabled'] == true || json['enabled'] == 1,
      showDeliverymanPhone:
          json['show_deliveryman_phone'] == true ||
          json['show_deliveryman_phone'] == 1,
      showDeliverymanSipCall:
          json['show_deliveryman_sip_call'] == null ||
          json['show_deliveryman_sip_call'] == true ||
          json['show_deliveryman_sip_call'] == 1,
      showStorePhone:
          json['show_store_phone'] == null ||
          json['show_store_phone'] == true ||
          json['show_store_phone'] == 1,
      recordingEnabled:
          json['recording_enabled'] == true || json['recording_enabled'] == 1,
      recordingReady:
          json['recording_ready'] == true || json['recording_ready'] == 1,
      recordingConsentRequired:
          json['recording_consent_required'] == true ||
          json['recording_consent_required'] == 1,
      agentsAvailable:
          json['agents_available'] == true || json['agents_available'] == 1,
      sipEnabled: json['sip_enabled'] == true || json['sip_enabled'] == 1,
      sipReady: json['sip_ready'] == true || json['sip_ready'] == 1,
      issabelQueue: json['issabel_queue']?.toString() ?? '505',
      activeCall: json['active_call'] is Map<String, dynamic>
          ? SupportVoiceCall.fromJson(json['active_call'])
          : null,
    );
  }
}

class SupportSipSession {
  final String callId;
  final int? orderId;
  final String websocketUrl;
  final String domain;
  final String sipUri;
  final String authorizationUser;
  final String password;
  final String displayName;
  final String target;
  final String queue;
  final String supportToken;
  final List<Map<String, String>> iceServers;
  final String route;
  final String participantType;
  final int participantId;
  final String targetType;
  final int targetId;
  final bool shouldDial;

  const SupportSipSession({
    required this.callId,
    required this.orderId,
    required this.websocketUrl,
    required this.domain,
    required this.sipUri,
    required this.authorizationUser,
    required this.password,
    required this.displayName,
    required this.target,
    required this.queue,
    required this.supportToken,
    required this.iceServers,
    required this.route,
    required this.participantType,
    required this.participantId,
    required this.targetType,
    required this.targetId,
    required this.shouldDial,
  });

  factory SupportSipSession.fromJson(Map<String, dynamic> json) {
    return SupportSipSession(
      callId: json['call_id']?.toString() ?? '',
      orderId: int.tryParse(json['order_id']?.toString() ?? ''),
      websocketUrl: json['websocket_url']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      sipUri: json['sip_uri']?.toString() ?? '',
      authorizationUser: json['authorization_user']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Customer Support',
      target: json['target']?.toString() ?? '',
      queue: json['queue']?.toString() ?? '505',
      supportToken: json['support_token']?.toString() ?? '',
      iceServers:
          (json['ice_server_configs'] is List || json['ice_servers'] is List)
          ? ((json['ice_server_configs'] is List
                        ? json['ice_server_configs']
                        : json['ice_servers'])
                    as List)
                .map(
                  (value) => value is Map
                      ? Map<String, String>.fromEntries(
                          value.entries.map(
                            (entry) => MapEntry(
                              entry.key.toString(),
                              entry.value.toString(),
                            ),
                          ),
                        )
                      : <String, String>{'urls': value.toString()},
                )
                .toList()
          : const <Map<String, String>>[],
      route: json['route']?.toString() ?? 'queue',
      participantType: json['participant_type']?.toString() ?? 'customer',
      participantId:
          int.tryParse(json['participant_id']?.toString() ?? '') ?? 0,
      targetType: json['target_type']?.toString() ?? '',
      targetId: int.tryParse(json['target_id']?.toString() ?? '') ?? 0,
      shouldDial:
          json['should_dial'] == null ||
          json['should_dial'] == true ||
          json['should_dial'] == 1,
    );
  }
}

class SupportSipLaunch {
  final SupportVoiceCall call;
  final SupportSipSession session;

  const SupportSipLaunch({required this.call, required this.session});

  factory SupportSipLaunch.fromJson(Map<String, dynamic> json) {
    return SupportSipLaunch(
      call: SupportVoiceCall.fromJson(
        Map<String, dynamic>.from(json['call'] as Map),
      ),
      session: SupportSipSession.fromJson(
        Map<String, dynamic>.from(json['session'] as Map),
      ),
    );
  }
}

class SupportVoiceCall {
  final String id;
  final int? orderId;
  final String? orderReference;
  final String status;
  final String direction;
  final String? recipientType;
  final String peerDisplayName;
  final int queuedAhead;
  final bool recordingRequested;
  final String recordingStatus;
  final bool pstnCall;

  const SupportVoiceCall({
    required this.id,
    required this.orderId,
    required this.orderReference,
    required this.status,
    required this.direction,
    required this.recipientType,
    required this.peerDisplayName,
    required this.queuedAhead,
    required this.recordingRequested,
    required this.recordingStatus,
    required this.pstnCall,
  });

  bool get isAccepted => status == 'accepted';
  bool get isWaiting => status == 'queued' || status == 'ringing';
  bool get isFinished => const {
    'ended',
    'cancelled',
    'declined',
    'missed',
    'failed',
  }.contains(status);

  factory SupportVoiceCall.fromJson(Map<String, dynamic> json) {
    return SupportVoiceCall(
      id: json['id']?.toString() ?? '',
      orderId: int.tryParse(json['order_id']?.toString() ?? ''),
      orderReference: json['order_reference']?.toString(),
      status: json['status']?.toString() ?? 'queued',
      direction: json['direction']?.toString() ?? 'outgoing',
      recipientType: json['recipient_type']?.toString(),
      peerDisplayName: json['peer_display_name']?.toString() ?? 'فريق الدعم',
      queuedAhead: int.tryParse(json['queued_ahead']?.toString() ?? '') ?? 0,
      recordingRequested:
          json['recording_requested'] == true ||
          json['recording_requested'] == 1,
      recordingStatus: json['recording_status']?.toString() ?? 'disabled',
      pstnCall:
          json['pstn_call'] == true ||
          json['pstn_call'] == 1 ||
          json['sip_route'] == 'pstn',
    );
  }
}

class SupportVoiceSession {
  final String callId;
  final String appId;
  final String channel;
  final String token;
  final int uid;
  final String peerDisplayName;
  final String encryptionMode;
  final String encryptionKey;
  final String encryptionSalt;

  const SupportVoiceSession({
    required this.callId,
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    required this.peerDisplayName,
    required this.encryptionMode,
    required this.encryptionKey,
    required this.encryptionSalt,
  });

  factory SupportVoiceSession.fromJson(Map<String, dynamic> json) {
    return SupportVoiceSession(
      callId: json['call_id']?.toString() ?? '',
      appId: json['app_id']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      uid: int.tryParse(json['uid']?.toString() ?? '') ?? 0,
      peerDisplayName: json['peer_display_name']?.toString() ?? 'فريق الدعم',
      encryptionMode: json['encryption_mode']?.toString() ?? 'aes-256-gcm2',
      encryptionKey: json['encryption_key']?.toString() ?? '',
      encryptionSalt: json['encryption_salt']?.toString() ?? '',
    );
  }
}
