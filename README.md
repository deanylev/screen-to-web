# screen-to-web
Output your Mac's screen over HTTP, using MJPEG. Written using Node.js and GStreamer.

## Prerequisites
Node.js and GStreamer installed on your system.

## Building
Clone the repo and run `yarn` to install dependencies. Run `yarn configure` and `yarn build` to build the native module. Run `yarn clean` to clean the build directory.

## Usage

```
yarn start --width 1920 --height 1080 --framerate 30 --extend --tcp-port 12802 --http-port 8080
```

Passing options is optional. If not passed, they will default to the values specified above (other than `extend`, which is `false` by default).

The resolution will not be used as is, rather it will be scaled against the target display's aspect ratio.

### Extending
Extending works by initialising a virtual display using `CGVirtualDisplay`, which is a private API. Therefore you may run into random issues, though I have yet to encounter any.

## Caveats
MJPEG does not make use of [p-frames](https://en.wikipedia.org/wiki/Video_compression_picture_types#Predicted_(P)_frames/slices) so it is very bandwidth heavy. Therefore you will likely run into performance issues over even a good network if you don't turn your resolution and framerate down.

## Why Would I Want to Use This?
It is quite useful for turning any device with a browser into a second display. This started because I wanted to see if I could use the display in my Tesla Model Y as a second display, mainly for fun.
