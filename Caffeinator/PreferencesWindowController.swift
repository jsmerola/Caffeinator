import Cocoa

/// Window controller for the Caffeinator preferences window.
class PreferencesWindowController: NSWindowController {

    // MARK: - Properties
    
    /// Checkbox corresponding to the start at login preference
    @IBOutlet weak var startAtLoginOption: NSButton!
    
    /// Checkbox corresponding to the activate at application launch preference
    @IBOutlet weak var activateOnLaunchOption: NSButton!
    
    /// Checkbox corresponding to the show preferences window at application launch preference
    @IBOutlet weak var showPreferencesOnLaunchOption: NSButton!
    
    /// Dropdown listing possible default durations for the `caffeinate` task
    @IBOutlet weak var defaultDurationOption: NSPopUpButton!
    
    /// The preferences object for interacting with user preferences.
    let preferences = Preferences()
    
    // MARK: - Setup
    
    /// Called once the `PreferencesWindowController`'s window has been loaded. Sets up
    /// the UI's initial state based on values in NSUserDefaults.
    override func windowDidLoad() {
        super.windowDidLoad()
    
        startAtLoginOption.state = preferences.shouldStartAtLogin() ? NSOnState : NSOffState
        activateOnLaunchOption.state = preferences.shouldActivateOnLaunch() ? NSOnState : NSOffState
        showPreferencesOnLaunchOption.state = preferences.shouldShowPreferencesOnLaunch() ? NSOnState : NSOffState
        
        let tag = preferences.defaultDuration()
        if !defaultDurationOption.selectItemWithTag(tag) {
            defaultDurationOption.selectItemAtIndex(0)
        }
    }
    
    // MARK: - IBActions
    
    /// IBAction attached to `startAtLoginOption`.
    /// - Postcondition: Updates the user preference.
    @IBAction func updateStartAtLoginState(sender: NSButton) {
        preferences.setStartAtLogin(sender.state == NSOnState)
    }
    
    /// IBAction attached to `activateOnLaunchOption`.
    /// - Postcondition: Updates the user preference.
    @IBAction func updateActivateOnLaunchState(sender: NSButton) {
        preferences.setShouldActivateOnLaunch(sender.state == NSOnState)
    }
    
    /// IBAction attached to `showPreferencesOnLaunchOption`.
    /// - Postcondition: Updates the user preference.
    @IBAction func updateShowPreferencesAtLaunchState(sender: NSButton) {
        preferences.setShouldShowPreferencesOnLaunch(sender.state == NSOnState)
    }
    
    /// IBAction attached to `defaultDurationOption`.
    /// - Postcondition: Updates the user preference.
    @IBAction func updateDefaultDurationState(sender: NSPopUpButton) {
        preferences.setDefaultDuration(sender.selectedTag())
    }
}
