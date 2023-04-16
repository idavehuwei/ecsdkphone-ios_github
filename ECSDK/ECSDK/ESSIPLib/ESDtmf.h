//
//  ESDtmf.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

//NS_ASSUME_NONNULL_BEGIN


#ifdef __cplusplus__
extern "c" {
#endif
void sip_call_play_digit(int call_id, char digit);
void sip_call_deinit_tonegen(int call_id);
void sip_call_play_info_digit(int call_id, char digit);

void sip_call_play_digits(int call_id, void *digits);
void sip_call_play_info_digits(int call_id, void *digits);
#ifdef __cplusplus__
extern "c" }
#endif


//NS_ASSUME_NONNULL_END
