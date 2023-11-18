#include <iostream>

#include <AppKit/AppKit.h>
#include <CoreGraphics/CoreGraphics.h>

#include <CGVirtualDisplay.h>
#include <CGVirtualDisplayDescriptor.h>
#include <CGVirtualDisplayMode.h>
#include <CGVirtualDisplaySettings.h>

#include "virtualDisplay.h"

CGVirtualDisplay *virtualDisplay = nil;

void destroyVirtualDisplay() {
  if (virtualDisplay) {
    CFRelease(virtualDisplay);
    virtualDisplay = nil;
  }
}

int createVirtualDisplay(double width, double height) {
  destroyVirtualDisplay();

  // https://github.com/OxEv1l/FluffyDisplay/blob/03ac81a1809c0d3008d193bd3728f4a3faf31244/FluffyDisplay/VirtualDisplay.m#L25

  CGVirtualDisplaySettings *settings = [[CGVirtualDisplaySettings alloc] init];
  settings.hiDPI = false;

  CGVirtualDisplayDescriptor *descriptor = [[CGVirtualDisplayDescriptor alloc] init];
  descriptor.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
  descriptor.name = @"screen-to-web virtual display";
  descriptor.whitePoint = CGPointMake(0.3125, 0.3291);
  descriptor.bluePrimary = CGPointMake(0.1494, 0.0557);
  descriptor.greenPrimary = CGPointMake(0.2559, 0.6983);
  descriptor.redPrimary = CGPointMake(0.6797, 0.3203);
  descriptor.maxPixelsWide = width;
  descriptor.maxPixelsHigh = height;
  descriptor.sizeInMillimeters = CGSizeMake(25.4 * width / 102, 25.4 * height / 102);
  descriptor.serialNum = 0;
  descriptor.productID = 0x010F2C;
  descriptor.vendorID = 0x010F2C;

  CGVirtualDisplay *display = [[CGVirtualDisplay alloc] initWithDescriptor:descriptor];
  CGVirtualDisplayMode *mode = [[CGVirtualDisplayMode alloc] initWithWidth:width height:height refreshRate:60];
  settings.modes = @[mode];

  if (![display applySettings:settings]) {
    std::cerr << "failed to initialise virtual display" << std::endl;
    return -1;
  }

  virtualDisplay = display;
  return display.displayID;
}
