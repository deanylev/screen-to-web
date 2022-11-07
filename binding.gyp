{
  "conditions": [
    ["target_arch == 'arm64'", {
      "variables": {
        "gstreamer_sdk_root": "/Library/Frameworks/GStreamer.framework/Versions/1.0/arm64"
      }
    }],
    ["target_arch == 'x64'", {
      "variables": {
        "gstreamer_sdk_root": "/Library/Frameworks/GStreamer.framework/Versions/1.0/x64"
      }
    }],
  ],
  "target_defaults": {
    "defines": [
      "NAPI_DISABLE_CPP_EXCEPTIONS",
      "NODE_GYP_OS=>(OS)"
    ],
    "include_dirs": [
      "<!(node -p \"require('node-addon-api').include_dir\")"
    ]
  },
  "targets": [
    {
      "target_name": "screenToTcp",
      "sources": [
        "src/virtualDisplay.mm",
        "src/screenToTcp.mm"
      ],
      "libraries": [
        "<(gstreamer_sdk_root)/lib/gstreamer-1.0/libgstcoreelements.a",
        "<(gstreamer_sdk_root)/lib/gstreamer-1.0/libgstjpeg.a",
        "<(gstreamer_sdk_root)/lib/gstreamer-1.0/libgstmultipart.a",
        "<(gstreamer_sdk_root)/lib/gstreamer-1.0/libgsttcp.a",
        "<(gstreamer_sdk_root)/lib/gstreamer-1.0/libgstvideorate.a",
        "<(gstreamer_sdk_root)/lib/gstreamer-1.0/libgstvideoscale.a",
        "<(gstreamer_sdk_root)/lib/gstreamer-1.0/libgstapplemedia.a",
        "<(gstreamer_sdk_root)/lib/libffi.a",
        "<(gstreamer_sdk_root)/lib/libjpeg.a",
        "<(gstreamer_sdk_root)/lib/libgio-2.0.a",
        "<(gstreamer_sdk_root)/lib/libglib-2.0.a",
        "<(gstreamer_sdk_root)/lib/libgmodule-2.0.a",
        "<(gstreamer_sdk_root)/lib/libgobject-2.0.a",
        "<(gstreamer_sdk_root)/lib/libgstaudio-1.0.a",
        "<(gstreamer_sdk_root)/lib/libgstbase-1.0.a",
        "<(gstreamer_sdk_root)/lib/libgstcontroller-1.0.a",
        "<(gstreamer_sdk_root)/lib/libgstnet-1.0.a",
        "<(gstreamer_sdk_root)/lib/libgstreamer-1.0.a",
        "<(gstreamer_sdk_root)/lib/libgstvideo-1.0.a",
        "<(gstreamer_sdk_root)/lib/libintl.a",
        "<(gstreamer_sdk_root)/lib/liborc-0.4.a",
        "-framework CoreFoundation"
      ],
      "include_dirs": [
        "<(gstreamer_sdk_root)/include",
        "<(gstreamer_sdk_root)/include/glib-2.0",
        "<(gstreamer_sdk_root)/include/gstreamer-1.0",
        "<(gstreamer_sdk_root)/lib/glib-2.0/include",
        "src/include"
      ],
      "cflags+": ["-fvisibility=hidden"],
      "xcode_settings": {
        "CLANG_CXX_LANGUAGE_STANDARD": "c++17",
        "GCC_SYMBOLS_PRIVATE_EXTERN": "YES",
        "OTHER_LDFLAGS": [
          "-framework AppKit",
          "-framework AVFoundation",
        ]
      }
    }
  ]
}
