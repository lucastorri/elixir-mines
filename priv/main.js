
var commands = {
  newGame: function() { return 'n'; },
  flag: function(i, j) { return 'f ' + i + ' ' + j; },
  sweep: function(i, j) { return 's ' + i + ' ' + j; },
  continue: function(gameId) { return 'c ' + gameId; }
};

function update(res, ws) {
  var colors = [];

  var game = res.state;
  var msg = res.msg !== "nil" && res.msg || "";

  var gameElement = $('#game')
  var finished = parseBoolean(game.lost) || parseBoolean(game.won);

  if (!game) {
    return gameElement.empty();
  }

  var source = $("#game-template").html();
  var template = Handlebars.compile(source);

  var model = {
    msg: parseBoolean(game.won) ? 'YOU WIN!' : (parseBoolean(game.lost) ? 'YOU LOSE' : ''),
    lines: []
  };

  var groupedLines = {};
  var squares = {};
  game.squares.forEach(function(sq) {
    var row = sq[0];
    var column = sq[1];
    var state = sq[2];
    var current = groupedLines[row] = groupedLines[row] || [];
    current.push(column);
    squares[row + '_' + column] = state;
  });

  Object.keys(groupedLines).sort().forEach(function(row) {
    var columns = groupedLines[row].sort().map(function(column) {
      var value = squares[row + '_' + column];
      var classes = 'square ';
      if (value === 'exploded') {
        value = 'X';
        classes += 'square-exploded'
      } else if (value === 'flagged') {
        value = 'F';
        classes += 'square-flagged'
      } else if (isInteger(value)) {
        classes += 'square-open square-open-' + value;
      } else if (value === 'unknown') {
        value = '?';
        classes += 'square-unknown';
      }
      return {
        classes: classes,
        value: value,
        row: row,
        column: column
      };
    });
    model.lines.push({
      columns: columns
    });
  });

  gameElement.html(template(model));

  var leftClick = 1,
    middleClick = 2,
     rightClick = 3;

  $('.square').mousedown(function(ev) {
    if (!finished) {
      var button = $(this);
      var row = button.data("row");
      var column = button.data("column");
      switch (ev.which) {
        case leftClick:
          ws.send(commands.sweep(row, column));
          break;
        case rightClick:
          ws.send(commands.flag(row, column));
          break;
        default:
          alert('You have a strange mouse');
      }
    }
    ev.preventDefault();
    return false;
  });
}

function parseBoolean(str) {
  return str === "true";
}

function isInteger(n) {
  return Number(n) === n && n % 1 === 0;
}

$(function () {
  var server = 'ws://' + location.host + '/websocket';
  var ws = new WebSocket(server);
  var newGameMsg = /New game (\w+) started/;

  ws.onmessage = function(evt) {
    var res = JSON.parse(evt.data);
    if (res.msg.match(newGameMsg)) {
      var gameId = res.msg.match(newGameMsg)[1];
      console.log(gameId);
      location.hash = gameId;
    }
    console.log(res);
    update(res, ws);
  };

  if (location.hash) {
    var gameId = location.hash.substring(1);
    var cont = function() {
      if (ws.readyState === 1) ws.send(commands.continue(gameId));
      else setTimeout(cont, 100);
    };
    cont();
  }

  $('#new').click(function() {
    ws.send(commands.newGame());
  });

});