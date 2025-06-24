import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { normalizePath, loadEnv } from 'vite';
import require$$0, { resolve, relative } from 'path';

function getDefaultExportFromCjs (x) {
	return x && x.__esModule && Object.prototype.hasOwnProperty.call(x, 'default') ? x['default'] : x;
}

var picocolors = {exports: {}};

var hasRequiredPicocolors;

function requirePicocolors () {
	if (hasRequiredPicocolors) return picocolors.exports;
	hasRequiredPicocolors = 1;
	let p = process || {}, argv = p.argv || [], env = p.env || {};
	let isColorSupported =
		!(!!env.NO_COLOR || argv.includes("--no-color")) &&
		(!!env.FORCE_COLOR || argv.includes("--color") || p.platform === "win32" || ((p.stdout || {}).isTTY && env.TERM !== "dumb") || !!env.CI);

	let formatter = (open, close, replace = open) =>
		input => {
			let string = "" + input, index = string.indexOf(close, open.length);
			return ~index ? open + replaceClose(string, close, replace, index) + close : open + string + close
		};

	let replaceClose = (string, close, replace, index) => {
		let result = "", cursor = 0;
		do {
			result += string.substring(cursor, index) + replace;
			cursor = index + close.length;
			index = string.indexOf(close, cursor);
		} while (~index)
		return result + string.substring(cursor)
	};

	let createColors = (enabled = isColorSupported) => {
		let f = enabled ? formatter : () => String;
		return {
			isColorSupported: enabled,
			reset: f("\x1b[0m", "\x1b[0m"),
			bold: f("\x1b[1m", "\x1b[22m", "\x1b[22m\x1b[1m"),
			dim: f("\x1b[2m", "\x1b[22m", "\x1b[22m\x1b[2m"),
			italic: f("\x1b[3m", "\x1b[23m"),
			underline: f("\x1b[4m", "\x1b[24m"),
			inverse: f("\x1b[7m", "\x1b[27m"),
			hidden: f("\x1b[8m", "\x1b[28m"),
			strikethrough: f("\x1b[9m", "\x1b[29m"),

			black: f("\x1b[30m", "\x1b[39m"),
			red: f("\x1b[31m", "\x1b[39m"),
			green: f("\x1b[32m", "\x1b[39m"),
			yellow: f("\x1b[33m", "\x1b[39m"),
			blue: f("\x1b[34m", "\x1b[39m"),
			magenta: f("\x1b[35m", "\x1b[39m"),
			cyan: f("\x1b[36m", "\x1b[39m"),
			white: f("\x1b[37m", "\x1b[39m"),
			gray: f("\x1b[90m", "\x1b[39m"),

			bgBlack: f("\x1b[40m", "\x1b[49m"),
			bgRed: f("\x1b[41m", "\x1b[49m"),
			bgGreen: f("\x1b[42m", "\x1b[49m"),
			bgYellow: f("\x1b[43m", "\x1b[49m"),
			bgBlue: f("\x1b[44m", "\x1b[49m"),
			bgMagenta: f("\x1b[45m", "\x1b[49m"),
			bgCyan: f("\x1b[46m", "\x1b[49m"),
			bgWhite: f("\x1b[47m", "\x1b[49m"),

			blackBright: f("\x1b[90m", "\x1b[39m"),
			redBright: f("\x1b[91m", "\x1b[39m"),
			greenBright: f("\x1b[92m", "\x1b[39m"),
			yellowBright: f("\x1b[93m", "\x1b[39m"),
			blueBright: f("\x1b[94m", "\x1b[39m"),
			magentaBright: f("\x1b[95m", "\x1b[39m"),
			cyanBright: f("\x1b[96m", "\x1b[39m"),
			whiteBright: f("\x1b[97m", "\x1b[39m"),

			bgBlackBright: f("\x1b[100m", "\x1b[49m"),
			bgRedBright: f("\x1b[101m", "\x1b[49m"),
			bgGreenBright: f("\x1b[102m", "\x1b[49m"),
			bgYellowBright: f("\x1b[103m", "\x1b[49m"),
			bgBlueBright: f("\x1b[104m", "\x1b[49m"),
			bgMagentaBright: f("\x1b[105m", "\x1b[49m"),
			bgCyanBright: f("\x1b[106m", "\x1b[49m"),
			bgWhiteBright: f("\x1b[107m", "\x1b[49m"),
		}
	};

	picocolors.exports = createColors();
	picocolors.exports.createColors = createColors;
	return picocolors.exports;
}

var picocolorsExports = /*@__PURE__*/ requirePicocolors();
var colors = /*@__PURE__*/getDefaultExportFromCjs(picocolorsExports);

var utils = {};

var constants;
var hasRequiredConstants;

function requireConstants () {
	if (hasRequiredConstants) return constants;
	hasRequiredConstants = 1;

	const path = require$$0;
	const WIN_SLASH = '\\\\/';
	const WIN_NO_SLASH = `[^${WIN_SLASH}]`;

	/**
	 * Posix glob regex
	 */

	const DOT_LITERAL = '\\.';
	const PLUS_LITERAL = '\\+';
	const QMARK_LITERAL = '\\?';
	const SLASH_LITERAL = '\\/';
	const ONE_CHAR = '(?=.)';
	const QMARK = '[^/]';
	const END_ANCHOR = `(?:${SLASH_LITERAL}|$)`;
	const START_ANCHOR = `(?:^|${SLASH_LITERAL})`;
	const DOTS_SLASH = `${DOT_LITERAL}{1,2}${END_ANCHOR}`;
	const NO_DOT = `(?!${DOT_LITERAL})`;
	const NO_DOTS = `(?!${START_ANCHOR}${DOTS_SLASH})`;
	const NO_DOT_SLASH = `(?!${DOT_LITERAL}{0,1}${END_ANCHOR})`;
	const NO_DOTS_SLASH = `(?!${DOTS_SLASH})`;
	const QMARK_NO_DOT = `[^.${SLASH_LITERAL}]`;
	const STAR = `${QMARK}*?`;

	const POSIX_CHARS = {
	  DOT_LITERAL,
	  PLUS_LITERAL,
	  QMARK_LITERAL,
	  SLASH_LITERAL,
	  ONE_CHAR,
	  QMARK,
	  END_ANCHOR,
	  DOTS_SLASH,
	  NO_DOT,
	  NO_DOTS,
	  NO_DOT_SLASH,
	  NO_DOTS_SLASH,
	  QMARK_NO_DOT,
	  STAR,
	  START_ANCHOR
	};

	/**
	 * Windows glob regex
	 */

	const WINDOWS_CHARS = {
	  ...POSIX_CHARS,

	  SLASH_LITERAL: `[${WIN_SLASH}]`,
	  QMARK: WIN_NO_SLASH,
	  STAR: `${WIN_NO_SLASH}*?`,
	  DOTS_SLASH: `${DOT_LITERAL}{1,2}(?:[${WIN_SLASH}]|$)`,
	  NO_DOT: `(?!${DOT_LITERAL})`,
	  NO_DOTS: `(?!(?:^|[${WIN_SLASH}])${DOT_LITERAL}{1,2}(?:[${WIN_SLASH}]|$))`,
	  NO_DOT_SLASH: `(?!${DOT_LITERAL}{0,1}(?:[${WIN_SLASH}]|$))`,
	  NO_DOTS_SLASH: `(?!${DOT_LITERAL}{1,2}(?:[${WIN_SLASH}]|$))`,
	  QMARK_NO_DOT: `[^.${WIN_SLASH}]`,
	  START_ANCHOR: `(?:^|[${WIN_SLASH}])`,
	  END_ANCHOR: `(?:[${WIN_SLASH}]|$)`
	};

	/**
	 * POSIX Bracket Regex
	 */

	const POSIX_REGEX_SOURCE = {
	  alnum: 'a-zA-Z0-9',
	  alpha: 'a-zA-Z',
	  ascii: '\\x00-\\x7F',
	  blank: ' \\t',
	  cntrl: '\\x00-\\x1F\\x7F',
	  digit: '0-9',
	  graph: '\\x21-\\x7E',
	  lower: 'a-z',
	  print: '\\x20-\\x7E ',
	  punct: '\\-!"#$%&\'()\\*+,./:;<=>?@[\\]^_`{|}~',
	  space: ' \\t\\r\\n\\v\\f',
	  upper: 'A-Z',
	  word: 'A-Za-z0-9_',
	  xdigit: 'A-Fa-f0-9'
	};

	constants = {
	  MAX_LENGTH: 1024 * 64,
	  POSIX_REGEX_SOURCE,

	  // regular expressions
	  REGEX_BACKSLASH: /\\(?![*+?^${}(|)[\]])/g,
	  REGEX_NON_SPECIAL_CHARS: /^[^@![\].,$*+?^{}()|\\/]+/,
	  REGEX_SPECIAL_CHARS: /[-*+?.^${}(|)[\]]/,
	  REGEX_SPECIAL_CHARS_BACKREF: /(\\?)((\W)(\3*))/g,
	  REGEX_SPECIAL_CHARS_GLOBAL: /([-*+?.^${}(|)[\]])/g,
	  REGEX_REMOVE_BACKSLASH: /(?:\[.*?[^\\]\]|\\(?=.))/g,

	  // Replace globs with equivalent patterns to reduce parsing time.
	  REPLACEMENTS: {
	    '***': '*',
	    '**/**': '**',
	    '**/**/**': '**'
	  },

	  // Digits
	  CHAR_0: 48, /* 0 */
	  CHAR_9: 57, /* 9 */

	  // Alphabet chars.
	  CHAR_UPPERCASE_A: 65, /* A */
	  CHAR_LOWERCASE_A: 97, /* a */
	  CHAR_UPPERCASE_Z: 90, /* Z */
	  CHAR_LOWERCASE_Z: 122, /* z */

	  CHAR_LEFT_PARENTHESES: 40, /* ( */
	  CHAR_RIGHT_PARENTHESES: 41, /* ) */

	  CHAR_ASTERISK: 42, /* * */

	  // Non-alphabetic chars.
	  CHAR_AMPERSAND: 38, /* & */
	  CHAR_AT: 64, /* @ */
	  CHAR_BACKWARD_SLASH: 92, /* \ */
	  CHAR_CARRIAGE_RETURN: 13, /* \r */
	  CHAR_CIRCUMFLEX_ACCENT: 94, /* ^ */
	  CHAR_COLON: 58, /* : */
	  CHAR_COMMA: 44, /* , */
	  CHAR_DOT: 46, /* . */
	  CHAR_DOUBLE_QUOTE: 34, /* " */
	  CHAR_EQUAL: 61, /* = */
	  CHAR_EXCLAMATION_MARK: 33, /* ! */
	  CHAR_FORM_FEED: 12, /* \f */
	  CHAR_FORWARD_SLASH: 47, /* / */
	  CHAR_GRAVE_ACCENT: 96, /* ` */
	  CHAR_HASH: 35, /* # */
	  CHAR_HYPHEN_MINUS: 45, /* - */
	  CHAR_LEFT_ANGLE_BRACKET: 60, /* < */
	  CHAR_LEFT_CURLY_BRACE: 123, /* { */
	  CHAR_LEFT_SQUARE_BRACKET: 91, /* [ */
	  CHAR_LINE_FEED: 10, /* \n */
	  CHAR_NO_BREAK_SPACE: 160, /* \u00A0 */
	  CHAR_PERCENT: 37, /* % */
	  CHAR_PLUS: 43, /* + */
	  CHAR_QUESTION_MARK: 63, /* ? */
	  CHAR_RIGHT_ANGLE_BRACKET: 62, /* > */
	  CHAR_RIGHT_CURLY_BRACE: 125, /* } */
	  CHAR_RIGHT_SQUARE_BRACKET: 93, /* ] */
	  CHAR_SEMICOLON: 59, /* ; */
	  CHAR_SINGLE_QUOTE: 39, /* ' */
	  CHAR_SPACE: 32, /*   */
	  CHAR_TAB: 9, /* \t */
	  CHAR_UNDERSCORE: 95, /* _ */
	  CHAR_VERTICAL_LINE: 124, /* | */
	  CHAR_ZERO_WIDTH_NOBREAK_SPACE: 65279, /* \uFEFF */

	  SEP: path.sep,

	  /**
	   * Create EXTGLOB_CHARS
	   */

	  extglobChars(chars) {
	    return {
	      '!': { type: 'negate', open: '(?:(?!(?:', close: `))${chars.STAR})` },
	      '?': { type: 'qmark', open: '(?:', close: ')?' },
	      '+': { type: 'plus', open: '(?:', close: ')+' },
	      '*': { type: 'star', open: '(?:', close: ')*' },
	      '@': { type: 'at', open: '(?:', close: ')' }
	    };
	  },

	  /**
	   * Create GLOB_CHARS
	   */

	  globChars(win32) {
	    return win32 === true ? WINDOWS_CHARS : POSIX_CHARS;
	  }
	};
	return constants;
}

var hasRequiredUtils;

function requireUtils () {
	if (hasRequiredUtils) return utils;
	hasRequiredUtils = 1;
	(function (exports) {

		const path = require$$0;
		const win32 = process.platform === 'win32';
		const {
		  REGEX_BACKSLASH,
		  REGEX_REMOVE_BACKSLASH,
		  REGEX_SPECIAL_CHARS,
		  REGEX_SPECIAL_CHARS_GLOBAL
		} = requireConstants();

		exports.isObject = val => val !== null && typeof val === 'object' && !Array.isArray(val);
		exports.hasRegexChars = str => REGEX_SPECIAL_CHARS.test(str);
		exports.isRegexChar = str => str.length === 1 && exports.hasRegexChars(str);
		exports.escapeRegex = str => str.replace(REGEX_SPECIAL_CHARS_GLOBAL, '\\$1');
		exports.toPosixSlashes = str => str.replace(REGEX_BACKSLASH, '/');

		exports.removeBackslashes = str => {
		  return str.replace(REGEX_REMOVE_BACKSLASH, match => {
		    return match === '\\' ? '' : match;
		  });
		};

		exports.supportsLookbehinds = () => {
		  const segs = process.version.slice(1).split('.').map(Number);
		  if (segs.length === 3 && segs[0] >= 9 || (segs[0] === 8 && segs[1] >= 10)) {
		    return true;
		  }
		  return false;
		};

		exports.isWindows = options => {
		  if (options && typeof options.windows === 'boolean') {
		    return options.windows;
		  }
		  return win32 === true || path.sep === '\\';
		};

		exports.escapeLast = (input, char, lastIdx) => {
		  const idx = input.lastIndexOf(char, lastIdx);
		  if (idx === -1) return input;
		  if (input[idx - 1] === '\\') return exports.escapeLast(input, char, idx - 1);
		  return `${input.slice(0, idx)}\\${input.slice(idx)}`;
		};

		exports.removePrefix = (input, state = {}) => {
		  let output = input;
		  if (output.startsWith('./')) {
		    output = output.slice(2);
		    state.prefix = './';
		  }
		  return output;
		};

		exports.wrapOutput = (input, state = {}, options = {}) => {
		  const prepend = options.contains ? '' : '^';
		  const append = options.contains ? '' : '$';

		  let output = `${prepend}(?:${input})${append}`;
		  if (state.negated === true) {
		    output = `(?:^(?!${output}).*$)`;
		  }
		  return output;
		}; 
	} (utils));
	return utils;
}

var scan_1;
var hasRequiredScan;

function requireScan () {
	if (hasRequiredScan) return scan_1;
	hasRequiredScan = 1;

	const utils = requireUtils();
	const {
	  CHAR_ASTERISK,             /* * */
	  CHAR_AT,                   /* @ */
	  CHAR_BACKWARD_SLASH,       /* \ */
	  CHAR_COMMA,                /* , */
	  CHAR_DOT,                  /* . */
	  CHAR_EXCLAMATION_MARK,     /* ! */
	  CHAR_FORWARD_SLASH,        /* / */
	  CHAR_LEFT_CURLY_BRACE,     /* { */
	  CHAR_LEFT_PARENTHESES,     /* ( */
	  CHAR_LEFT_SQUARE_BRACKET,  /* [ */
	  CHAR_PLUS,                 /* + */
	  CHAR_QUESTION_MARK,        /* ? */
	  CHAR_RIGHT_CURLY_BRACE,    /* } */
	  CHAR_RIGHT_PARENTHESES,    /* ) */
	  CHAR_RIGHT_SQUARE_BRACKET  /* ] */
	} = requireConstants();

	const isPathSeparator = code => {
	  return code === CHAR_FORWARD_SLASH || code === CHAR_BACKWARD_SLASH;
	};

	const depth = token => {
	  if (token.isPrefix !== true) {
	    token.depth = token.isGlobstar ? Infinity : 1;
	  }
	};

	/**
	 * Quickly scans a glob pattern and returns an object with a handful of
	 * useful properties, like `isGlob`, `path` (the leading non-glob, if it exists),
	 * `glob` (the actual pattern), `negated` (true if the path starts with `!` but not
	 * with `!(`) and `negatedExtglob` (true if the path starts with `!(`).
	 *
	 * ```js
	 * const pm = require('picomatch');
	 * console.log(pm.scan('foo/bar/*.js'));
	 * { isGlob: true, input: 'foo/bar/*.js', base: 'foo/bar', glob: '*.js' }
	 * ```
	 * @param {String} `str`
	 * @param {Object} `options`
	 * @return {Object} Returns an object with tokens and regex source string.
	 * @api public
	 */

	const scan = (input, options) => {
	  const opts = options || {};

	  const length = input.length - 1;
	  const scanToEnd = opts.parts === true || opts.scanToEnd === true;
	  const slashes = [];
	  const tokens = [];
	  const parts = [];

	  let str = input;
	  let index = -1;
	  let start = 0;
	  let lastIndex = 0;
	  let isBrace = false;
	  let isBracket = false;
	  let isGlob = false;
	  let isExtglob = false;
	  let isGlobstar = false;
	  let braceEscaped = false;
	  let backslashes = false;
	  let negated = false;
	  let negatedExtglob = false;
	  let finished = false;
	  let braces = 0;
	  let prev;
	  let code;
	  let token = { value: '', depth: 0, isGlob: false };

	  const eos = () => index >= length;
	  const peek = () => str.charCodeAt(index + 1);
	  const advance = () => {
	    prev = code;
	    return str.charCodeAt(++index);
	  };

	  while (index < length) {
	    code = advance();
	    let next;

	    if (code === CHAR_BACKWARD_SLASH) {
	      backslashes = token.backslashes = true;
	      code = advance();

	      if (code === CHAR_LEFT_CURLY_BRACE) {
	        braceEscaped = true;
	      }
	      continue;
	    }

	    if (braceEscaped === true || code === CHAR_LEFT_CURLY_BRACE) {
	      braces++;

	      while (eos() !== true && (code = advance())) {
	        if (code === CHAR_BACKWARD_SLASH) {
	          backslashes = token.backslashes = true;
	          advance();
	          continue;
	        }

	        if (code === CHAR_LEFT_CURLY_BRACE) {
	          braces++;
	          continue;
	        }

	        if (braceEscaped !== true && code === CHAR_DOT && (code = advance()) === CHAR_DOT) {
	          isBrace = token.isBrace = true;
	          isGlob = token.isGlob = true;
	          finished = true;

	          if (scanToEnd === true) {
	            continue;
	          }

	          break;
	        }

	        if (braceEscaped !== true && code === CHAR_COMMA) {
	          isBrace = token.isBrace = true;
	          isGlob = token.isGlob = true;
	          finished = true;

	          if (scanToEnd === true) {
	            continue;
	          }

	          break;
	        }

	        if (code === CHAR_RIGHT_CURLY_BRACE) {
	          braces--;

	          if (braces === 0) {
	            braceEscaped = false;
	            isBrace = token.isBrace = true;
	            finished = true;
	            break;
	          }
	        }
	      }

	      if (scanToEnd === true) {
	        continue;
	      }

	      break;
	    }

	    if (code === CHAR_FORWARD_SLASH) {
	      slashes.push(index);
	      tokens.push(token);
	      token = { value: '', depth: 0, isGlob: false };

	      if (finished === true) continue;
	      if (prev === CHAR_DOT && index === (start + 1)) {
	        start += 2;
	        continue;
	      }

	      lastIndex = index + 1;
	      continue;
	    }

	    if (opts.noext !== true) {
	      const isExtglobChar = code === CHAR_PLUS
	        || code === CHAR_AT
	        || code === CHAR_ASTERISK
	        || code === CHAR_QUESTION_MARK
	        || code === CHAR_EXCLAMATION_MARK;

	      if (isExtglobChar === true && peek() === CHAR_LEFT_PARENTHESES) {
	        isGlob = token.isGlob = true;
	        isExtglob = token.isExtglob = true;
	        finished = true;
	        if (code === CHAR_EXCLAMATION_MARK && index === start) {
	          negatedExtglob = true;
	        }

	        if (scanToEnd === true) {
	          while (eos() !== true && (code = advance())) {
	            if (code === CHAR_BACKWARD_SLASH) {
	              backslashes = token.backslashes = true;
	              code = advance();
	              continue;
	            }

	            if (code === CHAR_RIGHT_PARENTHESES) {
	              isGlob = token.isGlob = true;
	              finished = true;
	              break;
	            }
	          }
	          continue;
	        }
	        break;
	      }
	    }

	    if (code === CHAR_ASTERISK) {
	      if (prev === CHAR_ASTERISK) isGlobstar = token.isGlobstar = true;
	      isGlob = token.isGlob = true;
	      finished = true;

	      if (scanToEnd === true) {
	        continue;
	      }
	      break;
	    }

	    if (code === CHAR_QUESTION_MARK) {
	      isGlob = token.isGlob = true;
	      finished = true;

	      if (scanToEnd === true) {
	        continue;
	      }
	      break;
	    }

	    if (code === CHAR_LEFT_SQUARE_BRACKET) {
	      while (eos() !== true && (next = advance())) {
	        if (next === CHAR_BACKWARD_SLASH) {
	          backslashes = token.backslashes = true;
	          advance();
	          continue;
	        }

	        if (next === CHAR_RIGHT_SQUARE_BRACKET) {
	          isBracket = token.isBracket = true;
	          isGlob = token.isGlob = true;
	          finished = true;
	          break;
	        }
	      }

	      if (scanToEnd === true) {
	        continue;
	      }

	      break;
	    }

	    if (opts.nonegate !== true && code === CHAR_EXCLAMATION_MARK && index === start) {
	      negated = token.negated = true;
	      start++;
	      continue;
	    }

	    if (opts.noparen !== true && code === CHAR_LEFT_PARENTHESES) {
	      isGlob = token.isGlob = true;

	      if (scanToEnd === true) {
	        while (eos() !== true && (code = advance())) {
	          if (code === CHAR_LEFT_PARENTHESES) {
	            backslashes = token.backslashes = true;
	            code = advance();
	            continue;
	          }

	          if (code === CHAR_RIGHT_PARENTHESES) {
	            finished = true;
	            break;
	          }
	        }
	        continue;
	      }
	      break;
	    }

	    if (isGlob === true) {
	      finished = true;

	      if (scanToEnd === true) {
	        continue;
	      }

	      break;
	    }
	  }

	  if (opts.noext === true) {
	    isExtglob = false;
	    isGlob = false;
	  }

	  let base = str;
	  let prefix = '';
	  let glob = '';

	  if (start > 0) {
	    prefix = str.slice(0, start);
	    str = str.slice(start);
	    lastIndex -= start;
	  }

	  if (base && isGlob === true && lastIndex > 0) {
	    base = str.slice(0, lastIndex);
	    glob = str.slice(lastIndex);
	  } else if (isGlob === true) {
	    base = '';
	    glob = str;
	  } else {
	    base = str;
	  }

	  if (base && base !== '' && base !== '/' && base !== str) {
	    if (isPathSeparator(base.charCodeAt(base.length - 1))) {
	      base = base.slice(0, -1);
	    }
	  }

	  if (opts.unescape === true) {
	    if (glob) glob = utils.removeBackslashes(glob);

	    if (base && backslashes === true) {
	      base = utils.removeBackslashes(base);
	    }
	  }

	  const state = {
	    prefix,
	    input,
	    start,
	    base,
	    glob,
	    isBrace,
	    isBracket,
	    isGlob,
	    isExtglob,
	    isGlobstar,
	    negated,
	    negatedExtglob
	  };

	  if (opts.tokens === true) {
	    state.maxDepth = 0;
	    if (!isPathSeparator(code)) {
	      tokens.push(token);
	    }
	    state.tokens = tokens;
	  }

	  if (opts.parts === true || opts.tokens === true) {
	    let prevIndex;

	    for (let idx = 0; idx < slashes.length; idx++) {
	      const n = prevIndex ? prevIndex + 1 : start;
	      const i = slashes[idx];
	      const value = input.slice(n, i);
	      if (opts.tokens) {
	        if (idx === 0 && start !== 0) {
	          tokens[idx].isPrefix = true;
	          tokens[idx].value = prefix;
	        } else {
	          tokens[idx].value = value;
	        }
	        depth(tokens[idx]);
	        state.maxDepth += tokens[idx].depth;
	      }
	      if (idx !== 0 || value !== '') {
	        parts.push(value);
	      }
	      prevIndex = i;
	    }

	    if (prevIndex && prevIndex + 1 < input.length) {
	      const value = input.slice(prevIndex + 1);
	      parts.push(value);

	      if (opts.tokens) {
	        tokens[tokens.length - 1].value = value;
	        depth(tokens[tokens.length - 1]);
	        state.maxDepth += tokens[tokens.length - 1].depth;
	      }
	    }

	    state.slashes = slashes;
	    state.parts = parts;
	  }

	  return state;
	};

	scan_1 = scan;
	return scan_1;
}

var parse_1;
var hasRequiredParse;

function requireParse () {
	if (hasRequiredParse) return parse_1;
	hasRequiredParse = 1;

	const constants = requireConstants();
	const utils = requireUtils();

	/**
	 * Constants
	 */

	const {
	  MAX_LENGTH,
	  POSIX_REGEX_SOURCE,
	  REGEX_NON_SPECIAL_CHARS,
	  REGEX_SPECIAL_CHARS_BACKREF,
	  REPLACEMENTS
	} = constants;

	/**
	 * Helpers
	 */

	const expandRange = (args, options) => {
	  if (typeof options.expandRange === 'function') {
	    return options.expandRange(...args, options);
	  }

	  args.sort();
	  const value = `[${args.join('-')}]`;

	  try {
	    /* eslint-disable-next-line no-new */
	    new RegExp(value);
	  } catch (ex) {
	    return args.map(v => utils.escapeRegex(v)).join('..');
	  }

	  return value;
	};

	/**
	 * Create the message for a syntax error
	 */

	const syntaxError = (type, char) => {
	  return `Missing ${type}: "${char}" - use "\\\\${char}" to match literal characters`;
	};

	/**
	 * Parse the given input string.
	 * @param {String} input
	 * @param {Object} options
	 * @return {Object}
	 */

	const parse = (input, options) => {
	  if (typeof input !== 'string') {
	    throw new TypeError('Expected a string');
	  }

	  input = REPLACEMENTS[input] || input;

	  const opts = { ...options };
	  const max = typeof opts.maxLength === 'number' ? Math.min(MAX_LENGTH, opts.maxLength) : MAX_LENGTH;

	  let len = input.length;
	  if (len > max) {
	    throw new SyntaxError(`Input length: ${len}, exceeds maximum allowed length: ${max}`);
	  }

	  const bos = { type: 'bos', value: '', output: opts.prepend || '' };
	  const tokens = [bos];

	  const capture = opts.capture ? '' : '?:';
	  const win32 = utils.isWindows(options);

	  // create constants based on platform, for windows or posix
	  const PLATFORM_CHARS = constants.globChars(win32);
	  const EXTGLOB_CHARS = constants.extglobChars(PLATFORM_CHARS);

	  const {
	    DOT_LITERAL,
	    PLUS_LITERAL,
	    SLASH_LITERAL,
	    ONE_CHAR,
	    DOTS_SLASH,
	    NO_DOT,
	    NO_DOT_SLASH,
	    NO_DOTS_SLASH,
	    QMARK,
	    QMARK_NO_DOT,
	    STAR,
	    START_ANCHOR
	  } = PLATFORM_CHARS;

	  const globstar = opts => {
	    return `(${capture}(?:(?!${START_ANCHOR}${opts.dot ? DOTS_SLASH : DOT_LITERAL}).)*?)`;
	  };

	  const nodot = opts.dot ? '' : NO_DOT;
	  const qmarkNoDot = opts.dot ? QMARK : QMARK_NO_DOT;
	  let star = opts.bash === true ? globstar(opts) : STAR;

	  if (opts.capture) {
	    star = `(${star})`;
	  }

	  // minimatch options support
	  if (typeof opts.noext === 'boolean') {
	    opts.noextglob = opts.noext;
	  }

	  const state = {
	    input,
	    index: -1,
	    start: 0,
	    dot: opts.dot === true,
	    consumed: '',
	    output: '',
	    prefix: '',
	    backtrack: false,
	    negated: false,
	    brackets: 0,
	    braces: 0,
	    parens: 0,
	    quotes: 0,
	    globstar: false,
	    tokens
	  };

	  input = utils.removePrefix(input, state);
	  len = input.length;

	  const extglobs = [];
	  const braces = [];
	  const stack = [];
	  let prev = bos;
	  let value;

	  /**
	   * Tokenizing helpers
	   */

	  const eos = () => state.index === len - 1;
	  const peek = state.peek = (n = 1) => input[state.index + n];
	  const advance = state.advance = () => input[++state.index] || '';
	  const remaining = () => input.slice(state.index + 1);
	  const consume = (value = '', num = 0) => {
	    state.consumed += value;
	    state.index += num;
	  };

	  const append = token => {
	    state.output += token.output != null ? token.output : token.value;
	    consume(token.value);
	  };

	  const negate = () => {
	    let count = 1;

	    while (peek() === '!' && (peek(2) !== '(' || peek(3) === '?')) {
	      advance();
	      state.start++;
	      count++;
	    }

	    if (count % 2 === 0) {
	      return false;
	    }

	    state.negated = true;
	    state.start++;
	    return true;
	  };

	  const increment = type => {
	    state[type]++;
	    stack.push(type);
	  };

	  const decrement = type => {
	    state[type]--;
	    stack.pop();
	  };

	  /**
	   * Push tokens onto the tokens array. This helper speeds up
	   * tokenizing by 1) helping us avoid backtracking as much as possible,
	   * and 2) helping us avoid creating extra tokens when consecutive
	   * characters are plain text. This improves performance and simplifies
	   * lookbehinds.
	   */

	  const push = tok => {
	    if (prev.type === 'globstar') {
	      const isBrace = state.braces > 0 && (tok.type === 'comma' || tok.type === 'brace');
	      const isExtglob = tok.extglob === true || (extglobs.length && (tok.type === 'pipe' || tok.type === 'paren'));

	      if (tok.type !== 'slash' && tok.type !== 'paren' && !isBrace && !isExtglob) {
	        state.output = state.output.slice(0, -prev.output.length);
	        prev.type = 'star';
	        prev.value = '*';
	        prev.output = star;
	        state.output += prev.output;
	      }
	    }

	    if (extglobs.length && tok.type !== 'paren') {
	      extglobs[extglobs.length - 1].inner += tok.value;
	    }

	    if (tok.value || tok.output) append(tok);
	    if (prev && prev.type === 'text' && tok.type === 'text') {
	      prev.value += tok.value;
	      prev.output = (prev.output || '') + tok.value;
	      return;
	    }

	    tok.prev = prev;
	    tokens.push(tok);
	    prev = tok;
	  };

	  const extglobOpen = (type, value) => {
	    const token = { ...EXTGLOB_CHARS[value], conditions: 1, inner: '' };

	    token.prev = prev;
	    token.parens = state.parens;
	    token.output = state.output;
	    const output = (opts.capture ? '(' : '') + token.open;

	    increment('parens');
	    push({ type, value, output: state.output ? '' : ONE_CHAR });
	    push({ type: 'paren', extglob: true, value: advance(), output });
	    extglobs.push(token);
	  };

	  const extglobClose = token => {
	    let output = token.close + (opts.capture ? ')' : '');
	    let rest;

	    if (token.type === 'negate') {
	      let extglobStar = star;

	      if (token.inner && token.inner.length > 1 && token.inner.includes('/')) {
	        extglobStar = globstar(opts);
	      }

	      if (extglobStar !== star || eos() || /^\)+$/.test(remaining())) {
	        output = token.close = `)$))${extglobStar}`;
	      }

	      if (token.inner.includes('*') && (rest = remaining()) && /^\.[^\\/.]+$/.test(rest)) {
	        // Any non-magical string (`.ts`) or even nested expression (`.{ts,tsx}`) can follow after the closing parenthesis.
	        // In this case, we need to parse the string and use it in the output of the original pattern.
	        // Suitable patterns: `/!(*.d).ts`, `/!(*.d).{ts,tsx}`, `**/!(*-dbg).@(js)`.
	        //
	        // Disabling the `fastpaths` option due to a problem with parsing strings as `.ts` in the pattern like `**/!(*.d).ts`.
	        const expression = parse(rest, { ...options, fastpaths: false }).output;

	        output = token.close = `)${expression})${extglobStar})`;
	      }

	      if (token.prev.type === 'bos') {
	        state.negatedExtglob = true;
	      }
	    }

	    push({ type: 'paren', extglob: true, value, output });
	    decrement('parens');
	  };

	  /**
	   * Fast paths
	   */

	  if (opts.fastpaths !== false && !/(^[*!]|[/()[\]{}"])/.test(input)) {
	    let backslashes = false;

	    let output = input.replace(REGEX_SPECIAL_CHARS_BACKREF, (m, esc, chars, first, rest, index) => {
	      if (first === '\\') {
	        backslashes = true;
	        return m;
	      }

	      if (first === '?') {
	        if (esc) {
	          return esc + first + (rest ? QMARK.repeat(rest.length) : '');
	        }
	        if (index === 0) {
	          return qmarkNoDot + (rest ? QMARK.repeat(rest.length) : '');
	        }
	        return QMARK.repeat(chars.length);
	      }

	      if (first === '.') {
	        return DOT_LITERAL.repeat(chars.length);
	      }

	      if (first === '*') {
	        if (esc) {
	          return esc + first + (rest ? star : '');
	        }
	        return star;
	      }
	      return esc ? m : `\\${m}`;
	    });

	    if (backslashes === true) {
	      if (opts.unescape === true) {
	        output = output.replace(/\\/g, '');
	      } else {
	        output = output.replace(/\\+/g, m => {
	          return m.length % 2 === 0 ? '\\\\' : (m ? '\\' : '');
	        });
	      }
	    }

	    if (output === input && opts.contains === true) {
	      state.output = input;
	      return state;
	    }

	    state.output = utils.wrapOutput(output, state, options);
	    return state;
	  }

	  /**
	   * Tokenize input until we reach end-of-string
	   */

	  while (!eos()) {
	    value = advance();

	    if (value === '\u0000') {
	      continue;
	    }

	    /**
	     * Escaped characters
	     */

	    if (value === '\\') {
	      const next = peek();

	      if (next === '/' && opts.bash !== true) {
	        continue;
	      }

	      if (next === '.' || next === ';') {
	        continue;
	      }

	      if (!next) {
	        value += '\\';
	        push({ type: 'text', value });
	        continue;
	      }

	      // collapse slashes to reduce potential for exploits
	      const match = /^\\+/.exec(remaining());
	      let slashes = 0;

	      if (match && match[0].length > 2) {
	        slashes = match[0].length;
	        state.index += slashes;
	        if (slashes % 2 !== 0) {
	          value += '\\';
	        }
	      }

	      if (opts.unescape === true) {
	        value = advance();
	      } else {
	        value += advance();
	      }

	      if (state.brackets === 0) {
	        push({ type: 'text', value });
	        continue;
	      }
	    }

	    /**
	     * If we're inside a regex character class, continue
	     * until we reach the closing bracket.
	     */

	    if (state.brackets > 0 && (value !== ']' || prev.value === '[' || prev.value === '[^')) {
	      if (opts.posix !== false && value === ':') {
	        const inner = prev.value.slice(1);
	        if (inner.includes('[')) {
	          prev.posix = true;

	          if (inner.includes(':')) {
	            const idx = prev.value.lastIndexOf('[');
	            const pre = prev.value.slice(0, idx);
	            const rest = prev.value.slice(idx + 2);
	            const posix = POSIX_REGEX_SOURCE[rest];
	            if (posix) {
	              prev.value = pre + posix;
	              state.backtrack = true;
	              advance();

	              if (!bos.output && tokens.indexOf(prev) === 1) {
	                bos.output = ONE_CHAR;
	              }
	              continue;
	            }
	          }
	        }
	      }

	      if ((value === '[' && peek() !== ':') || (value === '-' && peek() === ']')) {
	        value = `\\${value}`;
	      }

	      if (value === ']' && (prev.value === '[' || prev.value === '[^')) {
	        value = `\\${value}`;
	      }

	      if (opts.posix === true && value === '!' && prev.value === '[') {
	        value = '^';
	      }

	      prev.value += value;
	      append({ value });
	      continue;
	    }

	    /**
	     * If we're inside a quoted string, continue
	     * until we reach the closing double quote.
	     */

	    if (state.quotes === 1 && value !== '"') {
	      value = utils.escapeRegex(value);
	      prev.value += value;
	      append({ value });
	      continue;
	    }

	    /**
	     * Double quotes
	     */

	    if (value === '"') {
	      state.quotes = state.quotes === 1 ? 0 : 1;
	      if (opts.keepQuotes === true) {
	        push({ type: 'text', value });
	      }
	      continue;
	    }

	    /**
	     * Parentheses
	     */

	    if (value === '(') {
	      increment('parens');
	      push({ type: 'paren', value });
	      continue;
	    }

	    if (value === ')') {
	      if (state.parens === 0 && opts.strictBrackets === true) {
	        throw new SyntaxError(syntaxError('opening', '('));
	      }

	      const extglob = extglobs[extglobs.length - 1];
	      if (extglob && state.parens === extglob.parens + 1) {
	        extglobClose(extglobs.pop());
	        continue;
	      }

	      push({ type: 'paren', value, output: state.parens ? ')' : '\\)' });
	      decrement('parens');
	      continue;
	    }

	    /**
	     * Square brackets
	     */

	    if (value === '[') {
	      if (opts.nobracket === true || !remaining().includes(']')) {
	        if (opts.nobracket !== true && opts.strictBrackets === true) {
	          throw new SyntaxError(syntaxError('closing', ']'));
	        }

	        value = `\\${value}`;
	      } else {
	        increment('brackets');
	      }

	      push({ type: 'bracket', value });
	      continue;
	    }

	    if (value === ']') {
	      if (opts.nobracket === true || (prev && prev.type === 'bracket' && prev.value.length === 1)) {
	        push({ type: 'text', value, output: `\\${value}` });
	        continue;
	      }

	      if (state.brackets === 0) {
	        if (opts.strictBrackets === true) {
	          throw new SyntaxError(syntaxError('opening', '['));
	        }

	        push({ type: 'text', value, output: `\\${value}` });
	        continue;
	      }

	      decrement('brackets');

	      const prevValue = prev.value.slice(1);
	      if (prev.posix !== true && prevValue[0] === '^' && !prevValue.includes('/')) {
	        value = `/${value}`;
	      }

	      prev.value += value;
	      append({ value });

	      // when literal brackets are explicitly disabled
	      // assume we should match with a regex character class
	      if (opts.literalBrackets === false || utils.hasRegexChars(prevValue)) {
	        continue;
	      }

	      const escaped = utils.escapeRegex(prev.value);
	      state.output = state.output.slice(0, -prev.value.length);

	      // when literal brackets are explicitly enabled
	      // assume we should escape the brackets to match literal characters
	      if (opts.literalBrackets === true) {
	        state.output += escaped;
	        prev.value = escaped;
	        continue;
	      }

	      // when the user specifies nothing, try to match both
	      prev.value = `(${capture}${escaped}|${prev.value})`;
	      state.output += prev.value;
	      continue;
	    }

	    /**
	     * Braces
	     */

	    if (value === '{' && opts.nobrace !== true) {
	      increment('braces');

	      const open = {
	        type: 'brace',
	        value,
	        output: '(',
	        outputIndex: state.output.length,
	        tokensIndex: state.tokens.length
	      };

	      braces.push(open);
	      push(open);
	      continue;
	    }

	    if (value === '}') {
	      const brace = braces[braces.length - 1];

	      if (opts.nobrace === true || !brace) {
	        push({ type: 'text', value, output: value });
	        continue;
	      }

	      let output = ')';

	      if (brace.dots === true) {
	        const arr = tokens.slice();
	        const range = [];

	        for (let i = arr.length - 1; i >= 0; i--) {
	          tokens.pop();
	          if (arr[i].type === 'brace') {
	            break;
	          }
	          if (arr[i].type !== 'dots') {
	            range.unshift(arr[i].value);
	          }
	        }

	        output = expandRange(range, opts);
	        state.backtrack = true;
	      }

	      if (brace.comma !== true && brace.dots !== true) {
	        const out = state.output.slice(0, brace.outputIndex);
	        const toks = state.tokens.slice(brace.tokensIndex);
	        brace.value = brace.output = '\\{';
	        value = output = '\\}';
	        state.output = out;
	        for (const t of toks) {
	          state.output += (t.output || t.value);
	        }
	      }

	      push({ type: 'brace', value, output });
	      decrement('braces');
	      braces.pop();
	      continue;
	    }

	    /**
	     * Pipes
	     */

	    if (value === '|') {
	      if (extglobs.length > 0) {
	        extglobs[extglobs.length - 1].conditions++;
	      }
	      push({ type: 'text', value });
	      continue;
	    }

	    /**
	     * Commas
	     */

	    if (value === ',') {
	      let output = value;

	      const brace = braces[braces.length - 1];
	      if (brace && stack[stack.length - 1] === 'braces') {
	        brace.comma = true;
	        output = '|';
	      }

	      push({ type: 'comma', value, output });
	      continue;
	    }

	    /**
	     * Slashes
	     */

	    if (value === '/') {
	      // if the beginning of the glob is "./", advance the start
	      // to the current index, and don't add the "./" characters
	      // to the state. This greatly simplifies lookbehinds when
	      // checking for BOS characters like "!" and "." (not "./")
	      if (prev.type === 'dot' && state.index === state.start + 1) {
	        state.start = state.index + 1;
	        state.consumed = '';
	        state.output = '';
	        tokens.pop();
	        prev = bos; // reset "prev" to the first token
	        continue;
	      }

	      push({ type: 'slash', value, output: SLASH_LITERAL });
	      continue;
	    }

	    /**
	     * Dots
	     */

	    if (value === '.') {
	      if (state.braces > 0 && prev.type === 'dot') {
	        if (prev.value === '.') prev.output = DOT_LITERAL;
	        const brace = braces[braces.length - 1];
	        prev.type = 'dots';
	        prev.output += value;
	        prev.value += value;
	        brace.dots = true;
	        continue;
	      }

	      if ((state.braces + state.parens) === 0 && prev.type !== 'bos' && prev.type !== 'slash') {
	        push({ type: 'text', value, output: DOT_LITERAL });
	        continue;
	      }

	      push({ type: 'dot', value, output: DOT_LITERAL });
	      continue;
	    }

	    /**
	     * Question marks
	     */

	    if (value === '?') {
	      const isGroup = prev && prev.value === '(';
	      if (!isGroup && opts.noextglob !== true && peek() === '(' && peek(2) !== '?') {
	        extglobOpen('qmark', value);
	        continue;
	      }

	      if (prev && prev.type === 'paren') {
	        const next = peek();
	        let output = value;

	        if (next === '<' && !utils.supportsLookbehinds()) {
	          throw new Error('Node.js v10 or higher is required for regex lookbehinds');
	        }

	        if ((prev.value === '(' && !/[!=<:]/.test(next)) || (next === '<' && !/<([!=]|\w+>)/.test(remaining()))) {
	          output = `\\${value}`;
	        }

	        push({ type: 'text', value, output });
	        continue;
	      }

	      if (opts.dot !== true && (prev.type === 'slash' || prev.type === 'bos')) {
	        push({ type: 'qmark', value, output: QMARK_NO_DOT });
	        continue;
	      }

	      push({ type: 'qmark', value, output: QMARK });
	      continue;
	    }

	    /**
	     * Exclamation
	     */

	    if (value === '!') {
	      if (opts.noextglob !== true && peek() === '(') {
	        if (peek(2) !== '?' || !/[!=<:]/.test(peek(3))) {
	          extglobOpen('negate', value);
	          continue;
	        }
	      }

	      if (opts.nonegate !== true && state.index === 0) {
	        negate();
	        continue;
	      }
	    }

	    /**
	     * Plus
	     */

	    if (value === '+') {
	      if (opts.noextglob !== true && peek() === '(' && peek(2) !== '?') {
	        extglobOpen('plus', value);
	        continue;
	      }

	      if ((prev && prev.value === '(') || opts.regex === false) {
	        push({ type: 'plus', value, output: PLUS_LITERAL });
	        continue;
	      }

	      if ((prev && (prev.type === 'bracket' || prev.type === 'paren' || prev.type === 'brace')) || state.parens > 0) {
	        push({ type: 'plus', value });
	        continue;
	      }

	      push({ type: 'plus', value: PLUS_LITERAL });
	      continue;
	    }

	    /**
	     * Plain text
	     */

	    if (value === '@') {
	      if (opts.noextglob !== true && peek() === '(' && peek(2) !== '?') {
	        push({ type: 'at', extglob: true, value, output: '' });
	        continue;
	      }

	      push({ type: 'text', value });
	      continue;
	    }

	    /**
	     * Plain text
	     */

	    if (value !== '*') {
	      if (value === '$' || value === '^') {
	        value = `\\${value}`;
	      }

	      const match = REGEX_NON_SPECIAL_CHARS.exec(remaining());
	      if (match) {
	        value += match[0];
	        state.index += match[0].length;
	      }

	      push({ type: 'text', value });
	      continue;
	    }

	    /**
	     * Stars
	     */

	    if (prev && (prev.type === 'globstar' || prev.star === true)) {
	      prev.type = 'star';
	      prev.star = true;
	      prev.value += value;
	      prev.output = star;
	      state.backtrack = true;
	      state.globstar = true;
	      consume(value);
	      continue;
	    }

	    let rest = remaining();
	    if (opts.noextglob !== true && /^\([^?]/.test(rest)) {
	      extglobOpen('star', value);
	      continue;
	    }

	    if (prev.type === 'star') {
	      if (opts.noglobstar === true) {
	        consume(value);
	        continue;
	      }

	      const prior = prev.prev;
	      const before = prior.prev;
	      const isStart = prior.type === 'slash' || prior.type === 'bos';
	      const afterStar = before && (before.type === 'star' || before.type === 'globstar');

	      if (opts.bash === true && (!isStart || (rest[0] && rest[0] !== '/'))) {
	        push({ type: 'star', value, output: '' });
	        continue;
	      }

	      const isBrace = state.braces > 0 && (prior.type === 'comma' || prior.type === 'brace');
	      const isExtglob = extglobs.length && (prior.type === 'pipe' || prior.type === 'paren');
	      if (!isStart && prior.type !== 'paren' && !isBrace && !isExtglob) {
	        push({ type: 'star', value, output: '' });
	        continue;
	      }

	      // strip consecutive `/**/`
	      while (rest.slice(0, 3) === '/**') {
	        const after = input[state.index + 4];
	        if (after && after !== '/') {
	          break;
	        }
	        rest = rest.slice(3);
	        consume('/**', 3);
	      }

	      if (prior.type === 'bos' && eos()) {
	        prev.type = 'globstar';
	        prev.value += value;
	        prev.output = globstar(opts);
	        state.output = prev.output;
	        state.globstar = true;
	        consume(value);
	        continue;
	      }

	      if (prior.type === 'slash' && prior.prev.type !== 'bos' && !afterStar && eos()) {
	        state.output = state.output.slice(0, -(prior.output + prev.output).length);
	        prior.output = `(?:${prior.output}`;

	        prev.type = 'globstar';
	        prev.output = globstar(opts) + (opts.strictSlashes ? ')' : '|$)');
	        prev.value += value;
	        state.globstar = true;
	        state.output += prior.output + prev.output;
	        consume(value);
	        continue;
	      }

	      if (prior.type === 'slash' && prior.prev.type !== 'bos' && rest[0] === '/') {
	        const end = rest[1] !== void 0 ? '|$' : '';

	        state.output = state.output.slice(0, -(prior.output + prev.output).length);
	        prior.output = `(?:${prior.output}`;

	        prev.type = 'globstar';
	        prev.output = `${globstar(opts)}${SLASH_LITERAL}|${SLASH_LITERAL}${end})`;
	        prev.value += value;

	        state.output += prior.output + prev.output;
	        state.globstar = true;

	        consume(value + advance());

	        push({ type: 'slash', value: '/', output: '' });
	        continue;
	      }

	      if (prior.type === 'bos' && rest[0] === '/') {
	        prev.type = 'globstar';
	        prev.value += value;
	        prev.output = `(?:^|${SLASH_LITERAL}|${globstar(opts)}${SLASH_LITERAL})`;
	        state.output = prev.output;
	        state.globstar = true;
	        consume(value + advance());
	        push({ type: 'slash', value: '/', output: '' });
	        continue;
	      }

	      // remove single star from output
	      state.output = state.output.slice(0, -prev.output.length);

	      // reset previous token to globstar
	      prev.type = 'globstar';
	      prev.output = globstar(opts);
	      prev.value += value;

	      // reset output with globstar
	      state.output += prev.output;
	      state.globstar = true;
	      consume(value);
	      continue;
	    }

	    const token = { type: 'star', value, output: star };

	    if (opts.bash === true) {
	      token.output = '.*?';
	      if (prev.type === 'bos' || prev.type === 'slash') {
	        token.output = nodot + token.output;
	      }
	      push(token);
	      continue;
	    }

	    if (prev && (prev.type === 'bracket' || prev.type === 'paren') && opts.regex === true) {
	      token.output = value;
	      push(token);
	      continue;
	    }

	    if (state.index === state.start || prev.type === 'slash' || prev.type === 'dot') {
	      if (prev.type === 'dot') {
	        state.output += NO_DOT_SLASH;
	        prev.output += NO_DOT_SLASH;

	      } else if (opts.dot === true) {
	        state.output += NO_DOTS_SLASH;
	        prev.output += NO_DOTS_SLASH;

	      } else {
	        state.output += nodot;
	        prev.output += nodot;
	      }

	      if (peek() !== '*') {
	        state.output += ONE_CHAR;
	        prev.output += ONE_CHAR;
	      }
	    }

	    push(token);
	  }

	  while (state.brackets > 0) {
	    if (opts.strictBrackets === true) throw new SyntaxError(syntaxError('closing', ']'));
	    state.output = utils.escapeLast(state.output, '[');
	    decrement('brackets');
	  }

	  while (state.parens > 0) {
	    if (opts.strictBrackets === true) throw new SyntaxError(syntaxError('closing', ')'));
	    state.output = utils.escapeLast(state.output, '(');
	    decrement('parens');
	  }

	  while (state.braces > 0) {
	    if (opts.strictBrackets === true) throw new SyntaxError(syntaxError('closing', '}'));
	    state.output = utils.escapeLast(state.output, '{');
	    decrement('braces');
	  }

	  if (opts.strictSlashes !== true && (prev.type === 'star' || prev.type === 'bracket')) {
	    push({ type: 'maybe_slash', value: '', output: `${SLASH_LITERAL}?` });
	  }

	  // rebuild the output if we had to backtrack at any point
	  if (state.backtrack === true) {
	    state.output = '';

	    for (const token of state.tokens) {
	      state.output += token.output != null ? token.output : token.value;

	      if (token.suffix) {
	        state.output += token.suffix;
	      }
	    }
	  }

	  return state;
	};

	/**
	 * Fast paths for creating regular expressions for common glob patterns.
	 * This can significantly speed up processing and has very little downside
	 * impact when none of the fast paths match.
	 */

	parse.fastpaths = (input, options) => {
	  const opts = { ...options };
	  const max = typeof opts.maxLength === 'number' ? Math.min(MAX_LENGTH, opts.maxLength) : MAX_LENGTH;
	  const len = input.length;
	  if (len > max) {
	    throw new SyntaxError(`Input length: ${len}, exceeds maximum allowed length: ${max}`);
	  }

	  input = REPLACEMENTS[input] || input;
	  const win32 = utils.isWindows(options);

	  // create constants based on platform, for windows or posix
	  const {
	    DOT_LITERAL,
	    SLASH_LITERAL,
	    ONE_CHAR,
	    DOTS_SLASH,
	    NO_DOT,
	    NO_DOTS,
	    NO_DOTS_SLASH,
	    STAR,
	    START_ANCHOR
	  } = constants.globChars(win32);

	  const nodot = opts.dot ? NO_DOTS : NO_DOT;
	  const slashDot = opts.dot ? NO_DOTS_SLASH : NO_DOT;
	  const capture = opts.capture ? '' : '?:';
	  const state = { negated: false, prefix: '' };
	  let star = opts.bash === true ? '.*?' : STAR;

	  if (opts.capture) {
	    star = `(${star})`;
	  }

	  const globstar = opts => {
	    if (opts.noglobstar === true) return star;
	    return `(${capture}(?:(?!${START_ANCHOR}${opts.dot ? DOTS_SLASH : DOT_LITERAL}).)*?)`;
	  };

	  const create = str => {
	    switch (str) {
	      case '*':
	        return `${nodot}${ONE_CHAR}${star}`;

	      case '.*':
	        return `${DOT_LITERAL}${ONE_CHAR}${star}`;

	      case '*.*':
	        return `${nodot}${star}${DOT_LITERAL}${ONE_CHAR}${star}`;

	      case '*/*':
	        return `${nodot}${star}${SLASH_LITERAL}${ONE_CHAR}${slashDot}${star}`;

	      case '**':
	        return nodot + globstar(opts);

	      case '**/*':
	        return `(?:${nodot}${globstar(opts)}${SLASH_LITERAL})?${slashDot}${ONE_CHAR}${star}`;

	      case '**/*.*':
	        return `(?:${nodot}${globstar(opts)}${SLASH_LITERAL})?${slashDot}${star}${DOT_LITERAL}${ONE_CHAR}${star}`;

	      case '**/.*':
	        return `(?:${nodot}${globstar(opts)}${SLASH_LITERAL})?${DOT_LITERAL}${ONE_CHAR}${star}`;

	      default: {
	        const match = /^(.*?)\.(\w+)$/.exec(str);
	        if (!match) return;

	        const source = create(match[1]);
	        if (!source) return;

	        return source + DOT_LITERAL + match[2];
	      }
	    }
	  };

	  const output = utils.removePrefix(input, state);
	  let source = create(output);

	  if (source && opts.strictSlashes !== true) {
	    source += `${SLASH_LITERAL}?`;
	  }

	  return source;
	};

	parse_1 = parse;
	return parse_1;
}

var picomatch_1;
var hasRequiredPicomatch$1;

function requirePicomatch$1 () {
	if (hasRequiredPicomatch$1) return picomatch_1;
	hasRequiredPicomatch$1 = 1;

	const path = require$$0;
	const scan = requireScan();
	const parse = requireParse();
	const utils = requireUtils();
	const constants = requireConstants();
	const isObject = val => val && typeof val === 'object' && !Array.isArray(val);

	/**
	 * Creates a matcher function from one or more glob patterns. The
	 * returned function takes a string to match as its first argument,
	 * and returns true if the string is a match. The returned matcher
	 * function also takes a boolean as the second argument that, when true,
	 * returns an object with additional information.
	 *
	 * ```js
	 * const picomatch = require('picomatch');
	 * // picomatch(glob[, options]);
	 *
	 * const isMatch = picomatch('*.!(*a)');
	 * console.log(isMatch('a.a')); //=> false
	 * console.log(isMatch('a.b')); //=> true
	 * ```
	 * @name picomatch
	 * @param {String|Array} `globs` One or more glob patterns.
	 * @param {Object=} `options`
	 * @return {Function=} Returns a matcher function.
	 * @api public
	 */

	const picomatch = (glob, options, returnState = false) => {
	  if (Array.isArray(glob)) {
	    const fns = glob.map(input => picomatch(input, options, returnState));
	    const arrayMatcher = str => {
	      for (const isMatch of fns) {
	        const state = isMatch(str);
	        if (state) return state;
	      }
	      return false;
	    };
	    return arrayMatcher;
	  }

	  const isState = isObject(glob) && glob.tokens && glob.input;

	  if (glob === '' || (typeof glob !== 'string' && !isState)) {
	    throw new TypeError('Expected pattern to be a non-empty string');
	  }

	  const opts = options || {};
	  const posix = utils.isWindows(options);
	  const regex = isState
	    ? picomatch.compileRe(glob, options)
	    : picomatch.makeRe(glob, options, false, true);

	  const state = regex.state;
	  delete regex.state;

	  let isIgnored = () => false;
	  if (opts.ignore) {
	    const ignoreOpts = { ...options, ignore: null, onMatch: null, onResult: null };
	    isIgnored = picomatch(opts.ignore, ignoreOpts, returnState);
	  }

	  const matcher = (input, returnObject = false) => {
	    const { isMatch, match, output } = picomatch.test(input, regex, options, { glob, posix });
	    const result = { glob, state, regex, posix, input, output, match, isMatch };

	    if (typeof opts.onResult === 'function') {
	      opts.onResult(result);
	    }

	    if (isMatch === false) {
	      result.isMatch = false;
	      return returnObject ? result : false;
	    }

	    if (isIgnored(input)) {
	      if (typeof opts.onIgnore === 'function') {
	        opts.onIgnore(result);
	      }
	      result.isMatch = false;
	      return returnObject ? result : false;
	    }

	    if (typeof opts.onMatch === 'function') {
	      opts.onMatch(result);
	    }
	    return returnObject ? result : true;
	  };

	  if (returnState) {
	    matcher.state = state;
	  }

	  return matcher;
	};

	/**
	 * Test `input` with the given `regex`. This is used by the main
	 * `picomatch()` function to test the input string.
	 *
	 * ```js
	 * const picomatch = require('picomatch');
	 * // picomatch.test(input, regex[, options]);
	 *
	 * console.log(picomatch.test('foo/bar', /^(?:([^/]*?)\/([^/]*?))$/));
	 * // { isMatch: true, match: [ 'foo/', 'foo', 'bar' ], output: 'foo/bar' }
	 * ```
	 * @param {String} `input` String to test.
	 * @param {RegExp} `regex`
	 * @return {Object} Returns an object with matching info.
	 * @api public
	 */

	picomatch.test = (input, regex, options, { glob, posix } = {}) => {
	  if (typeof input !== 'string') {
	    throw new TypeError('Expected input to be a string');
	  }

	  if (input === '') {
	    return { isMatch: false, output: '' };
	  }

	  const opts = options || {};
	  const format = opts.format || (posix ? utils.toPosixSlashes : null);
	  let match = input === glob;
	  let output = (match && format) ? format(input) : input;

	  if (match === false) {
	    output = format ? format(input) : input;
	    match = output === glob;
	  }

	  if (match === false || opts.capture === true) {
	    if (opts.matchBase === true || opts.basename === true) {
	      match = picomatch.matchBase(input, regex, options, posix);
	    } else {
	      match = regex.exec(output);
	    }
	  }

	  return { isMatch: Boolean(match), match, output };
	};

	/**
	 * Match the basename of a filepath.
	 *
	 * ```js
	 * const picomatch = require('picomatch');
	 * // picomatch.matchBase(input, glob[, options]);
	 * console.log(picomatch.matchBase('foo/bar.js', '*.js'); // true
	 * ```
	 * @param {String} `input` String to test.
	 * @param {RegExp|String} `glob` Glob pattern or regex created by [.makeRe](#makeRe).
	 * @return {Boolean}
	 * @api public
	 */

	picomatch.matchBase = (input, glob, options, posix = utils.isWindows(options)) => {
	  const regex = glob instanceof RegExp ? glob : picomatch.makeRe(glob, options);
	  return regex.test(path.basename(input));
	};

	/**
	 * Returns true if **any** of the given glob `patterns` match the specified `string`.
	 *
	 * ```js
	 * const picomatch = require('picomatch');
	 * // picomatch.isMatch(string, patterns[, options]);
	 *
	 * console.log(picomatch.isMatch('a.a', ['b.*', '*.a'])); //=> true
	 * console.log(picomatch.isMatch('a.a', 'b.*')); //=> false
	 * ```
	 * @param {String|Array} str The string to test.
	 * @param {String|Array} patterns One or more glob patterns to use for matching.
	 * @param {Object} [options] See available [options](#options).
	 * @return {Boolean} Returns true if any patterns match `str`
	 * @api public
	 */

	picomatch.isMatch = (str, patterns, options) => picomatch(patterns, options)(str);

	/**
	 * Parse a glob pattern to create the source string for a regular
	 * expression.
	 *
	 * ```js
	 * const picomatch = require('picomatch');
	 * const result = picomatch.parse(pattern[, options]);
	 * ```
	 * @param {String} `pattern`
	 * @param {Object} `options`
	 * @return {Object} Returns an object with useful properties and output to be used as a regex source string.
	 * @api public
	 */

	picomatch.parse = (pattern, options) => {
	  if (Array.isArray(pattern)) return pattern.map(p => picomatch.parse(p, options));
	  return parse(pattern, { ...options, fastpaths: false });
	};

	/**
	 * Scan a glob pattern to separate the pattern into segments.
	 *
	 * ```js
	 * const picomatch = require('picomatch');
	 * // picomatch.scan(input[, options]);
	 *
	 * const result = picomatch.scan('!./foo/*.js');
	 * console.log(result);
	 * { prefix: '!./',
	 *   input: '!./foo/*.js',
	 *   start: 3,
	 *   base: 'foo',
	 *   glob: '*.js',
	 *   isBrace: false,
	 *   isBracket: false,
	 *   isGlob: true,
	 *   isExtglob: false,
	 *   isGlobstar: false,
	 *   negated: true }
	 * ```
	 * @param {String} `input` Glob pattern to scan.
	 * @param {Object} `options`
	 * @return {Object} Returns an object with
	 * @api public
	 */

	picomatch.scan = (input, options) => scan(input, options);

	/**
	 * Compile a regular expression from the `state` object returned by the
	 * [parse()](#parse) method.
	 *
	 * @param {Object} `state`
	 * @param {Object} `options`
	 * @param {Boolean} `returnOutput` Intended for implementors, this argument allows you to return the raw output from the parser.
	 * @param {Boolean} `returnState` Adds the state to a `state` property on the returned regex. Useful for implementors and debugging.
	 * @return {RegExp}
	 * @api public
	 */

	picomatch.compileRe = (state, options, returnOutput = false, returnState = false) => {
	  if (returnOutput === true) {
	    return state.output;
	  }

	  const opts = options || {};
	  const prepend = opts.contains ? '' : '^';
	  const append = opts.contains ? '' : '$';

	  let source = `${prepend}(?:${state.output})${append}`;
	  if (state && state.negated === true) {
	    source = `^(?!${source}).*$`;
	  }

	  const regex = picomatch.toRegex(source, options);
	  if (returnState === true) {
	    regex.state = state;
	  }

	  return regex;
	};

	/**
	 * Create a regular expression from a parsed glob pattern.
	 *
	 * ```js
	 * const picomatch = require('picomatch');
	 * const state = picomatch.parse('*.js');
	 * // picomatch.compileRe(state[, options]);
	 *
	 * console.log(picomatch.compileRe(state));
	 * //=> /^(?:(?!\.)(?=.)[^/]*?\.js)$/
	 * ```
	 * @param {String} `state` The object returned from the `.parse` method.
	 * @param {Object} `options`
	 * @param {Boolean} `returnOutput` Implementors may use this argument to return the compiled output, instead of a regular expression. This is not exposed on the options to prevent end-users from mutating the result.
	 * @param {Boolean} `returnState` Implementors may use this argument to return the state from the parsed glob with the returned regular expression.
	 * @return {RegExp} Returns a regex created from the given pattern.
	 * @api public
	 */

	picomatch.makeRe = (input, options = {}, returnOutput = false, returnState = false) => {
	  if (!input || typeof input !== 'string') {
	    throw new TypeError('Expected a non-empty string');
	  }

	  let parsed = { negated: false, fastpaths: true };

	  if (options.fastpaths !== false && (input[0] === '.' || input[0] === '*')) {
	    parsed.output = parse.fastpaths(input, options);
	  }

	  if (!parsed.output) {
	    parsed = parse(input, options);
	  }

	  return picomatch.compileRe(parsed, options, returnOutput, returnState);
	};

	/**
	 * Create a regular expression from the given regex source string.
	 *
	 * ```js
	 * const picomatch = require('picomatch');
	 * // picomatch.toRegex(source[, options]);
	 *
	 * const { output } = picomatch.parse('*.js');
	 * console.log(picomatch.toRegex(output));
	 * //=> /^(?:(?!\.)(?=.)[^/]*?\.js)$/
	 * ```
	 * @param {String} `source` Regular expression source string.
	 * @param {Object} `options`
	 * @return {RegExp}
	 * @api public
	 */

	picomatch.toRegex = (source, options) => {
	  try {
	    const opts = options || {};
	    return new RegExp(source, opts.flags || (opts.nocase ? 'i' : ''));
	  } catch (err) {
	    if (options && options.debug === true) throw err;
	    return /$^/;
	  }
	};

	/**
	 * Picomatch constants.
	 * @return {Object}
	 */

	picomatch.constants = constants;

	/**
	 * Expose "picomatch"
	 */

	picomatch_1 = picomatch;
	return picomatch_1;
}

var picomatch$1;
var hasRequiredPicomatch;

function requirePicomatch () {
	if (hasRequiredPicomatch) return picomatch$1;
	hasRequiredPicomatch = 1;

	picomatch$1 = requirePicomatch$1();
	return picomatch$1;
}

var picomatchExports = requirePicomatch();
var picomatch = /*@__PURE__*/getDefaultExportFromCjs(picomatchExports);

// src/index.ts
function normalizePaths(root, path) {
  return (Array.isArray(path) ? path : [path]).map((path2) => resolve(root, path2)).map(normalizePath);
}
var src_default = (paths, config = {}) => ({
  name: "vite-plugin-full-reload",
  apply: "serve",
  // NOTE: Enable globbing so that Vite keeps track of the template files.
  config: () => ({ server: { watch: { disableGlobbing: false } } }),
  configureServer({ watcher, ws, config: { logger } }) {
    const { root = process.cwd(), log = true, always = true, delay = 0 } = config;
    const files = normalizePaths(root, paths);
    const shouldReload = picomatch(files);
    const checkReload = (path) => {
      if (shouldReload(path)) {
        setTimeout(() => ws.send({ type: "full-reload", path: always ? "*" : path }), delay);
        if (log)
          logger.info(`${colors.green("full reload")} ${colors.dim(relative(root, path))}`, { clear: true, timestamp: true });
      }
    };
    watcher.add(files);
    watcher.on("add", checkReload);
    watcher.on("change", checkReload);
  }
});

let exitHandlersBound = false;
const refreshPaths = [
    "lib/**/*.ex",
    "lib/**/*.heex",
    "lib/**/*.eex",
    "lib/**/*.leex",
    "lib/**/*.sface",
    "priv/gettext/**/*.po",
].filter((path) => fs.existsSync(path.replace(/\*\*$/, "")));
function phoenix(config) {
    const pluginConfig = resolvePluginConfig(config);
    return [
        resolvePhoenixPlugin(pluginConfig),
        ...resolveFullReloadConfig(pluginConfig),
    ];
}
/**
 * Resolve the Phoenix plugin configuration.
 */
function resolvePluginConfig(config) {
    if (typeof config === "undefined") {
        throw new Error("phoenix-vite-plugin: Missing configuration. Please provide an input path or a configuration object.");
    }
    if (typeof config === "string" || Array.isArray(config)) {
        config = { input: config, ssr: config };
    }
    if (typeof config.input === "undefined") {
        throw new Error('phoenix-vite-plugin: Missing configuration for "input". Please specify the entry point(s) for your application.');
    }
    // Validate input paths exist
    const validateInputPath = (inputPath) => {
        const resolvedPath = path.resolve(process.cwd(), inputPath);
        if (!fs.existsSync(resolvedPath)) {
            console.warn(`${colors.yellow("Warning")}: Input file "${inputPath}" does not exist. Make sure to create it before running Vite.`);
        }
    };
    if (typeof config.input === "string") {
        validateInputPath(config.input);
    }
    else if (Array.isArray(config.input)) {
        config.input.forEach((input) => {
            if (typeof input === "string") {
                validateInputPath(input);
            }
        });
    }
    if (typeof config.publicDirectory === "string") {
        config.publicDirectory = config.publicDirectory.trim().replace(/^\/+/, "");
        if (config.publicDirectory === "") {
            throw new Error("phoenix-vite-plugin: publicDirectory must be a subdirectory. E.g. 'priv/static'. Got empty string after normalization.");
        }
        // Validate public directory exists
        const publicDirPath = path.resolve(process.cwd(), config.publicDirectory);
        if (!fs.existsSync(publicDirPath)) {
            console.warn(`${colors.yellow("Warning")}: Public directory "${config.publicDirectory}" does not exist. It will be created during build.`);
        }
    }
    if (config.publicDirectory === undefined) {
        config.publicDirectory = "priv/static";
    }
    if (typeof config.buildDirectory === "string") {
        config.buildDirectory = config.buildDirectory
            .trim()
            .replace(/^\/+/, "")
            .replace(/\/+$/, "");
        if (config.buildDirectory === "") {
            throw new Error("phoenix-vite-plugin: buildDirectory must be a subdirectory. E.g. 'assets'. Got empty string after normalization.");
        }
    }
    if (config.buildDirectory === undefined) {
        config.buildDirectory = "assets";
    }
    if (typeof config.ssrOutputDirectory === "string") {
        config.ssrOutputDirectory = config.ssrOutputDirectory
            .trim()
            .replace(/^\/+/, "")
            .replace(/\/+$/, "");
        if (config.ssrOutputDirectory === "") {
            throw new Error("phoenix-vite-plugin: ssrOutputDirectory must be a subdirectory. E.g. 'priv/ssr'. Got empty string after normalization.");
        }
    }
    if (config.ssrOutputDirectory === undefined) {
        config.ssrOutputDirectory = "priv/ssr";
    }
    if (config.hotFile === undefined) {
        config.hotFile = path.join("priv", "hot");
    }
    if (config.manifestPath === undefined) {
        config.manifestPath = path.join(config.publicDirectory, config.buildDirectory, "manifest.json");
    }
    if (config.ssr === undefined) {
        config.ssr = config.input;
    }
    if (config.reactRefresh === undefined) {
        config.reactRefresh = false;
    }
    if (config.refresh === true) {
        config.refresh = [{ paths: refreshPaths }];
    }
    if (config.refresh === undefined) {
        config.refresh = false;
    }
    if (config.detectTls === undefined) {
        config.detectTls = null;
    }
    // Log resolved configuration in verbose mode
    if (process.env.DEBUG || process.env.VERBOSE) {
        console.log(colors.dim("Phoenix Vite Plugin - Resolved Configuration:"));
        console.log(colors.dim(JSON.stringify({
            publicDirectory: config.publicDirectory,
            buildDirectory: config.buildDirectory,
            hotFile: config.hotFile,
            detectTls: config.detectTls,
        }, null, 2)));
    }
    return {
        input: config.input,
        publicDirectory: config.publicDirectory,
        buildDirectory: config.buildDirectory,
        ssr: config.ssr,
        ssrOutputDirectory: config.ssrOutputDirectory,
        refresh: config.refresh,
        hotFile: config.hotFile,
        manifestPath: config.manifestPath,
        reactRefresh: config.reactRefresh,
        detectTls: config.detectTls,
        transformOnServe: config.transformOnServe ?? ((code) => code),
    };
}
/**
 * Resolve the Phoenix plugin.
 */
function resolvePhoenixPlugin(pluginConfig) {
    let viteDevServerUrl;
    let resolvedConfig;
    let userConfig;
    const defaultAliases = {
        "@": path.resolve(process.cwd(), "assets/js"),
    };
    // Check for Phoenix ESM files and use them if available
    const phoenixAliases = {};
    const depsPath = path.resolve(process.cwd(), "../deps");
    // Check for phoenix.mjs
    if (fs.existsSync(path.join(depsPath, "phoenix/priv/static/phoenix.mjs"))) {
        phoenixAliases["phoenix"] = path.join(depsPath, "phoenix/priv/static/phoenix.mjs");
    }
    else if (fs.existsSync(path.join(depsPath, "phoenix/priv/static/phoenix.js"))) {
        phoenixAliases["phoenix"] = path.join(depsPath, "phoenix/priv/static/phoenix.js");
    }
    // Always use phoenix_html.js (no ESM version exists)
    if (fs.existsSync(path.join(depsPath, "phoenix_html/priv/static/phoenix_html.js"))) {
        phoenixAliases["phoenix_html"] = path.join(depsPath, "phoenix_html/priv/static/phoenix_html.js");
    }
    // Check for phoenix_live_view.esm.js
    if (fs.existsSync(path.join(depsPath, "phoenix_live_view/priv/static/phoenix_live_view.esm.js"))) {
        phoenixAliases["phoenix_live_view"] = path.join(depsPath, "phoenix_live_view/priv/static/phoenix_live_view.esm.js");
    }
    else if (fs.existsSync(path.join(depsPath, "phoenix_live_view/priv/static/phoenix_live_view.js"))) {
        phoenixAliases["phoenix_live_view"] = path.join(depsPath, "phoenix_live_view/priv/static/phoenix_live_view.js");
    }
    return {
        name: "phoenix",
        enforce: "post",
        config: (config, env) => {
            userConfig = config;
            const ssr = !!userConfig.build?.ssr;
            const environment = loadEnv(env.mode, userConfig.envDir || process.cwd(), "");
            const assetUrl = environment.ASSET_URL ?? "assets";
            const serverConfig = env.command === "serve"
                ? (resolveDevelopmentEnvironmentServerConfig(pluginConfig.detectTls, environment) ??
                    resolveEnvironmentServerConfig(environment))
                : undefined;
            ensureCommandShouldRunInEnvironment(env.command, environment);
            // Warn about common configuration issues
            if (env.command === "serve") {
                checkCommonConfigurationIssues(pluginConfig, environment, userConfig);
            }
            return {
                base: userConfig.base ?? (env.command === "build" ? resolveBase(pluginConfig, assetUrl) : ""),
                publicDir: userConfig.publicDir ?? false,
                build: {
                    manifest: userConfig.build?.manifest ?? (ssr ? false : true),
                    ssrManifest: userConfig.build?.ssrManifest ?? (ssr ? "ssr-manifest.json" : false),
                    outDir: userConfig.build?.outDir ?? resolveOutDir(pluginConfig, ssr),
                    emptyOutDir: false,
                    rollupOptions: {
                        input: userConfig.build?.rollupOptions?.input ?? resolveInput(pluginConfig, ssr),
                    },
                    assetsInlineLimit: userConfig.build?.assetsInlineLimit ?? 0,
                },
                resolve: {
                    alias: Array.isArray(userConfig?.resolve?.alias)
                        ? [
                            ...userConfig.resolve.alias,
                            ...Object.entries(defaultAliases).map(([find, replacement]) => ({ find, replacement })),
                            ...Object.entries(phoenixAliases).map(([find, replacement]) => ({ find, replacement })),
                        ]
                        : {
                            ...defaultAliases,
                            ...phoenixAliases,
                            ...userConfig?.resolve?.alias,
                        },
                },
                ssr: {
                    noExternal: noExternalInertiaHelpers(userConfig),
                },
                optimizeDeps: {
                    entries: Array.isArray(pluginConfig.input)
                        ? pluginConfig.input.filter((entry) => typeof entry === "string")
                        : typeof pluginConfig.input === "string"
                            ? [pluginConfig.input]
                            : undefined,
                    include: [
                        "phoenix",
                        "phoenix_html",
                        "phoenix_live_view",
                        ...(userConfig?.optimizeDeps?.include || []),
                    ],
                },
                server: {
                    origin: userConfig?.server?.origin ?? "http://__phoenix_vite_placeholder__.test",
                    cors: userConfig?.server?.cors ?? {
                        origin: userConfig?.server?.origin ?? [
                            // Default patterns for localhost (IPv4, IPv6)
                            /^https?:\/\/(?:(?:[^:]+\.)?localhost|127\.0\.0\.1|\[::1\])(?::\d+)?$/, // Copied from Vite itself
                            // Phoenix app URL from environment
                            ...(environment.PHX_HOST ? [
                                environment.PHX_HOST.startsWith("http://") || environment.PHX_HOST.startsWith("https://")
                                    ? environment.PHX_HOST
                                    : `http://${environment.PHX_HOST}`
                            ] : []),
                            // Common local development patterns
                            /^https?:\/\/.*\.test(?::\d+)?$/, // *.test domains (common for local dev)
                            /^https?:\/\/.*\.local(?::\d+)?$/, // *.local domains
                            /^https?:\/\/.*\.localhost(?::\d+)?$/, // *.localhost subdomains
                        ],
                    },
                    // Handle Docker/container environments
                    ...(environment.PHOENIX_DOCKER || environment.DOCKER_ENV ? {
                        host: userConfig?.server?.host ?? "0.0.0.0",
                        port: userConfig?.server?.port ?? (environment.VITE_PORT ? parseInt(environment.VITE_PORT) : 5173),
                        strictPort: userConfig?.server?.strictPort ?? true,
                    } : undefined),
                    ...(serverConfig
                        ? {
                            host: userConfig?.server?.host ?? serverConfig.host,
                            hmr: userConfig?.server?.hmr === false
                                ? false
                                : {
                                    ...serverConfig.hmr,
                                    ...(userConfig?.server?.hmr === true
                                        ? {}
                                        : userConfig?.server?.hmr),
                                },
                            https: userConfig?.server?.https ?? serverConfig.https,
                        }
                        : {
                            hmr: userConfig?.server?.hmr === false
                                ? false
                                : {
                                    ...(typeof userConfig?.server?.hmr === "object"
                                        ? userConfig.server.hmr
                                        : {}),
                                },
                        }),
                },
            };
        },
        configResolved(config) {
            resolvedConfig = config;
        },
        transform(code) {
            if (resolvedConfig.command === "serve") {
                code = code.replace(/http:\/\/__phoenix_vite_placeholder__\.test/g, viteDevServerUrl);
                if (pluginConfig.transformOnServe) {
                    return pluginConfig.transformOnServe(code, viteDevServerUrl);
                }
            }
            return code;
        },
        configureServer(server) {
            const envDir = server.config.envDir || process.cwd();
            const phxHost = loadEnv(server.config.mode, envDir, "PHX_HOST").PHX_HOST ?? "undefined";
            server.httpServer?.once("listening", () => {
                const address = server.httpServer?.address();
                const isAddressInfo = (x) => typeof x === "object";
                if (isAddressInfo(address)) {
                    viteDevServerUrl = userConfig.server?.origin
                        ? userConfig.server.origin
                        : resolveDevServerUrl(address, server.config, userConfig);
                    // Write hot file with error handling
                    try {
                        const hotContent = `${viteDevServerUrl}${server.config.base.replace(/\/$/, "")}`;
                        const hotDir = path.dirname(pluginConfig.hotFile);
                        if (!fs.existsSync(hotDir)) {
                            fs.mkdirSync(hotDir, { recursive: true });
                        }
                        fs.writeFileSync(pluginConfig.hotFile, hotContent);
                        if (process.env.DEBUG || process.env.VERBOSE) {
                            console.log(colors.dim(`Hot file written to: ${pluginConfig.hotFile}`));
                        }
                    }
                    catch (error) {
                        console.error(`\n${colors.red("Error")}: Failed to write hot file.\n` +
                            `Path: ${pluginConfig.hotFile}\n` +
                            `Error: ${error instanceof Error ? error.message : String(error)}\n` +
                            `This may prevent Phoenix from detecting the Vite dev server.\n`);
                    }
                    setTimeout(() => {
                        const phoenixVer = phoenixVersion();
                        const pluginVer = pluginVersion();
                        server.config.logger.info(`\n  ${colors.red(`${colors.bold("PHOENIX")} ${phoenixVer !== "unknown" ? phoenixVer : ""}`)}  ${colors.dim("plugin")} ${colors.bold(`v${pluginVer}`)}`);
                        server.config.logger.info("");
                        server.config.logger.info(`  ${colors.green("➜")}  ${colors.bold("PHX_HOST")}: ${colors.cyan(phxHost.replace(/:(\d+)/, (_, port) => `:${colors.bold(port)}`))}`);
                        if (typeof resolvedConfig.server.https === "object" &&
                            typeof resolvedConfig.server.https.key === "string") {
                            // Log certificate source with detailed info
                            if (pluginConfig.detectTls) {
                                if (resolvedConfig.server.https.key.includes("mkcert")) {
                                    server.config.logger.info(`  ${colors.green("➜")}  Using mkcert certificate to secure Vite.`);
                                }
                                else if (resolvedConfig.server.https.key.includes("caddy")) {
                                    server.config.logger.info(`  ${colors.green("➜")}  Using Caddy certificate to secure Vite.`);
                                }
                                else if (resolvedConfig.server.https.key.includes("priv/cert")) {
                                    server.config.logger.info(`  ${colors.green("➜")}  Using project certificate to secure Vite.`);
                                }
                                else {
                                    server.config.logger.info(`  ${colors.green("➜")}  Using custom certificate to secure Vite.`);
                                }
                            }
                            else {
                                server.config.logger.info(`  ${colors.green("➜")}  Using TLS certificate to secure Vite.`);
                            }
                        }
                        // Add hot reload paths info if refresh is enabled
                        if (pluginConfig.refresh !== false) {
                            const refreshCount = Array.isArray(pluginConfig.refresh)
                                ? pluginConfig.refresh.reduce((acc, cfg) => acc + cfg.paths.length, 0)
                                : 0;
                            if (refreshCount > 0) {
                                server.config.logger.info(`  ${colors.green("➜")}  Full reload enabled for ${refreshCount} file pattern(s)`);
                            }
                        }
                        // Log the development server URL last
                        server.config.logger.info("");
                        server.config.logger.info(`  ${colors.green("➜")}  ${colors.bold("Dev Server")}: ${colors.cyan(viteDevServerUrl.replace(/:(\d+)/, (_, port) => `:${colors.bold(port)}`))}\n`);
                    }, 100);
                }
            });
            if (!exitHandlersBound) {
                const clean = () => {
                    if (fs.existsSync(pluginConfig.hotFile)) {
                        try {
                            fs.rmSync(pluginConfig.hotFile);
                            if (process.env.DEBUG || process.env.VERBOSE) {
                                console.log(colors.dim(`Hot file cleaned up: ${pluginConfig.hotFile}`));
                            }
                        }
                        catch (error) {
                            // Ignore cleanup errors - the file might already be deleted
                            if (process.env.DEBUG || process.env.VERBOSE) {
                                console.log(colors.dim(`Could not clean up hot file: ${error instanceof Error ? error.message : String(error)}`));
                            }
                        }
                    }
                };
                process.on("exit", clean);
                process.on("SIGINT", () => {
                    console.log(colors.dim("\nShutting down Vite..."));
                    process.exit();
                });
                process.on("SIGTERM", () => process.exit());
                process.on("SIGHUP", () => process.exit());
                // Terminate the watcher when Phoenix quits
                process.stdin.on("close", () => {
                    if (process.env.DEBUG || process.env.VERBOSE) {
                        console.log(colors.dim("Phoenix process closed, shutting down Vite..."));
                    }
                    process.exit(0);
                });
                process.stdin.resume();
                exitHandlersBound = true;
            }
            return () => server.middlewares.use((req, res, next) => {
                if (req.url === "/index.html") {
                    res.statusCode = 404;
                    res.end(fs
                        .readFileSync(new URL("./dev-server-index.html", import.meta.url))
                        .toString()
                        .replace(/{{ PHOENIX_VERSION }}/g, phoenixVersion()));
                }
                next();
            });
        },
        generateBundle(_options, bundle) {
            // Only generate manifest for non-SSR builds
            if (!resolvedConfig.build.ssr) {
                try {
                    const manifestChunks = Object.values(bundle)
                        .filter((chunk) => chunk.type === "chunk" && chunk.isEntry)
                        .map((chunk) => ({
                        file: chunk.fileName,
                        name: chunk.name || "",
                        src: chunk.facadeModuleId || undefined,
                        isEntry: true,
                        imports: chunk.imports,
                        css: Array.from(chunk.viteMetadata?.importedCss || []),
                        assets: Array.from(chunk.viteMetadata?.importedAssets || []),
                    }));
                    const manifest = manifestChunks.reduce((manifest, chunk) => {
                        if (chunk.src) {
                            const assetPath = toPhoenixAssetPath(chunk.src);
                            manifest[assetPath] = chunk;
                        }
                        return manifest;
                    }, {});
                    const manifestContent = JSON.stringify(manifest, null, 2);
                    const manifestDir = path.dirname(pluginConfig.manifestPath);
                    // Ensure manifest directory exists
                    if (!fs.existsSync(manifestDir)) {
                        if (process.env.DEBUG || process.env.VERBOSE) {
                            console.log(colors.dim(`Creating manifest directory: ${manifestDir}`));
                        }
                        fs.mkdirSync(manifestDir, { recursive: true });
                    }
                    fs.writeFileSync(pluginConfig.manifestPath, manifestContent);
                    if (process.env.DEBUG || process.env.VERBOSE) {
                        console.log(colors.dim(`Manifest written to: ${pluginConfig.manifestPath}`));
                        console.log(colors.dim(`Manifest entries: ${Object.keys(manifest).length}`));
                    }
                }
                catch (error) {
                    console.error(`\n${colors.red("Error")}: Failed to generate manifest file.\n` +
                        `Path: ${pluginConfig.manifestPath}\n` +
                        `Error: ${error instanceof Error ? error.message : String(error)}\n`);
                    throw error;
                }
            }
        },
    };
}
/**
 * Check for common configuration issues and warn the user.
 */
function checkCommonConfigurationIssues(pluginConfig, env, userConfig) {
    // Check if PHX_HOST is not set
    if (!env.PHX_HOST) {
        console.warn(`\n${colors.yellow("Warning")}: PHX_HOST environment variable is not set.\n` +
            `This may cause CORS issues when accessing your Phoenix app.\n` +
            `Set it in your .env file or shell: export PHX_HOST=localhost:4000\n`);
    }
    // Check for potential port conflicts
    const vitePort = userConfig.server?.port ?? (env.VITE_PORT ? parseInt(env.VITE_PORT) : 5173);
    if (env.PHX_HOST && env.PHX_HOST.includes(`:${vitePort}`)) {
        console.warn(`\n${colors.yellow("Warning")}: PHX_HOST (${env.PHX_HOST}) is using the same port as Vite (${vitePort}).\n` +
            `This will cause conflicts. Phoenix and Vite must run on different ports.\n`);
    }
    // Check if running in WSL without proper host configuration
    if (process.platform === "linux" && env.WSL_DISTRO_NAME && !userConfig.server?.host) {
        console.warn(`\n${colors.yellow("Warning")}: Running in WSL without explicit host configuration.\n` +
            `You may need to set server.host to '0.0.0.0' in your vite.config.js for proper access from Windows.\n`);
    }
    // Check for missing Phoenix dependencies
    const depsPath = path.resolve(process.cwd(), "../deps");
    if (!fs.existsSync(depsPath)) {
        console.warn(`\n${colors.yellow("Warning")}: Phoenix deps directory not found at ${depsPath}.\n` +
            `Make sure you're running Vite from the correct directory (usually the 'assets' folder).\n`);
    }
    // Warn if hot file directory doesn't exist
    const hotFileDir = path.dirname(pluginConfig.hotFile);
    if (!fs.existsSync(hotFileDir)) {
        console.warn(`\n${colors.yellow("Warning")}: Hot file directory "${hotFileDir}" does not exist.\n` +
            `Creating directory to prevent errors...\n`);
        fs.mkdirSync(hotFileDir, { recursive: true });
    }
    // Check for React configuration issues
    if (pluginConfig.reactRefresh && !userConfig.plugins?.some(p => typeof p === "object" && p !== null && "name" in p && p.name === "@vitejs/plugin-react")) {
        console.warn(`\n${colors.yellow("Warning")}: reactRefresh is enabled but @vitejs/plugin-react is not detected.\n` +
            `Install and configure @vitejs/plugin-react for React refresh to work properly.\n`);
    }
    // Warn about SSL in non-development environments
    if (env.MIX_ENV && env.MIX_ENV !== "dev" && (pluginConfig.detectTls || env.VITE_DEV_SERVER_KEY)) {
        console.warn(`\n${colors.yellow("Warning")}: TLS/SSL is configured but MIX_ENV is set to "${env.MIX_ENV}".\n` +
            `TLS is typically only needed in development. Consider disabling it for other environments.\n`);
    }
}
/**
 * Validate the command can run in the given environment.
 */
function ensureCommandShouldRunInEnvironment(command, env) {
    if (command === "build" || env.PHOENIX_BYPASS_ENV_CHECK === "1") {
        return;
    }
    // Check for CI environments
    if (typeof env.CI !== "undefined") {
        throw new Error("You should not run the Vite HMR server in CI environments. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1");
    }
    // Check for production deployment indicators
    if (env.MIX_ENV === "prod" || env.NODE_ENV === "production") {
        throw new Error("You should not run the Vite HMR server in production. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1");
    }
    // Check for Fly.io deployment
    if (typeof env.FLY_APP_NAME !== "undefined") {
        throw new Error("You should not run the Vite HMR server on Fly.io. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1");
    }
    // Check for Gigalixir deployment
    if (typeof env.GIGALIXIR_APP_NAME !== "undefined") {
        throw new Error("You should not run the Vite HMR server on Gigalixir. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1");
    }
    // Check for Heroku deployment
    if (typeof env.DYNO !== "undefined" && typeof env.HEROKU_APP_NAME !== "undefined") {
        throw new Error("You should not run the Vite HMR server on Heroku. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1");
    }
    // Check for Render deployment
    if (typeof env.RENDER !== "undefined") {
        throw new Error("You should not run the Vite HMR server on Render. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1");
    }
    // Check for Railway deployment
    if (typeof env.RAILWAY_ENVIRONMENT !== "undefined") {
        throw new Error("You should not run the Vite HMR server on Railway. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1");
    }
    // Check for running in ExUnit tests
    if (env.MIX_ENV === "test" && typeof env.PHOENIX_INTEGRATION_TEST === "undefined") {
        throw new Error("You should not run the Vite HMR server in the test environment. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1 or PHOENIX_INTEGRATION_TEST=1 for integration tests that need the dev server.");
    }
    // Check for Docker production environments
    if (typeof env.DOCKER_ENV !== "undefined" && env.DOCKER_ENV === "production") {
        throw new Error("You should not run the Vite HMR server in production Docker containers. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1");
    }
    // Check for release mode
    if (typeof env.RELEASE_NAME !== "undefined" || typeof env.RELEASE_NODE !== "undefined") {
        throw new Error("You should not run the Vite HMR server in an Elixir release. You should build your assets for production instead. To disable this ENV check you may set PHOENIX_BYPASS_ENV_CHECK=1");
    }
}
function toPhoenixAssetPath(filename) {
    filename = path.relative(process.cwd(), filename);
    if (filename.startsWith("assets/")) {
        filename = filename.slice("assets/".length);
    }
    return filename;
}
/**
 * The version of Phoenix being run.
 */
function phoenixVersion() {
    try {
        // Try to find mix.exs in common locations
        const possiblePaths = [
            path.join(process.cwd(), "mix.exs"),
            path.join(process.cwd(), "../mix.exs"),
            path.join(process.cwd(), "../../mix.exs"),
        ];
        for (const mixExsPath of possiblePaths) {
            if (fs.existsSync(mixExsPath)) {
                const content = fs.readFileSync(mixExsPath, "utf-8");
                // Look for app version
                const versionMatch = content.match(/version:\s*"([^"]+)"/);
                if (versionMatch) {
                    return versionMatch[1];
                }
                // Look for Phoenix dependency version
                const phoenixMatch = content.match(/{:phoenix,\s*"~>\s*([^"]+)"/);
                if (phoenixMatch) {
                    return `~${phoenixMatch[1]}`;
                }
            }
        }
    }
    catch (error) {
        if (process.env.DEBUG || process.env.VERBOSE) {
            console.log(colors.dim(`Could not read Phoenix version: ${error instanceof Error ? error.message : String(error)}`));
        }
    }
    return "unknown";
}
/**
 * The version of the Phoenix Vite plugin being run.
 */
function pluginVersion() {
    try {
        const currentDir = path.dirname(new URL(import.meta.url).pathname);
        // Try different paths to find package.json
        const possiblePaths = [
            path.join(currentDir, "../package.json"), // When running from dist/
            path.join(currentDir, "../../package.json"), // When running from src/
        ];
        for (const packageJsonPath of possiblePaths) {
            if (fs.existsSync(packageJsonPath)) {
                const packageJson = JSON.parse(fs.readFileSync(packageJsonPath).toString());
                return packageJson.version || "unknown";
            }
        }
    }
    catch {
        // Ignore errors
    }
    return "unknown";
}
function resolveFullReloadConfig({ refresh: config, }) {
    if (typeof config === "boolean") {
        return [];
    }
    if (typeof config === "string") {
        config = [{ paths: [config] }];
    }
    if (!Array.isArray(config)) {
        config = [config];
    }
    if (config.some((c) => typeof c === "string")) {
        config = [{ paths: config }];
    }
    return config.flatMap((c) => {
        const plugin = src_default(c.paths, c.config);
        /* eslint-disable-next-line @typescript-eslint/ban-ts-comment */
        /** @ts-ignore */
        plugin.__phoenix_plugin_config = c;
        return plugin;
    });
}
/**
 * Resolve the server config from the environment.
 */
function resolveEnvironmentServerConfig(env) {
    if (!env.VITE_DEV_SERVER_KEY && !env.VITE_DEV_SERVER_CERT) {
        return;
    }
    // Check if only one certificate path is provided
    if (!env.VITE_DEV_SERVER_KEY || !env.VITE_DEV_SERVER_CERT) {
        throw new Error(`Phoenix Vite Plugin: Both VITE_DEV_SERVER_KEY and VITE_DEV_SERVER_CERT must be provided. ` +
            `Currently provided: KEY=${env.VITE_DEV_SERVER_KEY ? "✓" : "✗"}, CERT=${env.VITE_DEV_SERVER_CERT ? "✓" : "✗"}`);
    }
    // Validate certificate files exist
    const missingFiles = [];
    if (!fs.existsSync(env.VITE_DEV_SERVER_KEY)) {
        missingFiles.push(`Key file not found: ${env.VITE_DEV_SERVER_KEY}`);
    }
    if (!fs.existsSync(env.VITE_DEV_SERVER_CERT)) {
        missingFiles.push(`Certificate file not found: ${env.VITE_DEV_SERVER_CERT}`);
    }
    if (missingFiles.length > 0) {
        throw new Error(`Phoenix Vite Plugin: Unable to find the certificate files specified in your environment.\n` +
            missingFiles.join("\n") + "\n" +
            `Please ensure the paths are correct and the files exist.`);
    }
    const host = resolveHostFromEnv(env);
    if (!host) {
        throw new Error(`Phoenix Vite Plugin: Unable to determine the host from the environment.\n` +
            `PHX_HOST is set to: ${env.PHX_HOST ? `"${env.PHX_HOST}"` : "(not set)"}\n` +
            `Please set PHX_HOST to a valid hostname or URL (e.g., "localhost", "myapp.test", or "https://myapp.test").`);
    }
    return {
        hmr: { host },
        host,
        https: {
            key: fs.readFileSync(env.VITE_DEV_SERVER_KEY),
            cert: fs.readFileSync(env.VITE_DEV_SERVER_CERT),
        },
    };
}
/**
 * Resolve the host name from the environment.
 */
function resolveHostFromEnv(env) {
    // Phoenix apps typically use PHX_HOST for the hostname
    if (env.PHX_HOST) {
        try {
            // If PHX_HOST contains a full URL, extract the host
            if (env.PHX_HOST.startsWith("http://") || env.PHX_HOST.startsWith("https://")) {
                return new URL(env.PHX_HOST).host;
            }
            // Otherwise, use it as is
            return env.PHX_HOST;
        }
        catch {
            return;
        }
    }
    return;
}
/**
 * Resolve the dev server URL from the server address and configuration.
 */
function resolveDevServerUrl(address, config, userConfig) {
    const configHmrProtocol = typeof config.server.hmr === "object" ? config.server.hmr.protocol : null;
    const clientProtocol = configHmrProtocol ? (configHmrProtocol === "wss" ? "https" : "http") : null;
    const serverProtocol = config.server.https ? "https" : "http";
    const protocol = clientProtocol ?? serverProtocol;
    const configHmrHost = typeof config.server.hmr === "object" ? config.server.hmr.host : null;
    const configHost = typeof config.server.host === "string" ? config.server.host : null;
    const dockerHost = process.env.PHOENIX_DOCKER && !userConfig.server?.host ? "localhost" : null;
    const serverAddress = isIpv6(address) ? `[${address.address}]` : address.address;
    const host = configHmrHost ?? dockerHost ?? configHost ?? serverAddress;
    const configHmrClientPort = typeof config.server.hmr === "object" ? config.server.hmr.clientPort : null;
    const port = configHmrClientPort ?? address.port;
    return `${protocol}://${host}:${port}`;
}
function isIpv6(address) {
    return address.family === "IPv6"
        // In node >=18.0 <18.4 this was an integer value. This was changed in a minor version.
        // See: https://github.com/laravel/vite-plugin/issues/103
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore-next-line
        || address.family === 6;
}
/**
 * Resolve the Vite base option from the configuration.
 */
function resolveBase(config, assetUrl) {
    return "/" + assetUrl + "/";
}
/**
 * Resolve the Vite input path from the configuration.
 */
function resolveInput(config, ssr) {
    if (ssr) {
        return config.ssr;
    }
    // Convert string arrays to proper rollup input format
    if (Array.isArray(config.input)) {
        return config.input.map((entry) => path.resolve(process.cwd(), entry));
    }
    if (typeof config.input === "string") {
        return path.resolve(process.cwd(), config.input);
    }
    return config.input;
}
/**
 * Resolve the Vite outDir path from the configuration.
 */
function resolveOutDir(config, ssr) {
    if (ssr) {
        return config.ssrOutputDirectory;
    }
    return path.join(config.publicDirectory, config.buildDirectory);
}
/**
 * Add the Inertia helpers to the list of SSR dependencies that aren't externalized.
 *
 * @see https://vitejs.dev/guide/ssr.html#ssr-externals
 */
function noExternalInertiaHelpers(config) {
    /* eslint-disable-next-line @typescript-eslint/ban-ts-comment */
    /* @ts-ignore */
    const userNoExternal = config.ssr?.noExternal;
    const pluginNoExternal = ["phoenix-vite-plugin"];
    if (userNoExternal === true) {
        return true;
    }
    if (typeof userNoExternal === "undefined") {
        return pluginNoExternal;
    }
    return [
        ...(Array.isArray(userNoExternal) ? userNoExternal : [userNoExternal]),
        ...pluginNoExternal,
    ];
}
/**
 * Resolve the server config for local development environments with TLS support.
 * This function attempts to detect and use certificates from local development tools.
 */
function resolveDevelopmentEnvironmentServerConfig(detectTls, env) {
    if (detectTls === false) {
        return;
    }
    // Use PHX_HOST from environment if available
    const phxHost = env.PHX_HOST;
    if (!phxHost && detectTls === null) {
        return;
    }
    const resolvedHost = detectTls === true || detectTls === null
        ? phxHost || "localhost"
        : detectTls;
    // Check for common certificate locations
    const homeDir = os.homedir();
    const searchPaths = [];
    const possibleCertPaths = [
        // mkcert default location (cross-platform)
        {
            key: path.join(homeDir, ".local/share/mkcert", `${resolvedHost}-key.pem`),
            cert: path.join(homeDir, ".local/share/mkcert", `${resolvedHost}.pem`),
            name: "mkcert",
        },
        // mkcert on macOS
        {
            key: path.join(homeDir, "Library/Application Support/mkcert", `${resolvedHost}-key.pem`),
            cert: path.join(homeDir, "Library/Application Support/mkcert", `${resolvedHost}.pem`),
            name: "mkcert (macOS)",
        },
        // Caddy certificates location
        {
            key: path.join(homeDir, ".local/share/caddy/certificates/local", `${resolvedHost}`, `${resolvedHost}.key`),
            cert: path.join(homeDir, ".local/share/caddy/certificates/local", `${resolvedHost}`, `${resolvedHost}.crt`),
            name: "Caddy",
        },
        // Generic location in project
        {
            key: path.join(process.cwd(), "priv/cert", `${resolvedHost}-key.pem`),
            cert: path.join(process.cwd(), "priv/cert", `${resolvedHost}.pem`),
            name: "project (priv/cert)",
        },
        {
            key: path.join(process.cwd(), "priv/cert", `${resolvedHost}.key`),
            cert: path.join(process.cwd(), "priv/cert", `${resolvedHost}.crt`),
            name: "project (priv/cert)",
        },
        // Additional common project locations
        {
            key: path.join(process.cwd(), "certs", `${resolvedHost}-key.pem`),
            cert: path.join(process.cwd(), "certs", `${resolvedHost}.pem`),
            name: "project (certs/)",
        },
        {
            key: path.join(process.cwd(), "certs", `${resolvedHost}.key`),
            cert: path.join(process.cwd(), "certs", `${resolvedHost}.crt`),
            name: "project (certs/)",
        },
    ];
    for (const certPath of possibleCertPaths) {
        searchPaths.push(`${certPath.name}: ${path.dirname(certPath.cert)}`);
        if (fs.existsSync(certPath.key) && fs.existsSync(certPath.cert)) {
            if (process.env.DEBUG || process.env.VERBOSE) {
                console.log(colors.dim(`Found TLS certificates in ${certPath.name} location`));
            }
            return {
                hmr: { host: resolvedHost },
                host: resolvedHost,
                https: {
                    key: certPath.key,
                    cert: certPath.cert,
                },
            };
        }
    }
    // If detectTls was explicitly requested but no certs found
    if (detectTls !== null) {
        const uniquePaths = [...new Set(searchPaths)];
        console.warn(`\n${colors.yellow("Warning")}: Unable to find TLS certificate files for host "${resolvedHost}".\n\n` +
            `Searched in the following locations:\n` +
            uniquePaths.map(p => `  - ${p}`).join("\n") + "\n\n" +
            `To generate local certificates, you can use mkcert:\n` +
            `  ${colors.dim("$")} brew install mkcert  ${colors.dim("# Install mkcert (macOS)")}\n` +
            `  ${colors.dim("$")} mkcert -install        ${colors.dim("# Install local CA")}\n` +
            `  ${colors.dim("$")} mkcert ${resolvedHost}  ${colors.dim("# Generate certificate")}\n` +
            `  ${colors.dim("$")} mkdir -p priv/cert     ${colors.dim("# Create cert directory")}\n` +
            `  ${colors.dim("$")} mv ${resolvedHost}*.pem priv/cert/  ${colors.dim("# Move certificates")}\n\n` +
            `Or set detectTls: false in your vite.config.js to disable TLS detection.\n`);
    }
    return;
}

export { phoenix as default, phoenix, refreshPaths };
