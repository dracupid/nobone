
nobone = require './nobone'
{ kit, renderer } = nobone()
conf = null
package_path = null

module.exports = (dest_dir) ->
	kit.mkdirs dest_dir
	.then ->
		dest_dir = kit.fs.realpathSync dest_dir
		package_path = kit.path.join(dest_dir, 'package.json')
		kit.outputFile package_path, '{"main": "app.coffee"}'
	.then ->
		kit.spawn 'npm', ['init'], {
			cwd: dest_dir
		}
	.then ->
		kit.readFile package_path
	.then (str) ->
		conf = JSON.parse str
		conf.scripts = {
			test: "cake test"
			install: "cake setup"
		}
		kit.outputFile package_path, JSON.stringify(conf, null, 2)
	.then ->
		conf.class_name = conf.name[0].toUpperCase() + conf.name[1..]
		kit.generate_bone {
			src_dir: kit.path.normalize(__dirname + '/../bone')
			dest_dir
			data: conf
		}
	.then ->
		kit.log 'npm install...'.cyan
		kit.spawn 'npm', [
			'install', '-S', 'q', 'coffee-script', 'lodash', 'bower', 'nobone'
		], {
			cwd: dest_dir
		}
	.then ->
		kit.spawn 'npm', ['install', '--save-dev', 'mocha', 'benchmark'], {
			cwd: dest_dir
		}
	.then ->
		kit.spawn dest_dir + '/node_modules/.bin/bower', ['init'], {
			cwd: dest_dir
		}
	.then ->
		kit.log 'bower install...'.cyan
		kit.spawn dest_dir + '/node_modules/.bin/bower', [
			'install', '-S', 'lodash'
		], {
			cwd: dest_dir
		}
	.then ->
		kit.spawn 'npm', ['run-script', 'install'], {
			cwd: dest_dir
		}
	.then ->
		kit.rename dest_dir + '/npmignore', dest_dir + '/.npmignore'
	.then ->
		kit.rename dest_dir + '/gitignore', dest_dir + '/.gitignore'
	.then ->
		kit.spawn 'git', ['init'], { cwd: dest_dir }
	.then ->
		kit.spawn 'git', ['add', '--all'], { cwd: dest_dir }
	.then ->
		kit.spawn 'git', ['commit', '-m', 'init'], { cwd: dest_dir }
	.catch (err) ->
		if err.message.indexOf('ENOENT') == 0
			kit.log 'Canceled'.yellow
		else
			throw err
	.done ->
		kit.log 'Scaffolding done.'.green
