//
//  Preferences.swift
//  Caffeinator
//
//  Created by Jeff Merola on 3/21/15.
//  Copyright (c) 2015 Jeff Merola. All rights reserved.
//

import Cocoa

/// A simple wrapper around user preferences. Allows setting and getting of individual preferences.
class Preferences: NSObject {

    /// `NSUserDefaults` keys for each available preference.
    private struct CaffeinatorPreferences {
        static let ActivateOnLaunch = "info.merola.Caffeinator.ActivateOnLaunch"
        static let ShowPreferencesOnLaunch = "info.merola.Caffeinator.ShowPreferencesOnLaunch"
        static let DefaultDuration = "info.merola.Caffeinator.DefaultDuration"
    }
    
    /// Notification names that get posted on preference changes.
    struct CaffeinatorPreferenceChangeNotifications {
        static let StartAtLoginDidChange = "info.merola.Caffeinator.StartAtLoginDidChangeNotification"
        static let ActivateOnLaunchDidChange = "info.merola.Caffeinator.ActivateOnLaunchDidChangeNotification"
        static let ShowPreferencesOnLaunchDidChange = "info.merola.Caffeinator.ShowPreferencesOnLaunchDidChangeNotification"
        static let DefaultDurationDidChange = "info.merola.Caffeinator.DefaultDurationDidChangeNotification"
    }
    
    // MARK: Preference States
    
    /// Returns whether or not the application is set to start at login.
    /// - Returns: A boolean indicating whether or not to start at login.
    func shouldStartAtLogin() -> Bool {
        return NSApplication.sharedApplication().startAtLogin
    }
    
    /// Returns whether or not the application should activate on launch.
    /// - Returns: A boolean indicating whether or not to activate on launch.
    func shouldActivateOnLaunch() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(Preferences.CaffeinatorPreferences.ActivateOnLaunch)
    }
    
    /// Returns whether or not the application should display the preferences window on launch.
    /// - Returns: A boolean indicating whether or not to display the preferences window on launch.
    func shouldShowPreferencesOnLaunch() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(Preferences.CaffeinatorPreferences.ShowPreferencesOnLaunch)
    }
    
    /// Returns the default duration for the `caffeinate` task.
    /// - Returns: An int equal to the default duration for the `caffeinate` task.
    func defaultDuration() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey(Preferences.CaffeinatorPreferences.DefaultDuration)
    }
    
    /// Updates the user's preference for starting the application on login.
    /// - Parameter startAtLogin: A boolean indicating whether or not to start at login.
    func setStartAtLogin(startAtLogin: Bool) {
        NSApplication.sharedApplication().startAtLogin = startAtLogin
        NSNotificationCenter.defaultCenter().postNotificationName(CaffeinatorPreferenceChangeNotifications.StartAtLoginDidChange, object: self)
    }
    
    /// Updates the user's preference for activating the `caffeinate` task on application launch.
    /// - Parameter activate: A boolean indicating whether or not to activate on launch.
    func setShouldActivateOnLaunch(activate: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(activate, forKey:Preferences.CaffeinatorPreferences.ActivateOnLaunch)
        NSUserDefaults.standardUserDefaults().synchronize()
        NSNotificationCenter.defaultCenter().postNotificationName(CaffeinatorPreferenceChangeNotifications.ActivateOnLaunchDidChange, object: self)
    }
    
    /// Updates the user's preference for displaying the preferences window on application launch.
    /// - Parameter show: A boolean indicating whether or not to display the preferences window on application launch.
    func setShouldShowPreferencesOnLaunch(show: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(show, forKey:Preferences.CaffeinatorPreferences.ShowPreferencesOnLaunch)
        NSUserDefaults.standardUserDefaults().synchronize()
        NSNotificationCenter.defaultCenter().postNotificationName(CaffeinatorPreferenceChangeNotifications.ShowPreferencesOnLaunchDidChange, object: self)
    }
    
    /// Updates the user's preference for the default duration for the `caffeinate` task.
    /// - Parameter duration: The number of seconds to use as the default duration for the `caffeinate` task.
    /// - Note: The value passed into this method should correspond to a valid `CaffeineTimeInterval`.
    func setDefaultDuration(duration: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(duration, forKey:Preferences.CaffeinatorPreferences.DefaultDuration)
        NSUserDefaults.standardUserDefaults().synchronize()
        NSNotificationCenter.defaultCenter().postNotificationName(CaffeinatorPreferenceChangeNotifications.DefaultDurationDidChange, object: self)
    }
}
