/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "GoogleAnalyticsPlugin.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

@implementation GoogleAnalyticsPlugin

- (void) close: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;

    if (!tracker) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"tracker not initialized"];
    } else {
        [[GAI sharedInstance] removeTrackerByName:[tracker name]];
        tracker = nil;
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) dispatch: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;

    [[GAI sharedInstance] dispatch];
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) get: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    NSString* key = [command.arguments objectAtIndex:0];

    if (!tracker) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"tracker not initialized"];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[tracker get:key]];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) getAdvertisingId: (CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;

        // throw error if on iOS < 6.0
        if (NSClassFromString(@"ASIdentifierManager")) {

            NSString *advertisingId = [[(id)[NSClassFromString(@"ASIdentifierManager") sharedManager] advertisingIdentifier] UUIDString];

            if (advertisingId != nil && [advertisingId length] > 0 && ![advertisingId isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:advertisingId];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            }
        }

        else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    }];
}


- (void) getAppOptOut: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;

    if ([GAI sharedInstance].optOut) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:(true)];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:(false)];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) getLimitAdTracking: (CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;

        if (NSClassFromString(@"ASIdentifierManager")) {
            // negate this because limitAdTracking = !isTrackingEnabled
            BOOL limitAdTracking = ![[NSClassFromString(@"ASIdentifierManager") sharedManager] isAdvertisingTrackingEnabled];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:limitAdTracking];

        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    }];
}


- (void) send: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    NSDictionary* params = [command.arguments objectAtIndex:0];

    if (!tracker) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"tracker not initialized"];
    } else {
        [tracker send:params];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) sendException: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    NSString* description = [command.arguments objectAtIndex:0];
    NSNumber* isFatal = [command.arguments objectAtIndex:1];

    if (!tracker) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"tracker not initialized"];
    } else {
        [tracker send:[[GAIDictionaryBuilder
                        createExceptionWithDescription:description
                        withFatal:isFatal] build]];

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) set: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    NSString* key = [command.arguments objectAtIndex:0];
    NSString* value = [command.arguments objectAtIndex:1];

    if (!tracker) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"tracker not initialized"];
    } else {
        [tracker set:key value:value];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) setAppOptOut: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    BOOL enabled = [[command.arguments objectAtIndex:0] boolValue];

    if (enabled) {
        [[GAI sharedInstance] setOptOut:YES];
    } else {
        [[GAI sharedInstance] setOptOut:NO];
    }
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) setDispatchInterval: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    NSTimeInterval dispatchInterval = [[command.arguments objectAtIndex:0] unsignedLongValue];

    [GAI sharedInstance].dispatchInterval = dispatchInterval;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) setIDFAEnabled: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    BOOL enabled = [[command.arguments objectAtIndex:0] boolValue];

    if (!tracker) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"tracker not initialized"];
    } else {
        if (enabled) {
            tracker.allowIDFACollection = YES;
        } else {
            tracker.allowIDFACollection = NO;
        }

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) setLogLevel: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;

    GAILogLevel logLevel = (GAILogLevel)[command.arguments objectAtIndex:0];

    [[[GAI sharedInstance] logger] setLogLevel:logLevel];

    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) setScreen: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    NSString* screenName = [command.arguments objectAtIndex:0];

    if (!tracker) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"tracker not initialized"];
    } else {
        [tracker set:kGAIScreenName value:screenName];
    }

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


- (void) setTrackingId: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    NSString* trackingId = [command.arguments objectAtIndex:0];

    [GAI sharedInstance].trackUncaughtExceptions = YES;

    if (tracker) {
        [[GAI sharedInstance] removeTrackerByName:[tracker name]];
    }

    tracker = [[GAI sharedInstance] trackerWithTrackingId:trackingId];
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}

@end
