//
//  ESConstants.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESConstants.h"

NSString* const SETTINGS_APP_OBSERVER = @"appObserver";
NSString* const SETTINGS_OWN_WORKER_THREAD = @"ownWorkerThread";
NSString* const SETTINGS_APP_DIRECTORY = @"appDirectory";
NSString* const SETTINGS_APP_LOG_LEVEL = @"appLogLevel";
NSString* const SETTINGS_APP_LOG_FILEPATH = @"appLogFilePath";
NSString* const SETTINGS_SERVER_IP = @"sipServerIp";
NSString* const SETTINGS_SERVER_PORT = @"sipServerPort";
NSString* const SETTINGS_PROTOCOL = @"protocol";
NSString* const SETTINGS_NAT_TYPE = @"natType";
NSString* const SETTINGS_USERNAME = @"userName";
NSString* const SETTINGS_PASSWORD = @"password";
NSString* const SETTINGS_PROXY_SERVER_IP = @"proxyServerIp";
NSString* const SETTINGS_PROXY_SERVER_PORT = @"proxyServerPort";
NSString* const SETTINGS_KA_INTERVAL = @"kaInterval";
NSString* const SETTINGS_KAD_DATA = @"kaDdata";
NSString* const SETTINGS_USE_SRTP = @"useSrtp";
NSString* const SETTINGS_SRTP_SECURE_SIGNALING = @"srtpSecureSignaling";
NSString* const SETTINGS_SPEECH_CODE = @"speechCode";
NSString* const SETTINGS_SPEECH_RATE = @"speechRate";
NSString* const SETTINGS_VAD = @"vad";
NSString* const SETTINGS_MEDIA_TRANSPORT_ADDRESS = @"mediaTransportAddress";
NSString* const SETTINGS_MEDIA_TRANSPORT_PORT = @"mediaTransportPort";
NSString* const SETTINGS_NAT_ICE_ENABLE = @"natIceEnable";
NSString* const SETTINGS_NAT_TURN_ENABLE = @"natTurnEnable";
NSString* const SETTINGS_NAT_REWRITE_USE = @"natRewriteUse";
NSString* const SETTINGS_SRTP_USE = @"srtpUse";
NSString* const SETTINGS_PAYLOADTYPES = @"payloadTypes";
NSString* const SETTINGS_AUTO_RECORD = @"autoRecord";
NSString* const SETTINGS_ROUTER_NUMBER = @"routerNumber";
NSString* const SETTINGS_CONTACT_REWRITE_USE = @"contactRewriteUse";
NSString* const SETTINGS_VIA_REWRITE_USE = @"viaRewriteUse";

NSString* const SETTINGS_TRANS_TYPE = @"transType";

NSString* const SETTINGS_KAD_DATA_DEFAULT = @"\r\n";

//NSString* const SPEECH_CODE_OPUS = @"Opus";
//NSString* const SPEECH_CODE_G711 = @"G711";
//NSString* const SPEECH_CODE_G722 = @"G722";
//NSString* const SPEECH_CODE_G726 = @"G726";
//NSString* const SPEECH_CODE_G729 = @"G729";

NSString* const PROTOCOL_UNSPECIFIED = @"unspecified";
NSString* const PROTOCOL_UDP = @"udp";
NSString* const PROTOCOL_TCP = @"tcp";
NSString* const PROTOCOL_TLS = @"tls";
NSString* const PROTOCOL_SCTP = @"sctp";
NSString* const PROTOCOL_LOOP = @"loop";
NSString* const PROTOCOL_LOOP_DGRAM = @"loop_dgram";
NSString* const PROTOCOL_START_OTHER = @"start_other";
NSString* const PROTOCOL_IPV6 = @"ipv6";
NSString* const PROTOCOL_UDP6 = @"udp6";
NSString* const PROTOCOL_TCP6 = @"tcp6";
NSString* const PROTOCOL_TLS6 = @"tls6";

NSString* const DEFAULT_CONFIG_NAME = @"essip.json";

NSString* const LOG_TAG = @"ESSIPLib";

NSString* const CURRENT_CALL_ID  = @"currentCallId";
