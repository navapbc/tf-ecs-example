'use strict';

const express = require('express');

// Constants
const PORT = 3000;
const HOST = '0.0.0.0';

// App
const app = express();
app.get('/', (req, res) => {
  res.send('Hello world\n');
});

// this demonstrates fetching environment variables
// only the length of the value is shown.
app.get('/env/:envVar', (req, res) => {
  let envVar = req.params.envVar;
  let envVal = process.env[envVar];
  if (envVal) {
    res.send(envVar + ' length is: ' + envVal.length + '\n');
  } else {
    res.send(envVar + ' not found!\n');
  }
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
