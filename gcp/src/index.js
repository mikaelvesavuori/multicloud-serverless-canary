const express = require('express');
const app = express();
const port = process.env.PORT || 80;

app.get('/', (req, res) => res.send('Hello World!'));

app.get('/throw', (req, res) => {
  throw new Error("SERVER: Throwing error!");
});

app.get('/error', (req, res) => {
  console.error('SERVER: Error!');
  res.status(500).send('SERVER: Error!');
});

app.get('/warn', (req, res) => {
  console.warn('SERVER: Warning!');
  res.status(500).send('SERVER: Warning!')
});

app.listen(port, () => console.log(`Example app listening at http://localhost:${port}`));

module.exports = { app };