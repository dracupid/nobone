#!/usr/bin/env node

try	{
	require('coffee-script/register');
	require('../lib/cli');
} catch (e) {
	if (e.code === 'MODULE_NOT_FOUND')
		require('../dist/cli');
	else
		throw e;
}
