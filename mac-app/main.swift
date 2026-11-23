import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let windowRect = NSRect(x: screen.width * 0.1, y: screen.height * 0.1,
                                 width: screen.width * 0.8, height: screen.height * 0.8)
        
        window = NSWindow(contentRect: windowRect,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        window.title = "Xscout"
        window.minSize = NSSize(width: 500, height: 400)
        window.isReleasedWhenClosed = false
        
        // Find the app bundle path (dev: look relative to executable, or fallback to home)
        var appPath: String
        if let resourcePath = Bundle.main.resourcePath {
            appPath = (resourcePath as NSString).appendingPathComponent("app")
        } else {
            appPath = NSString(string: "~/Xscout").expandingTildeInPath
        }
        
        let htmlPath = (appPath as NSString).appendingPathComponent("index.html")
        
        // Configure webview
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = false
        config.preferences = preferences
        
        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.setValue(false, forKey: "drawsBackground")
        
        window.contentView?.addSubview(webView)
        
        // Load the app
        let url = URL(fileURLWithPath: htmlPath)
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        
        // Create menu bar
        createMenus()
        
        window.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func createMenus() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "About Xscout", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Xscout", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // File menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        fileMenu.addItem(NSMenuItem(title: "Reload", action: #selector(reloadPage), keyEquivalent: "r"))
        fileMenu.addItem(NSMenuItem(title: "Toggle Developer Tools", action: #selector(toggleDevTools), keyEquivalent: "d"))
        
        // View menu
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu
        viewMenu.addItem(NSMenuItem(title: "Toggle Full Screen", action: #selector(toggleFullScreen), keyEquivalent: "f"))
        viewMenu.addItem(NSMenuItem(title: "Zoom In", action: #selector(zoomIn), keyEquivalent: "+"))
        viewMenu.addItem(NSMenuItem(title: "Zoom Out", action: #selector(zoomOut), keyEquivalent: "-"))
        viewMenu.addItem(NSMenuItem(title: "Actual Size", action: #selector(actualSize), keyEquivalent: "0"))
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc func reloadPage() {
        webView.reload()
    }
    
    @objc func toggleDevTools() {
        webView.setValue(!(webView.value(forKey: "drawsBackground") as? Bool ?? false), forKey: "drawsBackground")
    }
    
    @objc func toggleFullScreen() {
        window.toggleFullScreen(nil)
    }
    
    @objc func zoomIn() {
        webView.setMagnification(webView.magnification + 0.1, centeredAt: NSPoint.zero)
    }
    
    @objc func zoomOut() {
        webView.setMagnification(webView.magnification - 0.1, centeredAt: NSPoint.zero)
    }
    
    @objc func actualSize() {
        webView.setMagnification(1.0, centeredAt: NSPoint.zero)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        window.title = "Xscout"
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
