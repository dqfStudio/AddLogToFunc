//
//  AddLogToFunc.h
//  AddLogToFunc
//
//  Created by dqf on 2017/6/19.
//  Copyright © 2017年 DNE Technology Co.,Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "AddLogToFunc.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (IBAction)openFile:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if(result == 0)
            return ;
        
       NSString * path = [panel.URL path];
       self.textVIew.string = [AddLogToFunc openWithPath:path];
    }];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
@end
