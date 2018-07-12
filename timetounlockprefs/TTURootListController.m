#include "TTURootListController.h"

@implementation TTURootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/private/var/mobile/Library/Preferences/%@.plist", [specifier properties][@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	return (settings[[specifier properties][@"key"]]) ?: [specifier properties][@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {

      if ([[specifier properties][@"key"] isEqualToString:@"timeShift"]) {

            NSScanner *scanner = [NSScanner scannerWithString:value];
            int i;
            BOOL isNum = [scanner scanInt:&i] && [scanner isAtEnd];

            if (!isNum && [value length]) {
                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message: @"Time shift value must be positive or negative integer"
                                                    delegate:self 
                                                    cancelButtonTitle:@"OK" 
                                                    otherButtonTitles:nil];
                  [alert show];
                  [alert release];
                  return;      
            }
      }

      if ([[specifier properties][@"key"] isEqualToString:@"twoLastDigits"]) {
       
            NSScanner *scanner = [NSScanner scannerWithString:value];
            int i;
            BOOL isNum = [scanner scanInt:&i] && [scanner isAtEnd];

            if ((!isNum || i < 0) && [value length]) {
                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message: @"Two last digits must be positive numbers"
                                                    delegate:self 
                                                    cancelButtonTitle:@"OK" 
                                                    otherButtonTitles:nil];
                  [alert show];
                  [alert release];
                  return;      
            }
            if ([value length] != 2 && [value length]) {
                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message: @"Only enter 2 digits please"
                                                    delegate:self 
                                                    cancelButtonTitle:@"OK" 
                                                    otherButtonTitles:nil];
                  [alert show];
                  [alert release];
                  return;
            }
      }
	NSString *path = [NSString stringWithFormat:@"/private/var/mobile/Library/Preferences/%@.plist", [specifier properties][@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	[settings setObject:value forKey: [specifier properties][@"key"]];
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (CFStringRef)[specifier properties][@"PostNotification"];
	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
}

- (void)myTwitter:(id)arg1 {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=Jakeashacks"]];
    else [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/Jakeashacks"]];
}

-(void)sourceCode:(id)arg1 {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/jakeajames/TimeToUnlock"]];
}

-(void)resetSettings:(id)arg1 {
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.jakeashacks.timetounlock.plist" error:nil];
    [self reloadSpecifiers];
}

@end
