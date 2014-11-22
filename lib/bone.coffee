
nobone = require './nobone'
{ kit, renderer } = nobone()
conf = null
packagePath = null

module.exports = (destDir) ->
	kit.mkdirs destDir
	.then ->
		destDir = kit.fs.realpathSync destDir
		packagePath = kit.path.join(destDir, 'package.json')
		kit.outputFile packagePath, '{"main": "app.coffee"}'
	.then ->
		kit.spawn 'npm', ['init'], {
			cwd: destDir
		}
	.then ->
		kit.readFile packagePath
	.then (str) ->
		conf = JSON.parse str
		conf.scripts = {
			test: "cake test"
			install: "cake setup"
		}
		kit.outputFile packagePath, JSON.stringify(conf, null, 2)
	.then ->
		conf.className = conf.name[0].toUpperCase() + conf.name[1..]
		kit.generateBone {
			srcDir: kit.path.normalize(__dirname + '/../bone')
			destDir
			data: conf
		}
	.then ->
		kit.log 'npm install...'.cyan
		kit.spawn 'npm', [
			'install', '-S', 'q', 'coffee-script', 'lodash', 'bower', 'nobone'
		], {
			cwd: destDir
		}
	.then ->
		kit.spawn 'npm', ['install', '--save-dev', 'mocha', 'benchmark'], {
			cwd: destDir
		}
	.then ->
		kit.spawn destDir + '/nodeModules/.bin/bower', ['init'], {
			cwd: destDir
		}
	.then ->
		kit.log 'bower install...'.cyan
		kit.spawn destDir + '/nodeModules/.bin/bower', [
			'install', '-S', 'lodash'
		], {
			cwd: destDir
		}
	.then ->
		kit.spawn 'npm', ['run-script', 'install'], {
			cwd: destDir
		}
	.then ->
		kit.rename destDir + '/npmignore', destDir + '/.npmignore'
	.then ->
		kit.rename destDir + '/gitignore', destDir + '/.gitignore'
	.then ->
		kit.spawn 'git', ['init'], { cwd: destDir }
	.then ->
		kit.spawn 'git', ['add', '--all'], { cwd: destDir }
	.then ->
		kit.spawn 'git', ['commit', '-m', 'init'], { cwd: destDir }
	.catch (err) ->
		if err.message.indexOf('ENOENT') == 0
			kit.log 'Canceled'.yellow
		else
			throw err
	.done ->
		kit.log 'Scaffolding done.'.green
