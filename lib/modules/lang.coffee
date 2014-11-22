###*
 * An string helper for globalization.
###
Overview = 'lang'

kit = require '../kit'
_ = require 'lodash'

module.exports = (opts = {}) ->

	_.defaults opts, {
		langPath: null
		langSet: {}
		current: 'en'
	}

	###*
	 * It will find the right `key/value` pair in your defined `langSet`.
	 * If it cannot find the one, it will output the key directly.
	 * @param  {String} cmd The original text.
	 * @param  {Array} args The arguments for string format. Optional.
	 * @param  {String} name The target language name. Optional.
	 * @return {String}
	 * @example
	 * ```coffeescript
	 * { lang } = require('nobone')(lang: {})
	 * lang.langSet =
	 * 	human:
	 * 		cn: '人类'
	 * 		jp: '人間'
	 *
	 * 	open:
	 * 		cn:
	 * 			formal: '开启' # Formal way to say 'open'
	 * 			casual: '打开' # Casual way to say 'open'
	 *
	 * 	'find %s men': '%s人が見付かる'
	 *
	 * lang('human', 'cn', langSet) # -> '人类'
	 * lang('open|casual', 'cn', langSet) # -> '打开'
	 * lang('find %s men', [10], 'jp', langSet) # -> '10人が見付かる'
	 * ```
	 * @example
	 * ```coffeescript
	 * { lang } = require('nobone')(
	 * 	lang: { langPath: 'lang.coffee' }
	 * 	current: 'cn'
	 * )
	 *
	 * 'human'.l # '人类'
	 * 'Good weather.'.lang('jp') # '日和。'
	 *
	 * lang.current = 'en'
	 * 'human'.l # 'human'
	 * 'Good weather.'.lang('jp') # 'Good weather.'
	 * ```
	###
	self = (cmd, args = [], name, langSet) ->
		if _.isString args
			langSet = name
			name = args
			args = []

		name ?= self.current
		langSet ?= self.langSet

		i = cmd.lastIndexOf '|'
		if i > -1
			key = cmd[...i]
			cat = cmd[i + 1 ..]
		else
			key = cmd

		set = langSet[key]

		out = if _.isObject set
			if set[name] == undefined
				key
			else
				if cat == undefined
					set[name]
				else if _.isObject set[name]
					set[name][cat]
				else
					key
		else if _.isString set
			set
		else
			key

		if args.length > 0
			util = kit.require 'util'
			args.unshift out
			util.format.apply util, args
		else
			out

	###*
	 * Language collections.
	 * @type {Object}
	 * @example
	 * ```coffeescript
	 * { lang } = require('nobone')(lang: {})
	 * lang.langSet = {
	 * 	'cn': { 'human': '人类' }
	 * }
	 * ```
	###
	self.langSet = opts.langSet

	###*
	 * Current default language.
	 * @type {String}
	 * @default 'en'
	###
	self.current = opts.current

	###*
	 * Load language set and save them into the `langSet`.
	 * Besides, it will also add properties `l` and `lang` to `String.prototype`.
	 * @param  {String} filePath
	 * js or coffee files.
	 * @example
	 * ```coffeescript
	 * { lang } = require('nobone')(lang: {})
	 * lang.load 'assets/lang'
	 * lang.current = 'cn'
	 * log 'test'.l # -> '测试'.
	 * log '%s persons'.lang([10]) # -> '10 persons'
	 * ```
	###
	self.load = (langPath) ->
		switch typeof langPath
			when 'string'
				langPath = kit.path.resolve langPath
				self.langSet = require langPath
			when 'object'
				self.langSet = langPath
			else
				return

		Object.defineProperty String.prototype, 'l', {
			get: -> self @ + ''
		}

		String.prototype.lang = (args...) ->
			args.unshift @ + ''
			self.apply null, args

	if opts.langPath
		self.load opts.langPath

	self