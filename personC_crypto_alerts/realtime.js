let ioInstance = null;

function init(server) {
  const { Server } = require('socket.io');
  const io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    }
  });
  io.on('connection', socket => {
    console.log('socket connected', socket.id);
    socket.on('hello', data => {
      console.log('hello from client', data);
    });
    socket.on('disconnect', () => {
      console.log('socket disconnected', socket.id);
    });
  });
  ioInstance = io;
  return io;
}

function getIo() {
  return ioInstance;
}

module.exports = { init, getIo };
