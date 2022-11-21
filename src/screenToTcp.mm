#include <iostream>
#include <string>

#include <napi.h>

#include <AppKit/AppKit.h>

#include <gst/gst.h>

#include "virtualDisplay.h"

GstElement *vpipeline = nullptr;
GstElement *vsrc = nullptr;
GstElement *vrate = nullptr;
GstElement *vrateCaps = nullptr;
GstElement *vscale = nullptr;
GstElement *vscaleCaps = nullptr;
GstElement *venc = nullptr;
GstElement *vmux = nullptr;
GstElement *vsink = nullptr;

struct Destination {
  gint index;
  guint width;
  guint height;
};

// scale our target resolution against our physical aspect ratio
Destination calculateDestination(gint displayId, guint targetWidth, guint targetHeight) {
  Destination defaultDestination = {
    .index = -1,
    .width = targetWidth,
    .height = targetHeight
  };
  gint index = -1;
  double calculatedWidth;
  double calculatedHeight;

  const NSArray * screens = [NSScreen screens];
  const NSUInteger length = [screens count];
  for (NSUInteger i = 0; i < length; i++) {
    const NSDictionary * description = [screens[i] deviceDescription];
    const CGDirectDisplayID deviceId = [[description objectForKey:@"NSScreenNumber"] unsignedIntegerValue];

    if (static_cast<gint>(deviceId) == displayId) {
      const CGDisplayModeRef displayMode = CGDisplayCopyDisplayMode(deviceId);
      if (displayMode == nullptr) {
        std::cerr << "null displayMode, using default destination" << std::endl;
        return defaultDestination;
      }

      index = static_cast<gint>(i);
      calculatedWidth = static_cast<double>(CGDisplayModeGetPixelWidth(displayMode));
      calculatedHeight = static_cast<double>(CGDisplayModeGetPixelHeight(displayMode));

      CGDisplayModeRelease(displayMode);
    }
  }

  if (index == -1) {
    return defaultDestination;
  }

  const double calculatedRatio = calculatedWidth / calculatedHeight;
  const double targetRatio = targetWidth / targetHeight;
  if (calculatedWidth > targetWidth || calculatedHeight > targetHeight) {
    if (calculatedRatio > targetRatio) {
      // too wide
      calculatedHeight *= targetWidth / calculatedWidth;
      calculatedWidth = targetWidth;
    } else {
      // too tall
      calculatedWidth *= targetHeight / calculatedHeight;
      calculatedHeight = targetHeight;
    }
  }

  const Destination destination = {
    .index = index,
    .width = static_cast<guint>(calculatedWidth) / 2 * 2,
    .height = static_cast<guint>(calculatedHeight) / 2 * 2
  };
  return destination;
}

Napi::Value start(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();

  Napi::Object ret = Napi::Object::New(env);
  ret["width"] = 0;
  ret["height"] = 0;
  ret["screenWidth"] = 0;
  ret["screenHeight"] = 0;
  ret["screenX"] = 0;
  ret["screenY"] = 0;

  if (info.Length() < 6 || !info[0].IsNumber() || !info[1].IsNumber() || !info[2].IsNumber() || !info[3].IsBoolean() || !info[4].IsNumber() || !info[5].IsString()) {
    Napi::TypeError::New(env, "Wrong arguments").ThrowAsJavaScriptException();
    return ret;
  }

  const guint width = info[0].As<Napi::Number>().Uint32Value();
  const guint height = info[1].As<Napi::Number>().Uint32Value();
  const guint framerate = info[2].As<Napi::Number>().Uint32Value();
  const bool extend = info[3].As<Napi::Boolean>().Value();
  const guint port = info[4].As<Napi::Number>().Uint32Value();
  const std::string multipartBoundary(info[5].As<Napi::String>());

  gint displayId = CGMainDisplayID();
  if (extend) {
    gint virtualDisplayId = createVirtualDisplay();
    if (virtualDisplayId != -1) {
      displayId = virtualDisplayId;
    }
  }

  auto destination = calculateDestination(displayId, width, height);
  std::cout << "display id: " << displayId << std::endl;
  std::cout << "display index: " << destination.index << std::endl;
  std::cout << "width: " << destination.width << std::endl;
  std::cout << "height: " << destination.height << std::endl;

  if (vpipeline != nullptr) {
    gst_element_set_state(vpipeline, GST_STATE_NULL);
    gst_object_unref(vpipeline);
    vpipeline = nullptr;
  }

  vpipeline = gst_pipeline_new("vpipeline");

  vsrc = gst_element_factory_make("avfvideosrc", "vsrc");
  vrate = gst_element_factory_make("videorate", "vrate");
  vrateCaps = gst_element_factory_make("capsfilter", "vrateCaps");
  vscale = gst_element_factory_make("videoscale", "vscale");
  vscaleCaps = gst_element_factory_make("capsfilter", "vscaleCaps");
  venc = gst_element_factory_make("jpegenc", "venc");
  vmux = gst_element_factory_make("multipartmux", "vmux");
  vsink = gst_element_factory_make("tcpclientsink", "vsink");

  g_object_set(vsrc,
      "capture-screen", TRUE,
      "capture-screen-cursor", TRUE,
      "device-index", destination.index,
      nullptr);

  g_object_set(venc,
      "quality", 65,
      nullptr);

  g_object_set(vmux,
      "boundary", multipartBoundary.c_str(),
      nullptr);

  g_object_set(vsink,
      "host", "127.0.0.1",
      "port", port,
      "sync", FALSE,
      nullptr);

  GstCaps* caps;

  caps = gst_caps_new_simple("video/x-raw",
      "framerate", GST_TYPE_FRACTION, framerate, 1,
      nullptr);
  g_object_set(vrateCaps,
      "caps", caps,
      nullptr);
  gst_caps_unref(caps);

  caps = gst_caps_new_simple("video/x-raw",
      "width", G_TYPE_INT, destination.width,
      "height", G_TYPE_INT, destination.height,
      nullptr);
  g_object_set(vscaleCaps,
      "caps", caps,
      nullptr);
  gst_caps_unref(caps);

  gst_bin_add_many(GST_BIN(vpipeline),
      vsrc,
      vrate,
      vrateCaps,
      vscale,
      vscaleCaps,
      venc,
      vmux,
      vsink,
      nullptr);

  gst_element_link_many(
      vsrc,
      vrate,
      vrateCaps,
      vscale,
      vscaleCaps,
      venc,
      vmux,
      vsink,
      nullptr);

  gst_element_set_state(vpipeline, GST_STATE_PLAYING);

  ret["width"] = destination.width;
  ret["height"] = destination.height;

  CGRect screenBounds = CGDisplayBounds(displayId);
  ret["screenWidth"] = screenBounds.size.width;
  ret["screenHeight"] = screenBounds.size.height;
  ret["screenX"] = screenBounds.origin.x;
  ret["screenY"] = screenBounds.origin.y;

  return ret;
}

Napi::Object init(Napi::Env env, Napi::Object exports) {
  if (!gst_is_initialized()) {
    gst_init(nullptr, nullptr);
  }

  exports["start"] = Napi::Function::New(env, start);

  return exports;
}

NODE_API_MODULE(NODE_GYP_MODULE_NAME, init)
