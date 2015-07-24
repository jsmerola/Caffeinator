import Cocoa

// MARK: - Application Delegate
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate { }

// MARK: - Login Item Extension
extension NSApplication {
    
    /// Controls whether the application should start at login or not. Setting this value either adds or removes the application from the login items for the current user.
    var startAtLogin: Bool {
    get{
        return retainedLoginItem().existingReference != nil
    }
    set {
        if newValue == true {
            addToLoginItems()
        } else {
            removeFromLoginItems()
        }
    }
    }
    
    /// Adds the application to the user's login items. This method does nothing if the application is already a login item.
    /// - SeeAlso: removeFromLoginItems()
    func addToLoginItems() {
        let itemReferences = retainedLoginItem()
        if itemReferences.existingReference == nil {
            // Get the list of login items and insert a new one for this application at the end.
            let loginItemsFileList = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileListRef?
            if loginItemsFileList != nil {
                LSSharedFileListInsertItemURL(loginItemsFileList, itemReferences.lastReference, nil, nil, NSBundle.mainBundle().bundleURL, nil, nil)
            }
        }
    }
    
    /// Removes the application from the user's login items. This method does nothing if the application is not a login item.
    /// - SeeAlso: addToLoginItems()
    func removeFromLoginItems() {
        let itemReferences = retainedLoginItem()
        // Get this applications login item and remove it from the list of login items.
        if let loginItem = itemReferences.existingReference {
            if let loginItemsFileList = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileListRef? {
                LSSharedFileListItemRemove(loginItemsFileList, loginItem);
            }
        }
    }
    
    /// Gets the login item corresponding to this application.
    /// - Returns: A tuple containing two `LSSharedFileListItemRef`'s; the one corresponding to this application, and the last one in the list of login items.
    func retainedLoginItem() -> (existingReference: LSSharedFileListItemRef?, lastReference: LSSharedFileListItemRef?) {
        // Get the list of login items.
        let loginItemsFileList = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileListRef?
        if loginItemsFileList != nil {
            let loginItems = LSSharedFileListCopySnapshot(loginItemsFileList, nil).takeRetainedValue() as NSArray

            // Get a reference to the last item in the list. This is needed for inserting.
            let lastItemRef = loginItems.lastObject as! LSSharedFileListItemRef
            
            // Search for a login item for this application.
            for i in 0..<loginItems.count {
                let currentItemRef: LSSharedFileListItemRef = loginItems.objectAtIndex(i) as! LSSharedFileListItemRef
                let itemURL = LSSharedFileListItemCopyResolvedURL(currentItemRef, 0, nil).takeRetainedValue() as NSURL
                if NSBundle.mainBundle().bundleURL == itemURL {
                    return (currentItemRef, lastItemRef)
                }
            }

            // There is no login item for this application.
            return (nil, lastItemRef)
        }
        
        return (nil, nil)
    }
}