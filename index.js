const net = require('net');

const commandLineArgs = require('command-line-args');
const express = require('express');
const app = express();

// https://xkcd.com/221/
const multipartBoundary = 'ffb88cad-a6a7-4546-8620-b1422d38919d';

const screenToTcp = require('./build/Release/screenToTcp');

const options = commandLineArgs([
  { name: 'width', type: Number, defaultValue: 1920 },
  { name: 'height', type: Number, defaultValue: 1080 },
  { name: 'framerate', type: Number, defaultValue: 30 },
  { name: 'extend', type: Boolean, defaultValue: false },
  { name: 'tcp-port', type: Number, defaultValue: 12802 },
  { name: 'http-port', type: Number, defaultValue: 8080 }
]);

const promises = [];

promises.push(new Promise((resolve, reject) => {
  const tcpServer = net.createServer((socket) => {
    console.log('tcp connection');
    resolve();

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
  tcpServer.listen(options['tcp-port'], () => {
    console.log('tcp listening', {
      port: tcpServer.address().port
    });
    screenToTcp.start(options.width, options.height, options.framerate, options.extend, options['tcp-port'], multipartBoundary);
  });
}));

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
  res.sendFile(`${__dirname}/res/view.html`);
});

promises.push(new Promise((resolve, reject) => {
  const httpServer = app.listen(options['http-port'], () => {
    const { port } = httpServer.address();
    console.log('http listening', {
      port
    });
    resolve(port);
  });
}));

Promise.all(promises).then((values) => {
  console.log(`\n✅ ready to rock! Head to http://localhost:${values[1]}/view to get started.`)
});
