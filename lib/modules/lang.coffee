###*
 * An string helper for globalization.
###
Overview = 'lang'

kit = require '../kit'
_ = require 'lodash'

module.exports = (opts = {}) ->

	_.defaults opts, {
		lang_path: null
		lang_set: {}
		current: 'en'
	}

	###*
	 * It will find the right `key/value` pair in your defined `lang_set`.
	 * If it cannot find the one, it will output the key directly.
	 * @param  {String} cmd The original text.
	 * @param  {Array} args The arguments for string format. Optional.
	 * @param  {String} name The target language name. Optional.
	 * @return {String}
	 * @example
	 * ```coffeescript
	 * { lang } = require('nobone')(lang: {})
	 * lang.lang_set =
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
	 * lang('human', 'cn', lang_set) # -> '人类'
	 * lang('open|casual', 'cn', lang_set) # -> '打开'
	 * lang('find %s men', [10], 'jp', lang_set) # -> '10人が見付かる'
	 * ```
	 * @example
	 * ```coffeescript
	 * { lang } = require('nobone')(
	 * 	lang: { lang_path: 'lang.coffee' }
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
	self = (cmd, args = [], name, lang_set) ->
		if _.isString args
			lang_set = name
			name = args
			args = []

		name ?= self.current
		lang_set ?= self.lang_set

		i = cmd.lastIndexOf '|'
		if i > -1
			key = cmd[...i]
			cat = cmd[i + 1 ..]
		else
			key = cmd

		set = lang_set[key]

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
	 * lang.lang_set = {
	 * 	'cn': { 'human': '人类' }
	 * }
	 * ```
	###
	self.lang_set = opts.lang_set

	###*
	 * Current default language.
	 * @type {String}
	 * @default 'en'
	###
	self.current = opts.current

	###*
	 * Load language set and save them into the `lang_set`.
	 * Besides, it will also add properties `l` and `lang` to `String.prototype`.
	 * @param  {String} file_path
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
	self.load = (lang_path) ->
		switch typeof lang_path
			when 'string'
				lang_path = kit.path.resolve lang_path
				self.lang_set = require lang_path
			when 'object'
				self.lang_set = lang_path
			else
				return

		Object.defineProperty String.prototype, 'l', {
			get: -> self @ + ''
		}

		String.prototype.lang = (args...) ->
			args.unshift @ + ''
			self.apply null, args

	if opts.lang_path
		self.load opts.lang_path

	self