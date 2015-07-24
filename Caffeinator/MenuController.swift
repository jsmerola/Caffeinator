import Cocoa

/// Controller object for the application's menu item
class MenuController: NSObject, NSMenuDelegate {
    
    // MARK: - Properties
    
    /// The NSWindowController instance for the application's preferences window.
    /// - Note: This controller is the only instance of a `PreferencesWindowController` in the application.
    private let preferencesController = {
        PreferencesWindowController(windowNibName: "PreferencesScreen")
    }()
    
    /// An `NSDateComponentsFormatter` instance used to format the time remaining string in the "Activate for..." menu option.
    private lazy var dateComponentsFormatter: NSDateComponentsFormatter = {
        var formatter = NSDateComponentsFormatter()
        formatter.allowedUnits = [.Second, .Minute, .Hour]
        formatter.unitsStyle = .Short
        formatter.includesTimeRemainingPhrase = true
        return formatter
    }()
    
    /// The instance of `CaffeineTimer` that handles running the `caffeinate` task for the application.
    private let caffeineTimer = CaffeineTimer()
    
    /// The preferences object for interacting with user preferences.
    private let preferences = Preferences()
    
    /// The actual `NSStatusItem` for the application. It is configured to have a variable width so it adjusts to the width of its contents.
    private let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    
    /// The main `NSMenu` instance for the application. Contains the "About", "Preferences", and "Quit" options, as well as the `intervalMenu` submenu.
    /// - SeeAlso: intervalMenu
    @IBOutlet weak var mainMenu: NSMenu!
    
    /// The secondary `NSMenu` instance for the application. Contains the available duration options for the caffeine timer. This menu is a submenu of the `mainMenu`.
    /// - SeeAlso: mainMenu
    @IBOutlet weak var intervalMenu: NSMenu!
    
    /// The `NSMenuItem` instance for displaying the time remaining on the `caffeinate` task.
    @IBOutlet weak var timeRemainingItem: NSMenuItem!
    
    /// The `NSTimer` instance keeping track of how long until the application's `caffeinate` task exits.
    /// Used to create the time remaining string displaying in the `timeRemainingItem` menu item.
    private var timeRemainingTimer: NSTimer?
    
    // MARK: - Setup
    
    /// Initializes a newly allocated menu controller.
    /// - Returns: An initialized `MenuController` instance.
    override init() {
        super.init()
        
        configureStatusItem()
        
        if preferences.shouldActivateOnLaunch() {
            activateTimer()
        }
        
        if preferences.shouldShowPreferencesOnLaunch() {
            preferencesController.showWindow(self)
        }
    }
    
    /// Configures `statusItem`'s `NSStatusBarButton`, if it exists.
    func configureStatusItem() {
        if let button = statusItem.button {
            button.target = self
            button.action = Selector("toggleStatus:")
            button.sendActionOn(Int(NSEventMask.LeftMouseUpMask.rawValue))
            
            setStatusItemActive(false)
        }
    }
    
    /// This method updates the `statusItem`'s button state to use the active/inactive images and to set whether the button appears disabled.
    /// - Parameter active: Specifies whether the button should display the active or inactive state.
    func setStatusItemActive(active: Bool) {
        if let button = statusItem.button {
            if active {
                button.image = NSImage(named: "Active")
                button.appearsDisabled = false
            } else {
                button.image = NSImage(named: "Inactive")
                button.appearsDisabled = true
            }
        }
    }
    
    // MARK: - Timer Management
    
    /// Toggles the inactive/active state. Inactive aborts the `caffeinate` task while active creates a new one with the default duration.
    func toggleStatus(_: AnyObject?) {
        // If the user clicked on the menu bar icon with the command (⌘) key pressed
        if let event = NSApplication.sharedApplication().currentEvent where event.modifierFlags.intersect(.CommandKeyMask) != [] {
//            if event.modifierFlags.intersect(.CommandKeyMask) != [] {
                showMenu(nil)
                return
//            }
        }
        
        if caffeineTimer.isScheduled {
            terminateTimer()
        } else {
            activateTimer()
        }
    }

    /// Activates the caffeine timer with the default duration specified in NSUserDefaults (or `.Indefinite` if not specified).
    func activateTimer() {
        if let interval = CaffeineTimer.CaffeineTimeInterval(rawValue: NSTimeInterval(preferences.defaultDuration())) {
            activateTimerWithTimeInterval(interval)
        } else {
            activateTimerWithTimeInterval(.Indefinite)
        }
    }
    
    /// Activates the caffeine timer with the specified duration.
    /// - Note: This method first invalidates any running timers.
    /// - Parameter interval: The `CaffeineTimeInterval` to activate the timer with.
    func activateTimerWithTimeInterval(interval: CaffeineTimer.CaffeineTimeInterval) {
        // Invalidate any running timer and create a new one, adding it to a run loop
        timeRemainingTimer?.invalidate()
        timeRemainingTimer = NSTimer(timeInterval: 0.5, target: self, selector: "updateTimeRemaining", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timeRemainingTimer!, forMode: NSRunLoopCommonModes)
        
        setStatusItemActive(true)
        caffeineTimer.scheduleWithTimeInterval(interval, completion: { (cancelled) -> Void in
            self.setStatusItemActive(false)
        })
    }
    
    /// Terminates the currently running timer and sets the status item to inactive.
    func terminateTimer() {
        timeRemainingTimer?.invalidate()
        
        setStatusItemActive(false)
        caffeineTimer.invalidate()
    }
    
    /// `NSTimer` fire method. Called once every 0.5 seconds. Updates the time remaining string in the menu.
    func updateTimeRemaining() {
        if !timeRemainingItem.hidden, let fireDate = caffeineTimer.fireDate {
            timeRemainingItem.title = dateComponentsFormatter.stringFromDate(NSDate(), toDate: fireDate)!
        }
    }
    
    // MARK: - Menu Item Actions
    
    /// Displays the main menu in the menu bar.
    /// - Parameter sender: The object sending the message.
    func showMenu(sender: AnyObject!) {
        statusItem.popUpStatusItemMenu(mainMenu)
    }
    
    /// Activates the application and displays the preferences window.
    /// - Parameter sender: The `NSMenuItem` sending the message.
    @IBAction func showPreferences(sender: NSMenuItem) {
        NSApp.activateIgnoringOtherApps(true)
        preferencesController.showWindow(self)
    }
    
    /// Activate the application and displays the about pane.
    /// - Parameter sender: The `NSMenuItem` sending the message.
    @IBAction func showAbout(sender: NSMenuItem) {
        let aboutString = NSAttributedString(string: "Prevent your Mac from going to sleep and displaying the screen saver.", attributes: [ NSFontAttributeName: NSFont.systemFontOfSize(11) ])
        let options = [ "Credits": aboutString , "Version": ""]
        
        NSApp.activateIgnoringOtherApps(true)
        NSApp.orderFrontStandardAboutPanelWithOptions(options)
    }
    
    /// The IBAction for choosing a time interval from the menu.
    /// - Note: The menu items corresponding to time intervals must have tags
    /// that are set to the number of seconds for that interval (or 0 for infinity).
    /// - Parameter sender: The `NSMenuItem` sending the message.
    @IBAction func selectTimeInterval(sender: NSMenuItem) {
        if caffeineTimer.isScheduled {
            caffeineTimer.invalidate()
        }
        
        // Attempt to activate the timer with the specified time interval. 
        // If that fails, use the default specified in the user preferences. 
        // If that fails, use indefinite.
        let timeInterval = NSTimeInterval(sender.tag)
        if let caffeineTimeInterval = CaffeineTimer.CaffeineTimeInterval(rawValue: timeInterval) {
            activateTimerWithTimeInterval(caffeineTimeInterval)
        } else {
            let defaultDuration = preferences.defaultDuration()
            if let caffeineTimeInterval = CaffeineTimer.CaffeineTimeInterval(rawValue: NSTimeInterval(defaultDuration)) {
                activateTimerWithTimeInterval(caffeineTimeInterval)
            } else {
                activateTimerWithTimeInterval(.Indefinite)
            }
        }
    }
    
    /// Terminates any running `caffeinate` tasks and quits the application.
    /// - Parameter sender: The `NSMenuItem` sending the message.
    @IBAction func quit(sender: NSMenuItem) {
        caffeineTimer.invalidate()
        NSApplication.sharedApplication().terminate(self)
    }
    
    // MARK: - NSMenuDelegate
    
    /// Called when the specified menu is about to be displayed. Used to
    /// update the time remaining label and the on/off state for the time
    /// interval menu items.
    /// - Parameter menu: The menu about to be displayed.
    func menuNeedsUpdate(menu: NSMenu) {
        if menu != intervalMenu {
            return
        }
        
        for menuItem in menu.itemArray as [NSMenuItem] {
            menuItem.state = NSOffState
            
            let menuItemInterval = NSTimeInterval(menuItem.tag)
            if menuItemInterval > 0 {
                // One of the duration options (not indefinite)
                if caffeineTimer.isScheduled && caffeineTimer.scheduledTimeInterval.rawValue == menuItemInterval {
                    menuItem.state = NSOnState
                }
            } else if menuItemInterval == 0 && !menuItem.separatorItem {
                // The indefinite duration option
                if caffeineTimer.isScheduled && caffeineTimer.scheduledTimeInterval == .Indefinite {
                    menuItem.state = NSOnState
                }
            } else {
                // The time remaining menu item
                menuItem.hidden = true
                if let fireDate = caffeineTimer.fireDate {
                    menuItem.hidden = false
                    menuItem.title = dateComponentsFormatter.stringFromDate(NSDate(), toDate: fireDate)!
                }
            }
        }
    }
}
