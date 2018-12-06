//
//  PushNotificationsApp
//
//  (c) Pushwoosh 2014
//

#import "AppDelegate.h"
#import <Pushwoosh/PushNotificationManager.h>
#import <UserNotifications/UserNotifications.h>


@implementation AppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	// Override point for customization after application launch.
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];

	self.window.rootViewController = self.viewController;
	[self.window makeKeyAndVisible];

	//-----------PUSHWOOSH PART-----------

	// set custom delegate for push handling, in our case - view controller
	[PushNotificationManager pushManager].delegate = self.viewController;
	
	// set default Pushwoosh delegate for iOS10 foreground push handling
	[UNUserNotificationCenter currentNotificationCenter].delegate = [PushNotificationManager pushManager].notificationCenterDelegate;

	// make sure we count app open in Pushwoosh stats
	[[PushNotificationManager pushManager] sendAppOpen];

	// register for push notifications!
	[[PushNotificationManager pushManager] registerForPushNotifications];

	// check launch notification (optional)
	NSDictionary *launchNotification = [PushNotificationManager pushManager].launchNotification;
	if (launchNotification) {
		NSError *error;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:launchNotification
														   options:NSJSONWritingPrettyPrinted
															 error:&error];
		
		if (!jsonData) {
			NSLog(@"Got an error: %@", error);
		} else {
			NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
			NSLog(@"Received launch notification with data: %@", jsonString);
		}
	}
	else {
		NSLog(@"No launch notification");
	}

	return YES;
}

// system push notification registration success callback, delegate to pushManager
- (void)application:(UIApplication *)application
	didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[[PushNotificationManager pushManager] handlePushRegistration:deviceToken];
}

// system push notification registration error callback, delegate to pushManager
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	[[PushNotificationManager pushManager] handlePushRegistrationFailure:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    //get custom data from push notification
    NSDictionary *userdata = [[PushNotificationManager pushManager] getCustomPushDataAsNSDict:userInfo];
    
    //check if this is deletable push (check user info for key "dlt":dict)
    //if this is not null - the dict is the deletable push
    NSString * dltPushId = [userdata objectForKey:@"dlt"];
    
    if(dltPushId) {
        //if push is to delete notification "dlt":string"
        //load notif and delete
        NSString * pushNotificationId = [NSString stringWithFormat:@"com.pushwoosh.notification.%@", dltPushId];
        
        if(pushNotificationId) {
            [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[pushNotificationId]];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:pushNotificationId];
            completionHandler(UIBackgroundFetchResultNewData);
            return;
        }
        
        NSLog(@"Push notification fetch :%@", userInfo);
    }
    
    //should we create new push notification
    NSString * createPushId = [userdata objectForKey:@"crt"];
    
    if(createPushId) {
        //create local notification of the push
        //save it
        
        //we don't need to care about sound or badge as this would be handled already by iOS itself
        UNMutableNotificationContent *content = [UNMutableNotificationContent new];
        content.title = [userdata objectForKey:@"title"];
        content.userInfo = userInfo;
        
        NSString * pushNotificationId = [NSString stringWithFormat:@"com.pushwoosh.notification.%@", createPushId];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:pushNotificationId content:content trigger:nil];
        
        //present notification now
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (!error) {
                [[NSUserDefaults standardUserDefaults] setObject:pushNotificationId forKey:pushNotificationId];
            }
        }];
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSLog(@"%@", response.notification);
}

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		 forRemoteNotification:(NSDictionary *)notification
  completionHandler:(void (^)(void))completionHandler {
	if ([identifier isEqualToString:@"ACCEPT_IDENTIFIER"]) {
	}

	// Must be called when finished
	completionHandler();
}

+ (AppDelegate *)sharedDelegate {
	return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attempting to open URL"
													message:[NSString stringWithFormat:
															 @"Url - %@", url]
												   delegate:self cancelButtonTitle:@"Ok"
										  otherButtonTitles:nil];
	[alert show];
	
	return YES;
}

@end
