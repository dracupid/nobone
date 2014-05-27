// Generated by CoffeeScript 1.7.1
(function() {
  var Q, app_path, coffee_bin, conf_path, example_path, forever_bin, gaze, os, ps, start, _;

  process.env.NODE_ENV = 'development';

  require('coffee-script/register');

  _ = require('underscore');

  require('colors');

  Q = require('q');

  os = require('../sys/os');

  coffee_bin = 'node_modules/.bin/coffee';

  forever_bin = 'node_modules/.bin/forever';

  app_path = process.cwd() + '/nobone.coffee';

  switch (process.argv[2]) {
    case 'setup':
      conf_path = 'var/NB_config.coffee';
      example_path = 'kit/NB_config.example.coffee';
      Q.fcall(function() {
        console.log(">> Install bower...".cyan);
        return os.spawn('node_modules/.bin/bower', ['--allow-root', 'install']);
      }).then(function() {
        return os.exists(conf_path);
      }).then(function(exists) {
        if (!exists) {
          console.log(">> Config file auto created.".cyan);
          return os.copy(example_path, conf_path);
        }
      }).done(function() {
        return console.log('>> Setup finished.'.yellow);
      });
      break;
    case 'dev':
      ps = null;
      start = function() {
        return ps = os.spawn(coffee_bin, [app_path], os.env_mode('development')).process;
      };
      start();
      global.NB = {};
      require('../var/NB_config');
      gaze = new (require('gaze'))(NB.conf.server_watch_pattern);
      gaze.on('all', function(action, path) {
        console.log((">> " + action + ": ").yellow + path);
        ps.kill('SIGINT');
        return start();
      });
      break;
    case 'debug':
      global.NB = {};
      require('../var/NB_config');
      os.spawn(coffee_bin, ['--nodejs', '--debug-brk=' + NB.conf.debug_port, app_path]);
      break;
    case 'start':
      os.spawn(forever_bin, ['start', '--minUptime', '5000', '--spinSleepTime', '5000', '-a', '-o', 'var/log/std.log', '-e', 'var/log/err.log', '-c', coffee_bin, app_path], os.env_mode('production'));
      break;
    case 'stop':
      os.spawn(forever_bin, ['stop', app_path]);
      break;
    default:
      console.error('>> No such command: ' + process.argv[2]);
  }

}).call(this);
