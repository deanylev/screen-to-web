const net = require('net');
const os = require('os');

const commandLineArgs = require('command-line-args');
const express = require('express');
const robot = require('robotjs');

const app = express();
app.use(express.json());

// https://xkcd.com/221/
const multipartBoundary = 'ffb88cad-a6a7-4546-8620-b1422d38919d';

const screenToTcp = require('./build/Release/screenToTcp');

const options = commandLineArgs([
  { name: 'width', type: Number, defaultValue: 1920 },
  { name: 'height', type: Number, defaultValue: 1080 },
  { name: 'framerate', type: Number, defaultValue: 30 },
  { name: 'quality', type: Number, defaultValue: 65 },
  { name: 'extend', type: Boolean, defaultValue: false },
  { name: 'extend-width', type: Number, defaultValue: 1920 },
  { name: 'extend-height', type: Number, defaultValue: 1080 },
  { name: 'allow-input', type: Boolean, defaultValue: false },
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

    const { screenWidth, screenHeight, screenX, screenY, width, height } = screenToTcp.start(options.width, options.height, options.framerate, options.quality, options.extend, options['extend-width'], options['extend-height'], options['tcp-port'], multipartBoundary);
    const scaleCoordinates = (x, y) => {
      return {
        x: x / width * screenWidth + screenX,
        y: y / height * screenHeight + screenY
      };
    };

    if (options['allow-input']) {
      app.post('/move', (req, res) => {
        const { x, y, down } = req.body;
        if (typeof x !== 'number' || typeof y !== 'number' || typeof down !== 'boolean') {
          res.sendStatus(400);
          return;
        }

        const scaled = scaleCoordinates(x, y);

        if (down) {
          robot.dragMouse(scaled.x, scaled.y);
        } else {
          robot.moveMouse(scaled.x, scaled.y);
        }
        res.sendStatus(204);
      });

      app.post('/click', (req, res) => {
        const { x, y, down, right } = req.body;
        if (typeof down !== 'boolean' || typeof right !== 'boolean') {
          res.sendStatus(400);
          return;
        }

        if (typeof x === 'number' && typeof y === 'number') {
          const scaled = scaleCoordinates(x, y);
          robot.moveMouse(scaled.x, scaled.y);
        }

        robot.mouseToggle(down ? 'down' : 'up', right ? 'right' : 'left');
        res.sendStatus(204);
      });
    }
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
  const port = values[1];
  const networkInterfaces = os.networkInterfaces();
  const ips = Object.values(networkInterfaces)
    .flat()
    .filter(({ family, internal }) => !internal && family === 'IPv4')
    .map(({ address }) => address);

  const urls = ['localhost', ...ips].map((ip) => `http://${ip}:${port}/view`);
  console.log(`\n✅ ready to rock! Get started at:\n\n${urls.join('\n')}`);
});
