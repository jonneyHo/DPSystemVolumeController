#import "DPSystemVolumeController.h"


#if TARGET_OS_IPHONE && !(TARGET_IPHONE_SIMULATOR)
#if ENABLE_ACCESS_PRIVATE_API


#import <MediaPlayer/MediaPlayer.h>
#import "dp_exec_block_on_main_thread.h"
#import "DPStringEncrypter.h"


NSString* const DPSystemVolumeControllerAES256SharedKey = @"4fo81OKCX5mts2o2WQYNiAC3BKAhkby";
/*
 plain: AVSystemController_SystemVolumeDidChangeNotification
 enc:   1LeAbDOKYj3lvush23o4/bsL1lGzf2unw8gYEHsHd7iz50PgneH5hJxUI1i1/Aw1O+plW/eAy2SzyQABQmgR2g==
 
 plain: AVSystemController_AudioVolumeNotificationParameter
 enc:   1LeAbDOKYj3lvush23o4/XZY/VT7bNly0q+FBcYCM8rJ3jc1DnaQJXkNl85MmorNJO/56ZmXxLAOV5siZofDaw==
 
 plain: AVSystemController_AudioVolumeChangeReasonNotificationParameter
 enc:   1LeAbDOKYj3lvush23o4/VI0sqpwtvg4HAyrCbLpVK0pfXQyRkQdQxSMUq6B/qvo+KKsNA/De6Sa4RAvQvbe2A==
 
 plain: ExplicitVolumeChange
 enc:   6TDXuOJx05GFak1xo/IjIAWKXWDq8rLAICmUQUYpNSk=
 
 plain: AVSystemController_AudioCategoryNotificationParameter
 enc:   1LeAbDOKYj3lvush23o4/QjRkLoqBoMSEcM+RBhm4yFZR2eRu8MoOM6Aoyb7Dz7Ol4LVTTF9+31jIxFlnQnqvg==
 
 plain: Ringtone
 enc:   9OLHMhyMQQwt61XpuxNOqw==
 
 plain: Audio/Video
 enc:   I0NTsCuEuGv08oDu/J/o4Q==
 
 plain: AVSystemController
 enc:   1LeAbDOKYj3lvush23o4/YNTLQdCiFDrxRe6a8fkWWo=
 
 plain: sharedAVSystemController
 enc:   T7a3l/r5tlr79HFBYZCvvVRT51yAQYX3hNwfrDnmO/0=
 
 plain: volumeCategoryForAudioCategory:
 enc:   +eAkm14sa2+M80W/At1ffqizEpqVaMJftQlVOFM08pI=
 
 plain: getVolume:forCategory:
 enc:   FFlNp022W9dXgQA+dEr38BULKklfLNrpeD0LF9G6fqg=
  
 plain: setVolumeTo:forCategory:
 enc:   hHTa/jSVRx/bJfsGUq5kxvqon5OfdAM99oh/mAmri98=
 */


@interface DPSystemVolumeController ()
{
    NSHashTable* _observers;
}
@end


@implementation DPSystemVolumeController

#pragma mark - Initializer

- (void)dealloc
{
    [self removeVolumeChangeNotificationObserver];
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return self;
}

- (instancetype)initSharedManager
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        [self addVolumeChangeNotificationObserver];
    }
    return self;
}

#pragma mark - AES256

- (NSString*)decrypt:(NSString*)encryptedBase64String
{
    return [DPStringEncrypter decryptedStringForBase64String:encryptedBase64String key:DPSystemVolumeControllerAES256SharedKey];
}

#pragma mark - Singleton Pattern

+ (instancetype)sharedController
{
    static DPSystemVolumeController* sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initSharedManager];
    });
    return sharedManager;
}

#pragma mark - Notifications

- (void)addVolumeChangeNotificationObserver
{
    // たぶん Apple の内部実装の都合で一度 [MPMusicPlayerController applicationMusicPlayer] を呼び出して初期化走らせてやる必要があるので、こういう書き方になった。
    if ([MPMusicPlayerController applicationMusicPlayer]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catchVolumeChangeNotification:) name:[self decrypt:@"1LeAbDOKYj3lvush23o4/bsL1lGzf2unw8gYEHsHd7iz50PgneH5hJxUI1i1/Aw1O+plW/eAy2SzyQABQmgR2g=="] object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catchVolumeChangeNotification:) name:[self decrypt:@"1LeAbDOKYj3lvush23o4/bsL1lGzf2unw8gYEHsHd7iz50PgneH5hJxUI1i1/Aw1O+plW/eAy2SzyQABQmgR2g=="] object:nil];
    }
}

- (void)removeVolumeChangeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[self decrypt:@"1LeAbDOKYj3lvush23o4/bsL1lGzf2unw8gYEHsHd7iz50PgneH5hJxUI1i1/Aw1O+plW/eAy2SzyQABQmgR2g=="] object:nil];
}

- (void)catchVolumeChangeNotification:(NSNotification*)notification
{
    float volume          = [notification.userInfo[[self decrypt:@"1LeAbDOKYj3lvush23o4/XZY/VT7bNly0q+FBcYCM8rJ3jc1DnaQJXkNl85MmorNJO/56ZmXxLAOV5siZofDaw=="]] floatValue];
    BOOL  isExplictChange = [notification.userInfo[[self decrypt:@"1LeAbDOKYj3lvush23o4/VI0sqpwtvg4HAyrCbLpVK0pfXQyRkQdQxSMUq6B/qvo+KKsNA/De6Sa4RAvQvbe2A=="]] isEqualToString:[self decrypt:@"6TDXuOJx05GFak1xo/IjIAWKXWDq8rLAICmUQUYpNSk="]];
    id    audioCategory   =  notification.userInfo[[self decrypt:@"1LeAbDOKYj3lvush23o4/QjRkLoqBoMSEcM+RBhm4yFZR2eRu8MoOM6Aoyb7Dz7Ol4LVTTF9+31jIxFlnQnqvg=="]];
    
    dp_exec_block_on_main_thread(^{
        for (id<DPSystemVolumeControllerObserving> observer in _observers) {
            if ([observer respondsToSelector:@selector(systemVolumeController:didChangeVolume:isExplictChange:audioCategory:)]) {
                [observer systemVolumeController:self didChangeVolume:volume isExplictChange:isExplictChange audioCategory:audioCategory];
            }
        }
    });
}

#pragma mark - Accessor

- (float)volumeForRingtone
{
    float volume = -1.0;
    NSString* audioCategory = [self decrypt:@"9OLHMhyMQQwt61XpuxNOqw=="];
    if ([self getVolume:&volume category:audioCategory] == NO) {
        NSLog(@"maybe get volumeForRingtone failed.");
        return -1.0;
    }
    return volume;
}

- (void)setVolumeForRingtone:(float)volumeForRingtone
{
    NSString* audioCategory = [self decrypt:@"9OLHMhyMQQwt61XpuxNOqw=="];
    if ([self setVolume:volumeForRingtone category:audioCategory] == NO) {
        NSLog(@"maybe setVolumeForRingtone failed.");
    }
}

- (float)volumeForAudioVideo
{
    float volume = -1.0;
    NSString* audioCategory = [self decrypt:@"I0NTsCuEuGv08oDu/J/o4Q=="];
    if ([self getVolume:&volume category:audioCategory] == NO) {
        NSLog(@"maybe get volumeForAudioVideo failed.");
        return -1.0;
    }
    return volume;
}

- (void)setVolumeForAudioVideo:(float)volumeForAudioVideo
{
    NSString* audioCategory = [self decrypt:@"I0NTsCuEuGv08oDu/J/o4Q=="];
    if ([self setVolume:volumeForAudioVideo category:audioCategory] == NO) {
        NSLog(@"maybe setVolumeForRingtone failed.");
    }
}

#pragma mark - Observers

- (void)addSystemVolumeControllerObserver:(__weak id<DPSystemVolumeControllerObserving>)observer
{
    if (observer && [observer conformsToProtocol:@protocol(DPSystemVolumeControllerObserving)]) {
        if ([_observers containsObject:observer] == NO) {
            [_observers addObject:observer];
        }
    }
}

- (void)removeSystemVolumeControllerObserver:(__weak id<DPSystemVolumeControllerObserving>)observer
{
    if (observer && [_observers containsObject:observer]) {
        [_observers removeObject:observer];
    }
}

#pragma mark - System

- (id)systemController
{
    /*
     AVSystemController というプライベートクラスを利用する。
     以下のコードと等価
     
     AVSystemController* systemController = [AVSystemController sharedAVSystemController];
     return systemController;
     */
    
    Class class    = NSClassFromString([self decrypt:@"1LeAbDOKYj3lvush23o4/YNTLQdCiFDrxRe6a8fkWWo="]);
    SEL   selector = NSSelectorFromString([self decrypt:@"T7a3l/r5tlr79HFBYZCvvVRT51yAQYX3hNwfrDnmO/0="]);
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id controller = [class performSelector:selector];
    #pragma clang diagnostic pop
    return controller;
}

- (BOOL)getVolume:(float*)volume category:(NSString*)category
{
    /*
     AVSystemController Class の
     - (id)volumeCategoryForAudioCategory:(id)arg1;
     - (bool)getVolume:(float*)arg1 forCategory:(id)arg2;
     を叩いてる。以下のコードと等価
     
     AVSystemController* systemController = [AVSystemController sharedAVSystemController];
     NSString* volumeCategory = [systemController volumeCategoryForAudioCategory:category];
     BOOL success = [systemController getVolume:volume forCategory:volumeCategory];
     return success;
     */
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id  volumeCategory = [[self systemController] performSelector:NSSelectorFromString([self decrypt:@"+eAkm14sa2+M80W/At1ffqizEpqVaMJftQlVOFM08pI="]) withObject:category];
    #pragma clang diagnostic pop
    id  target = [self systemController];
    SEL sel = NSSelectorFromString([self decrypt:@"FFlNp022W9dXgQA+dEr38BULKklfLNrpeD0LF9G6fqg="]);
    NSMethodSignature* signature = [target methodSignatureForSelector:sel];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:target];
    [invocation setSelector:sel];
    [invocation setArgument:&volume atIndex:2];
    [invocation setArgument:&volumeCategory atIndex:3];
    [invocation invoke];
    BOOL success;
    [invocation getReturnValue:&success];
    return success;
}

- (BOOL)setVolume:(float)volume category:(NSString*)category
{
    /*
     AVSystemController Class の
     - (id)volumeCategoryForAudioCategory:(id)arg1;
     - (bool)setVolumeTo:(float)arg1 forCategory:(id)arg2;
     を叩いてる。以下のコードと等価
     
     AVSystemController* systemController = [AVSystemController sharedAVSystemController];
     NSString* volumeCategory = [systemController volumeCategoryForAudioCategory:category];
     BOOL success = [systemController setVolumeTo:volume forCategory:volumeCategory];
     return success;
     */
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id  volumeCategory = [[self systemController] performSelector:NSSelectorFromString([self decrypt:@"+eAkm14sa2+M80W/At1ffqizEpqVaMJftQlVOFM08pI="]) withObject:category];
    #pragma clang diagnostic pop
    id  target = [self systemController];
    SEL sel = NSSelectorFromString([self decrypt:@"hHTa/jSVRx/bJfsGUq5kxvqon5OfdAM99oh/mAmri98="]);
    NSMethodSignature* signature = [target methodSignatureForSelector:sel];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:target];
    [invocation setSelector:sel];
    [invocation setArgument:&volume atIndex:2];
    [invocation setArgument:&volumeCategory atIndex:3];
    [invocation invoke];
    BOOL success;
    [invocation getReturnValue:&success];
    return success;
}

@end


#endif
#endif