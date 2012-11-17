" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:yavimim = {}
let s:yavimim.metadatas = {'wubi': {'full': '五笔', 'short': '五'},
			\ 'pinyin': {'full': '拼音', 'short': '拼'}}

function! s:wbqq_spliter(string)
	" '你好vb' => ['你好', 'vb']
	let l:first = ''
	let l:second = ''
	let l:start = -1
	let l:index = 0
	while l:index < len(a:string)
		let l:char = a:string[l:index]
		if l:char =~ '[a-z]'
			let l:second .= l:char
		else
			let l:first .= l:char
		endif
		let l:index += 1
	endwhile
	return [l:first, l:second]
endfunction

function! yavimim#backend#has(key)
	let im = s:yavimim.im
	let lines = s:getlines(im)
	if im.type == 'wubi'
		if im.id == 'qq'
			let index = s:find_sorted_idx(lines, a:key)
		else
			let index = s:find_sorted_match(lines, a:key, 0, len(lines) - 1)
		endif
	elseif im.type == 'pinyin'
	else
	endif
	return index == -1 ? 0 : 1
endfunction

function! yavimim#backend#matches(key, mode)
	let im = s:yavimim.im
	let lines = s:getlines(im)
	let words = []
	if im.type == 'wubi'
		if im.id == 'qq'
			let index = s:find_sorted_idx(lines, a:key)
			if index == -1
				return []
			endif
			let line = s:encoding(lines[index])
			let parts = split(line, '\s\+')
			call remove(parts, 0)
			let matches = s:matches(parts, a:mode)
			let g:yavimim_only = len(matches) == 1 ? 1 : 0
			for match in matches
				let [word, tip] = s:wbqq_spliter(match)
				call add(words, {'word': word, 'tip': tip, 'kind': ''})
			endfor
			let total_nr = s:total_nr(len(parts), a:mode)
		else
			let range = s:sorted_matches_range(lines, a:key)
			if range == [-1, -1]
				return []
			endif
			let length = range[1] - range[0] + 1
			let matches = s:matches_wbpy(lines, range, a:mode)
			let g:yavimim_only = len(matches) == 1 ? 1 : 0
			for match in matches
				let [tip, word] = split(match)
				let kind = tip[0] == '@' ? '[拼]' : ''
				let offset = tip[0] == '@' ? 1 : 0
				let tip = tip[(len(a:key) + offset) : ]
				call add(words, {'word': word, 'tip': tip, 'kind': kind})
			endfor
			let total_nr = s:total_nr(length, a:mode)
		endif
	else
	endif
	" @TODO: 简繁转换
	if a:mode == 'insert'
		" @TODO: %S
		call s:data_omni(words)
		if total_nr != 1
			let words[0].kind .= printf("%d/%d", b:yavimim.page_nr, total_nr)
		endif
	else
		let g:_yavimim_total_nr = total_nr
	endif
	return words
endfunction

function! yavimim#backend#cmdline_total_nr()
	return s:cmdline_total_nr
endfunction

function! s:data_omni(list)
	let label = 1
	for item in a:list
		let item.abbr = printf("%d.%s%s", label % 10, item.word, item.tip)
		let item.dup = 1
		let label += 1
	endfor
endfunction

function! s:matches(list, mode)
		let total_nr = s:total_nr(len(a:list), a:mode)
		let page_nr = a:mode == 'insert' ?
					\ b:yavimim.page_nr : g:_yavimim_page_nr
		if page_nr < 1
			let page_nr = total_nr
		elseif page_nr > total_nr
			let page_nr = 1
		endif
		if a:mode == 'insert'
			let b:yavimim.page_nr = page_nr
		else
			let g:_yavimim_page_nr = page_nr
		endif
		" @TODO: pumheight
		let one = (page_nr - 1) * &pumheight
		let two = one + &pumheight - 1
		return a:list[one : two]
endfunction

function! s:matches_wbpy(list, range, mode)
	let length = a:range[1] - a:range[0] + 1
	let total_nr = s:total_nr(length, a:mode)
	let page_nr = a:mode == 'insert' ? b:yavimim.page_nr : g:_yavimim_page_nr
	let num = a:mode == 'insert' ? &pumheight : 5
	if page_nr < 1
		let page_nr = total_nr
	elseif page_nr > total_nr
		let page_nr = 1
	endif
	if a:mode == 'insert'
		let b:yavimim.page_nr = page_nr
	else
		let g:_yavimim_page_nr = page_nr
	endif
	" @TODO: pumheight
	let one = (page_nr - 1) * num + a:range[0]
	let two = one + num - 1
	let two = two > a:range[1] ? a:range[1] : two
	return a:list[one : two]
endfunction

function! s:total_nr(length, mode)
	let num = a:mode == 'insert' ? &pumheight : 5
	return float2nr(ceil(a:length / yavimim#util#nr2float(num)))
endfunction

function! yavimim#backend#title()
endfunction

function! s:getlines(im)
	let cht = ''
	if exists('g:yavimim_traditional') && g:yavimim_traditional
		let cht = '_cht'
	endif
	if !has_key(a:im, 'lines'.cht) && a:im.type != 'cloud'
		" @TODO: can we access l:path?
		let l:path = a:im['path'.cht]
		let lines = readfile(l:path)
		if a:im.id != 'qq'
			while lines[0] != '[Data]'
				" @TODO
				call remove(lines, 0)
			endwhile
			call remove(lines, 0)
		endif
		let a:im['lines'.cht] = lines
	endif
	return a:im['lines'.cht]
endfunction

function! s:encoding(line)
	if &enc == 'utf-8'
		return a:line
	endif
	try
		let a:line = iconv(a:line, 'utf-8', &enc)
		" 移除编码转换失败词组
		let pattern = '\S\*?\+\l*'
		let a:line = substitute(a:line, pattern, '', 'g')
		return a:line
	catch /.*/
		echoerr "Maybe iconv feature is missing.
					\ See http://www.vim.org/download.php for more details."
		return ''
	endtry
endfunction

function! s:find_sorted_idx(list, key)
	" a:list: ['a', 'aa', 'ab', ...]
	" a:key:   'def'
	let low = 0
	let high = len(a:list) - 1
	let mid = (low + high) / 2
	let l:key = get(split(a:list[mid], '\s\+'), 0, '')

	while low <= high
		if l:key < a:key
			let low = mid + 1
		elseif l:key > a:key
			let high = mid - 1
		else
			return mid
		endif
		let mid = (low + high) / 2
		let l:key = get(split(a:list[mid], '\s\+'), 0, '')
	endwhile
	return -1
endfunction

function! s:find_sorted_match(list, key, low, high)
	" a:list: ['a 工', 'a 戈', '@a 啊', ...]
	" a:key:   'def'
	if a:high >= len(a:list) || a:low > a:high
		return -1
	endif
	let pattern = '^@\='.a:key
	let low = a:low
	let high = a:high
	let mid = (low + high) / 2
	let line = a:list[mid]

	while low <= high && low >= a:low && high <= a:high &&
				\ mid >= a:low && mid <= a:high
		if line =~ pattern
			return mid
		endif
		let start = line[0] == '@' ? 1 : 0
		let cmp = line[start : len(a:key)]
		if cmp < a:key
			let low = mid + 1
		elseif cmp > a:key
			let high = mid - 1
		endif
		let mid = (low + high) / 2
		let line = a:list[mid]
	endwhile
	return -1
endfunction

function! s:sorted_matches_range(list, key)
	let high = len(a:list) - 1
	let sep = s:find_sorted_match(a:list, a:key, 0, high)
	if sep == -1
		return [-1, -1]
	endif

	let lower = s:find_sorted_match(a:list, a:key, 0, sep - 1)
	if lower == -1
		let lower_saver = sep
	else
		while lower != -1
			let lower_saver = lower
			let lower = s:find_sorted_match(a:list, a:key, 0, lower - 1)
		endwhile
	endif
	let greater = s:find_sorted_match(a:list, a:key, sep + 1, high)
	if greater == -1
		let greater_saver = sep
	else
		while greater != -1
			let greater_saver = greater
			let greater = s:find_sorted_match(a:list, a:key, greater + 1, high)
		endwhile
	endif
	return [lower_saver, greater_saver]
endfunction

function! yavimim#backend#setup_backend()
	let s:yavimim.backends = {
				\ 'wbqq': {'id': 'qq',
					\ 'type': 'wubi',
					\ 'name': 'QQ云五笔'},
				\ 'wbpy': {'id':'wbpy',
				\ 'type': 'wubi',
				\ 'name': '五笔拼音'}
				\ }
	for [key, im] in items(s:yavimim.backends)
		let paths = s:getpaths(im)
		if join(paths, '') == ''
			call remove(s:yavimim.backends, key)
		else
			let im.path = paths[0]
			let im.path_cht = paths[1]
		endif
	endfor
	let user_ims = keys(s:yavimim.backends)
	if exists('g:yavimim_imlist')
		let ims = split(g:yavimim_imlist, ',')
		let _ims = []
		for imkey in ims
			if index(user_ims, imkey) >= 0
				call add(_ims, imkey)
			endif
		endfor
		if !empty(_ims)
			let user_ims = _ims
		endif
	endif
	let s:yavimim.im = s:yavimim.backends[user_ims[0]]
endfunction

function! s:getpaths(im)
	let paths = []
	for cht in ['', '_cht']
		let relative = printf('autoload/yavimim/%s/%s%s.txt',
					\ a:im.type, a:im.id, cht)
		let path = split(globpath(&rtp, relative), '\n')
		if len(path) > 0
			if len(path) > 1
				silent call yavimim#util#show_message()
			endif
			call add(paths, path[0])
		else
			call add(paths, '')
		endif
	endfor
	return paths
endfunction

" 简繁转换
function! s:s2t(chars)
	if !exists('s:s2t_lines') || empty(s:s2t_lines)
		let path = sptit(globpath(&rtp, 'autoload/yavimim/data/gbks2t.tab'),
					\ '\n')
		if len(path) == 0
			let message = "简繁转换数据库不存在，无法使用该功能！"
			call yavimim#util#show_message(message)
			return
		endif
		let s:s2t_lines = readfile(path[0])
	endif
	for line in s:s2t_lines
		let pattern = '^'.a:chars
		if line =~ pattern
			return strpart(line, byteidx(line, 1))
	endfor
endfunction

function! yavimim#backend#getim()
	" @TODO deepcopy/copy
	return s:yavimim.im
endfunction
