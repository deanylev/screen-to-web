const childProcess = require('child_process');
const net = require('net');

const express = require('express');
const app = express();

const httpPort = 8080;
const tcpPort = 12802;

const multipartBoundary = '08360129-1EDF-4BEF-AD94-4EFD4F3EC793';

const server = net.createServer((socket) => {
  socket.on('data', (data) => {
    responses.forEach((res) => {
      res.write(data);
    });
  });
  socket.on('close', () => {
    responses.forEach((res) => {
      res.end();
    });
  });
});
server.listen(tcpPort, () => {
  console.log('tcp listening', {
    tcpPort
  });
  const gstreamer = childProcess.spawn('gst-launch-1.0', [
    // video
    'avfvideosrc', 'capture-screen=true', 'capture-screen-cursor=true', 'device-index=1', 'do-timestamp=true', '!',
    'videorate', '!',
    'video/x-raw,framerate=10/1', '!',
    'videoscale', '!', 'video/x-raw,width=854,height=480', '!',
    'jpegenc', 'quality=65','!',
    'muxer.',
    // mux and network
    'multipartmux', `boundary=${multipartBoundary}`, 'name=muxer', '!',
    'tcpclientsink', 'host=127.0.0.1', 'sync=false', `port=${tcpPort}`
  ]);
  gstreamer.stdout.on('data', (data) => {
    console.log(data.toString());
  });

  gstreamer.stderr.on('data', (data) => {
    console.warn(data.toString());
  });
});

const responses = new Set();

app.get('/', (req, res) => {
  res.set({
    'Cache-Control': 'max-age=0, no-cache, must-revalidate',
    'Content-Type': `multipart/x-mixed-replace; boundary=${multipartBoundary}`
  });
  responses.add(res);
  res.on('close', () => {
    responses.delete(res);
  });
});

app.get('/view', (req, res) => {
  res.sendFile(`${__dirname}/view.html`);
});

app.listen(httpPort, () => {
  console.log('http listening', {
    httpPort
  });
});
