import Cocoa

/// Wrapper around a timed `caffeinate` task. 
class CaffeineTimer: NSObject {
    
    /// Available durations for the `caffeinate` task.
    enum CaffeineTimeInterval: NSTimeInterval {
        case Indefinite = 0
        case FiveMinutes = 300
        case TenMinutes = 600
        case FifteenMinutes = 900
        case ThirtyMinutes = 1800
        case OneHour = 3600
        case TwoHours = 7200
        case FiveHours = 18000
    }
    
    /// The preferences object for interacting with user preferences.
    private let preferences = Preferences()

    /// For non-indefinite `caffeinate` tasks, the date at which to terminate the task.
    private(set) var fireDate: NSDate?
    
    /// The currently set duration being used for the active `caffeinate` task, or the 
    /// default value according to the user's preferences if there is no running task.
    private(set) var scheduledTimeInterval: CaffeineTimeInterval = .Indefinite
    
    /// A bool indicating whether or not there is an active `caffeinate` task.
    var isScheduled: Bool {
        if let task = caffeinateTask {
            return task.running
        } else {
            return false
        }
    }
    
    /// The actual `caffeinate` task that keeps the computer from sleeping.
    private var caffeinateTask: NSTask?
    
    /// Closure definition for a completion block.
    typealias CaffeineCompletionBlock = ((cancelled: Bool) -> Void)?
    
    /// The completion block that gets executed when the `caffeinate` task completes.
    private var completionBlock: CaffeineCompletionBlock
    
    /// The observer object that listens for the `NSApplicationWillTerminateNotification`
    /// in order to terminate any running tasks.
    private var observer: NSObjectProtocol?
    
    /// Designated initializer for a `CaffeineTimer`. Sets initial state for the scheduled
    /// time interval and adds the observer for the `NSApplicationWillTerminateNotification`.
    override init() {
        super.init()
        resetScheduledTimeIntervalToDefaultValue()
        observer = NSNotificationCenter.defaultCenter().addObserverForName(NSApplicationWillTerminateNotification, object: nil, queue: nil) { _ in
            self.invalidate()
        }
    }

    /// Called when the `CaffeineTimer` is being deallocated. Invalidates and
    /// running `caffeinate` tasks and removes the notification observer.
    deinit {
        invalidate()
        if let observer = observer {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
            self.observer = nil
        }
    }
    
    /// Resets the scheduled time interval to the default value as specified by the user's 
    /// preferences, or .Indefinite if no specification exists.
    func resetScheduledTimeIntervalToDefaultValue() {
        let defaultTimeInterval = NSTimeInterval(preferences.defaultDuration())
        scheduledTimeInterval = CaffeineTimeInterval(rawValue: defaultTimeInterval) ?? .Indefinite
    }
    
    /// Sets the `completionBlock`, `scheduledTimeInterval`, and `fireDate` properties
    /// and spawns a new `caffeinate` task.
    /// - Parameter timeInterval: The duration to use for the `caffeinate` task.
    /// - Parameter completion: The completion block to execute once the `caffeinate` task finishes.
    func scheduleWithTimeInterval(timeInterval: CaffeineTimeInterval, completion: CaffeineCompletionBlock) {
        completionBlock = completion
        scheduledTimeInterval = timeInterval
        
        switch timeInterval {
            case .Indefinite:
                fireDate = nil
            default:
                fireDate = NSDate(timeIntervalSinceNow: timeInterval.rawValue)
        }
        
        spawnCaffeinateTask(timeInterval)
    }
    
    /// Terminates the `caffeinate` task and resets the scheduled time interval.
    func invalidate() {
        fireDate = nil
        resetScheduledTimeIntervalToDefaultValue()
        terminateCaffeinateTask()
    }
    
    /// Creates a new `caffeinate` task with the specified time interval. The task
    /// uses the `/usr/bin/caffeinate` application to keep the computer from sleeping.
    /// - Parameter timeInterval: The duration to use for the `caffeinate` task.
    private func spawnCaffeinateTask(timeInterval: CaffeineTimeInterval) {
        // -di        -> prevent the display and system from sleeping
        // -w <id>    -> waits for the process with the specifed ID to exit (in this case, the application)
        // -t <time>  -> the timeout value in seconds after which the assertion is dropped
        var arguments = ["-di", "-w \(NSProcessInfo.processInfo().processIdentifier)"]
        switch timeInterval {
            case .Indefinite:
                break
            default:
                arguments.append("-t \(timeInterval.rawValue)")
        }
        
        // Create the task using the system provided "caffeinate" application (see the caffeinate man page for details)
        caffeinateTask = NSTask.launchedTaskWithLaunchPath("/usr/bin/caffeinate", arguments: arguments)
        caffeinateTask?.terminationHandler = { _ in
            self.terminateWithForce(false)
        }
        
    }
    
    /// Terminates the caffeinate task by force.
    private func terminateCaffeinateTask() {
        caffeinateTask?.terminationHandler = nil
        caffeinateTask?.terminate()
        
        terminateWithForce(true)
    }
    
    /// Resets the `CaffeineTimer` state and calls the completion block.
    /// - Parameter forcedTermination: A bool indicating whether the 
    /// `caffeinate` task was terminated by force or whether it finished
    /// executed due to the time running out.
    private func terminateWithForce(forcedTermination: Bool) {
        caffeinateTask = nil
        resetScheduledTimeIntervalToDefaultValue()
        fireDate = nil
        
        completionBlock?(cancelled: forcedTermination)
    }
    
}
