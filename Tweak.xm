#import "NSData+AES256.m"

@interface SBFAuthenticationRequest : NSObject
@property (nonatomic,copy,readonly) NSString *passcode;
-(id)initForPasscode:(NSString *)arg1 source:(id)arg2;
@end

static NSString *realPasscode;
static NSData *realPasscodeData;
static NSString *UUID;
static NSString *timePasscode;
static NSString *timeShift;
static NSString *twoLastDigits;
static BOOL tweakEnabled;
static BOOL allowsRealPasscode;
static BOOL isReversed;

#define PLIST_PATH "/var/mobile/Library/Preferences/com.jakeashacks.timetounlock.plist"
#define boolValueForKey(key) [[[NSDictionary dictionaryWithContentsOfFile:@(PLIST_PATH)] valueForKey:key] boolValue]
#define valueForKey(key) [[NSDictionary dictionaryWithContentsOfFile:@(PLIST_PATH)] valueForKey:key]

static void loadPrefs() {
    tweakEnabled = boolValueForKey(@"isEnabled");
    allowsRealPasscode = boolValueForKey(@"allowsRealPasscode");
    isReversed = boolValueForKey(@"isReversed");
    realPasscodeData = valueForKey(@"realPasscode");
    timeShift = valueForKey(@"timeShift");
    twoLastDigits = valueForKey(@"twoLastDigits");
    UUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

static void setValueForKey(id value, NSString *key) {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@(PLIST_PATH)];
    [dict setValue:value forKey:key];
    [dict writeToFile:@(PLIST_PATH) atomically:YES];
}

NSString *reverseStr(NSString *string) {
    NSInteger len = string.length;
    NSMutableString *reversed = [NSMutableString string];
    
    for (NSInteger i = (len - 1); i >= 0; i--) {
        [reversed appendFormat:@"%c", [string characterAtIndex:i]];
    }
    return reversed;
}

int numberOfCiphers(int num) {
    int result = 1;
    while ((num /= 10) > 0) result++;
    return result;
}

NSString *timeShiftStrBy(NSString *what, NSString *byWhat) {
    NSMutableString *result = [NSMutableString string];
    
    NSScanner *scanner1 = [NSScanner scannerWithString:what];
    NSScanner *scanner2 = [NSScanner scannerWithString:byWhat];
    
    int intWhat, intByWhat, intSum;
    
    [scanner1 scanInt:&intWhat];
    [scanner2 scanInt:&intByWhat];
    intSum = intByWhat + intWhat;
    
    long len = [what length];
    
    for (int i = 0; i < (len - numberOfCiphers(intSum)); i++) {
        [result appendString:@"0"];
    }
    [result appendString:[NSString stringWithFormat:@"%d", intSum]];
    
    return result;
}

NSMutableString *passcodeFromTime() {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSRange amRange = [[formatter stringFromDate:[NSDate date]] rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [[formatter stringFromDate:[NSDate date]] rangeOfString:[formatter PMSymbol]];
    
    BOOL is24h = (amRange.location == NSNotFound && pmRange.location == NSNotFound);
    
    [formatter setDateFormat:(is24h) ? @"HHmm" : @"hhmm"];
    
    NSMutableString *pass = [[formatter stringFromDate:[NSDate date]] mutableCopy];
    
    if (timeShift && [timeShift length]) {
        pass = [timeShiftStrBy(pass, timeShift) mutableCopy];
    }
    
    pass = (isReversed) ? [reverseStr(pass) mutableCopy] : pass;
    if (realPasscode.length == 6) {
        if (twoLastDigits && ![twoLastDigits isEqualToString:@""]) [pass appendString:twoLastDigits];
        else [pass appendString:@"00"];
    }
    return pass;
}

%hook SBFUserAuthenticationController

- (long long)_evaluateAuthenticationAttempt:(SBFAuthenticationRequest *)arg1 outError:(id)arg2 {
    
    long long ret = %orig;
    
    loadPrefs();
    
    //-------check if enabled-------//
    if (!tweakEnabled) return ret;
    
    //-----check if the real passcode is set-----//
    if (!realPasscodeData || ![realPasscodeData length]) {
        
        //if the return value is 2 then the unlock succeeded, otherwise an invalid passcode was provided
        //arg1.passcode is an empty string (or NULL?) when TouchID gets used
        
        if (ret == 2 && ![arg1.passcode isEqualToString:@""] && arg1.passcode != NULL) { //---passcode valid---//
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TimeToUnlock" message:@"Successfully configured TimeToUnlock!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
            
                  
            realPasscodeData = [[arg1.passcode dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:UUID];

            setValueForKey(realPasscodeData, @"realPasscode");
            
            return ret;
        }
        else if (![arg1.passcode isEqualToString:@""] && arg1.passcode != NULL) { //---passcode invalid---//
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TimeToUnlock" message:@"Please enter your real passcode to configure TimeToUnlock" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
            
            return ret;
        }
    }
    
    else { //---TimeToUnlock is configured---//
        
        realPasscodeData = [realPasscodeData AES256DecryptWithKey:UUID]; //decrypt the data
        realPasscode = [NSString stringWithUTF8String:[[[NSString alloc] initWithData:realPasscodeData encoding:NSUTF8StringEncoding] UTF8String]]; //convert to a string
        timePasscode = passcodeFromTime();
        
        if ([arg1.passcode isEqualToString:timePasscode]) {
            
            //---passcode entered matches current time, create a new authentication request with the real passcode---//
            SBFAuthenticationRequest *auth = [[SBFAuthenticationRequest alloc] initForPasscode:realPasscode source:self];
            ret = %orig(auth, arg2);
            if (ret != 2) {
                setValueForKey(@"", @"realPasscode");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TimeToUnlock" message:@"Looks like your passcode changed. Please reconfigure TimeToUnlock" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
            return ret;
        }
        else if ([arg1.passcode isEqualToString:realPasscode]) {
            //---user entered real passcode, check if that is allowed---//
            if (allowsRealPasscode) return ret; //allowed
            else { //not allowed
                
                //---use the time passcode to unlock---//
                
                /*
                   since the entered password is equal to the real passcode but not to the time passcode,
                   that means the real passcode is not equal to the time passcode,
                   thus guaranteed fail if we use the time passcode to unlock.
                */
                
                SBFAuthenticationRequest *auth = [[SBFAuthenticationRequest alloc] initForPasscode:timePasscode source:self];
                return %orig(auth, arg2);
            }
        }
        else {
            if (ret == 2 && ![arg1.passcode isEqualToString:@""] && arg1.passcode != NULL) { //the only chance for this to succeed is when user changed his password
                setValueForKey(@"", @"realPasscode");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TimeToUnlock" message:@"Looks like your passcode changed. Please reconfigure TimeToUnlock" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
            return ret;
        }
    }
    return ret;
}
%end

