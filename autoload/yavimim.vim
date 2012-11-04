" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
" ==============================================================================
" initialization
" ==============================================================================
let s:y = {}
let s:y.cycle_langmap = 30 " keycode , :help i_CTRL-^

let s:y.keycodes = {}
let s:y.keycodes.enter = 13 " Enter/CR
let s:y.keycodes.ctrl_e = 5 " Ctrl-E
let s:y.keycodes.ctrl_y = 25 " Ctrl-Y
let s:y.keycodes.ctrl_n = 14 " Ctrl-N
let s:y.keycodes.space = 32 " Space
let s:y.keycodes.escape = 27 " Esc
let s:y.map_args= "<silent> <buffer> <unique>"

let s:y.punctuation = {
			\ 'origin': [',', '.', ';', '?', '!', '\', ':'],
			\ 'trans': ['，', '。', '；', '？', '！', '、', '：']}

function! yavimim#toggle_insert()
	call s:yavimim#toggle()
	call yavimim#insert#toggle()
endfunction

function! yavimim#toggle_cmdline()
	call s:yavimim#toggle()
	call yavimim#cmdline#toggle()
endfunction

function! yavimim#toggle_normal()
	call s:yavimim#toggle()
endfunction

function! yavimim#yavimim#toggle(...)
	call s:plugin_compatible()
	if !&l:modifiable | return '' | endif
	if !exists('g:yavimim.init') | call s:init() | endif
	if !exists('b:yavimim') | call s:init_buffer() | endif
	call yavimim#cmdline#init()
	call s:toggle_options()
	if exists('b:yavimim.highlight_id')
		call matchdelete(b:yavimim.highlight_id)
		unlet b:yavimim.highlight_id
	endif
	call s:set_cursor_position()
	if a:0 > 0
		" invoke from normal mode
		if &l:iminsert == 1 && exists('b:yavimim.iminsert_saved')
			let &l:iminsert = b:yavimim.iminsert_saved
		else
			let b:yavimim.iminsert_saved = &l:iminsert
			let &l:iminsert = 1
		endif
	else
		return nr2char(s:y.cycle_langmap)
	endif
endfunction

function! s:plugin_compatible()
	try
		silent NeoComplCacheToggle
	catch /.*/
	endtry
endfunction

function! s:set_cursor_position()
	let b:yavimim.cursor = {'line': line('.'), 'column': col('.') - 1}
endfunction

function! s:init()
	let g:yavimim.init = 1
	let s:yavimim = {}
	runtime autoload/yavimim/user_config.vim
	call s:setup_backend()
endfunction

function! g:yavimim_cursor_movedi()
	if !exists('b:yavimim') || &l:iminsert != 1
		return
	endif

	if !b:yavimim.state
		call s:set_cursor_position()
	endif
endfunction

function! g:yavimim_start_insert()
	if !exists('b:yavimim') || &l:iminsert != 1
		return
	endif

	call s:reset_start_insert()
endfunction

function! s:reset_start_insert()
	let b:yavimim.match_lists = []
	let b:yavimim.state = 0
	call s:set_cursor_position()
endfunction

fun! s:session_start_running()
	let b:yavimim.state = 1
endf
fun! s:session_end()
	let b:yavimim.state = 0
endf

function! s:init_buffer()
	let b:yavimim = {}
	let b:yavimim.match_lists = []
	let b:yavimim.state = 0
	let b:yavimim.pmenu = 0
	let b:yavimim.base = ''
	autocmd YaVimIM CursorMovedI <buffer>
				\ if exists('b:yavimim')
				\ | call g:yavimim_cursor_movedi()
				\ | endif
	autocmd YaVimIM InsertEnter <buffer>
				\ if exists('b:yavimim')
				\ | call g:yavimim_start_insert()
				\ | endif
	autocmd YaVimIM InsertLeave <buffer>
				\ if exists('b:yavimim')
				\ | call g:do_after_cancel()
				\ | endif
	autocmd YaVimIM BufWinEnter <buffer>
				\ if !exists('b:vimim') && &l:modifiable
				\ | let &l:iminsert = 0
				\ | endif
	call s:set_cursor_position()

	" binding all keys
	call s:lmap_letters()
	call s:lmap_numbers()
	call s:lmap_punctuations()
	silent execute "lnoremap" s:y.map_args "<CR>" "<C-R>=g:lmap_enter()<CR>"
	silent execute "lnoremap" s:y.map_args "<Space>" "<C-R>=g:lmap_space()<CR>"
	silent execute "lnoremap" s:y.map_args "<BS>" "<C-R>=g:lmap_bs()<CR>"
	silent execute "lnoremap" s:y.map_args "<C-H>" "<C-R>=g:lmap_bs()<CR>"
	" 只在补全可见时禁用，其它时候可用
	silent execute "lnoremap" s:y.map_args "<Home> <Nop>"
	silent execute "lnoremap" s:y.map_args "<End> <Nop>"
	silent execute "lnoremap" s:y.map_args "<C-E>" "<C-R>=g:lmap_ctrl_e()<CR>"
	silent execute "lnoremap" s:y.map_args "<Up>"
				\ "<C-R>=g:change_cursor_pmenu_position(-1)<CR><Up>"
	silent execute "lnoremap" s:y.map_args "<Down>"
				\ "<C-R>=g:change_cursor_pmenu_position(1)<CR><Down>"
	" silent execute "lnoremap" s:y.map_args "<C-U>"
				" \ "<C-R>=g:do_after_cancel()<CR><C-U>"
endfunction

function! s:toggle_options()
	if &l:iminsert == 1
		let &l:omnifunc = b:yavimim.omnifunc_saved
		let &completeopt = b:yavimim.completeopt_saved
		let &pumheight = b:yavimim.pumheight_saved
	else
		let b:yavimim.omnifunc_saved = &l:omnifunc
		let b:yavimim.completeopt_saved = &completeopt
		let b:yavimim.pumheight_saved = &pumheight
		let b:yavimim.iminsert_saved = &l:iminsert
		let &l:omnifunc='g:yavimim_omnifunc'
		let &completeopt='menuone'
		let &pumheight = 10
	endif
endfunction

function! g:change_cursor_pmenu_position(change)
	if pumvisible() && b:yavimim.state == 1
		let b:yavimim.pmenu += a:change
	endif
	return ''
endfunction

function! g:do_after_commit()
	let b:yavimim.state = 0
	let b:yavimim.match_lists = []
	let b:yavimim.pmenu = 0
	call s:set_cursor_position()
	call yavimim#highlight#predict()
	return ''
endfunction

function! g:do_waiting_commit()
	" 开始中文输入中
	let b:yavimim.state = 1
	call yavimim#highlight#predict()
	return ''
endfunction

function! g:do_after_cancel()
	let b:yavimim.state = 0
	let b:yavimim.match_lists = []
	call s:set_cursor_position()
	call yavimim#highlight#predict()
	return ''
endfunction

function! g:set_after_insert_beside_chinese()
	" 输入的不是中文汉字
	let b:yavimim.state = 0
	call s:set_cursor_position()
	call yavimim#highlight#predict()
	return ''
endfunction

function! s:setup_backend()
	let l:wubi_qqs = split(globpath(&rtp, 'autoload/yavimim/wubi/qq.txt'), '\n')
	if len(l:wubi_qqs) > 0
		silent call yavimim#util#show_message()
	endif
	let s:yavimim.backends = {
				\ 'wubi_qq': {'path': l:wubi_qqs[0],
					\ 'type': 'wubi',
					\ 'keys': [],
					\ 'lines':[],
					\ 'name': 'QQ云五笔'}
				\ }
	let s:yavimim.metadatas = {'wubi': {'full': '五笔', 'short': '五'},
				\ 'pinyin': {'full': '拼音', 'short': '拼'}}
	let s:yavimim.im = s:yavimim.backends.wubi_qq
endfunction
" ==============================================================================
" key mappings
" ==============================================================================
function! s:lmap_punctuations()
	let index = 0
	let origins = s:y.punctuation.origin
	let trans = s:y.punctuation.trans
	while index < len(origins)
		let origin = origins[index]
		let tran = trans[index]
		silent execute "lnoremap" s:y.map_args origin
					\ "<C-R>=g:lmap_punctuation(".index.")<CR>"
		let index += 1
	endwhile
endfunction

function! g:lmap_punctuation(index)
	let tran = s:y.punctuation.trans[a:index]
	if pumvisible()
		let key = '\<C-N>\<C-Y>\<C-R>=g:do_after_commit()\<CR>'
		let key .= tran
	else
		let key = tran
	endif
	silent execute printf('return "%s"', key)
endfunction

function! g:lmap_bs()
	let key = '\<BackSpace>'
	let step = (col('.') - 1 - b:yavimim.cursor.column)
	" 因为此时还没开始做退格操作，在删之后是4个就要做自动补全，所以在删之前是5个
	if step <= 5
		let key .= '\<C-X>\<C-O>\<C-R>=g:do_trigger_completion()\<CR>'
	endif
	silent execute printf('return "%s"', key)
endfunction

function! g:lmap_ctrl_e()
	if b:yavimim.state == 1
		let key = '\<C-R>=g:do_after_cancel()\<CR>'
		if pumvisible()
			let key .= '\<C-E>'
		endif
		let step = col('.') - 1 - b:yavimim.cursor.column
		let key .= repeat('\<BS>', step)
	else
		let key = '\<C-E>'
	endif
	silent execute printf('return "%s"', key)
endfunction

function! g:do_trigger_completion()
	if pumvisible() && len(b:yavimim.match_lists) == 1
		silent execute printf('return "%s"',
					\ '\<C-Y>\<C-R>=g:do_after_commit()\<CR>')
	endif
	if pumvisible()
		silent execute printf('return "%s"', '\<C-P>')
	endif
	return ''
endfunction

" binding enter
function! g:lmap_enter()
	if pumvisible()
		let key = '\<C-Y>'
	elseif b:yavimim.state == 1
		let key = ''
	else
		let key = '\<CR>'
	endif
	let key .= '\<C-R>=g:do_after_cancel()\<CR>'
	silent execute printf('return "%s"', key)
endf

function! s:lmap_numbers()
	for l:number in range(10)
		silent execute "lnoremap" s:y.map_args l:number
					\ "<C-R>=g:lmap_number(".l:number.")<CR>"
	endfor
endfunction

" binding number
function! g:lmap_number(number)
	let l:number = a:number
	if l:number == 0 && b:yavimim.state == 1
		let l:number = 10
	endif
	if b:yavimim.state == 1
		let l:key = repeat('\<Down>', l:number) . '\<C-Y>'
		silent execute printf('return "%s%s"', l:key,
					\ '\<C-R>=g:do_after_commit()\<CR>')
	else
		return l:number
	endif
endfunction

function! s:lmap_letters()
	for l:letter in range(char2nr('a'), char2nr('z'))
		silent execute printf("lnoremap %s %s <C-R>=g:lmap_letter('%s')<CR>",
					\ s:y.map_args, nr2char(l:letter), nr2char(l:letter))
	endfor
endfunction

function! g:lmap_letter(char)
	let type = s:yavimim.im.type
	let mode = yavimim#util#getmode()
	return s:lmap_letter_{type}_{mode}(a:char)
endfunction

function! s:lmap_letter_wubi_i(char)
	" 五笔
	" 检测我们是否已经输入四个可用字母，此时就可以上档了
	call s:fix_cursor_position()
	let l:len = col('.') - b:yavimim.cursor.column - 1
	let key = ''
	if pumvisible() && (l:len == 4 || len(b:yavimim.match_lists) == 1)
		let key = '\<C-N>\<C-Y>\<C-R>=g:do_after_commit()\<CR>'
	endif
	let key .= a:char . '\<C-R>=g:do_waiting_commit()\<CR>' .
				\ '\<C-X>\<C-O>\<C-R>=g:do_trigger_completion()\<CR>'
	silent execute printf('return "%s"', key)
endfunction

function! s:lmap_letter_wubi_c(char)
	return yavimim#cmdline#wubi(a:char)
endfunction

function! g:lmap_space()
	if pumvisible()
		" 检查 popup menu 是否高亮被选中
		" :help popupmenu-completion
		let now = getline(b:yavimim.cursor.line)
					\[b:yavimim.cursor.column:col('.') - 2]
		let key = ''
		if now == b:yavimim.base && b:yavimim.pmenu == 0
			let key .= '\<C-N>'
		endif
		let key .= '\<C-Y>\<C-R>=g:do_after_commit()\<CR>'
	else
		let key = '\<Space>\<C-R>=g:set_after_insert_beside_chinese()\<CR>'
	endif
	silent execute printf('return "%s"', key)
endfunction
" ==============================================================================
" completion
" ==============================================================================
function! s:fix_cursor_position()
	let line = getline('.')
	let line_nr = line('.')
	let start = col('.') - 1
	if line_nr != b:yavimim.cursor.line
		call s:set_cursor_position()
		" dirty hack
		" 针对 textwidth 不为0自动换行所做的hack
		if b:yavimim.state == 1
			let b:yavimim.cursor.column = 0
			call s:fix_cursor_position()
		endif
		return
	endif

	while start > 0 && start > b:yavimim.cursor.column
				\ && line[start - 1] =~ '\l'
		let start -= 1
	endwhile
	let b:yavimim.cursor.column = start
endfunction

function! g:yavimim_omnifunc(findstart, base)
	" omnifunc
	if a:findstart
		call s:fix_cursor_position()
		let base = getline(b:yavimim.cursor.line)
					\[b:yavimim.cursor.column:col('.') - 2]
		let b:yavimim.base = base
		let b:yavimim.match_lists =
					\ yavimim#backend#get_match_lists(s:yavimim.im, base)
		if !len(b:yavimim.match_lists)
			return -3
		endif
		return b:yavimim.cursor.column
	else
		let l:matches = []
		let l:index = 1
		for l:match in b:yavimim.match_lists
			let [l:word, l:menu] = yavimim#backend#wubi_qq_spliter(l:match)
			let l:abbr=printf(printf("%%%dd %%s",
						\ len(len(b:yavimim.match_lists))),
						\ l:index==10 ? 0 : l:index, l:match)
			call add(l:matches, {'word': l:word, 'abbr': l:abbr})
			let l:index += 1
		endfor
		return {'words': l:matches}
	endif
endfunction
" ==============================================================================
" utils
" ==============================================================================
function! s:debug(...)
	call yavimim#util#debugprint(a:000)
endfunction

function! yavimim#yavimim#debug(...)
	" put here that you can look into script internally variables
	let l:list = []
	for l:var in a:000
		call add(l:list, l:var)
		if type(l:var) == type("")
			try
				silent execute printf("let %s=%s", "l:inspect_var", l:var)
				call add(l:list, l:inspect_var)
				unlet l:inspect_var
			catch /.*/ " @TODO: tips, much more user friendly, don't be so rude.
			endtry
		else
			call add(l:list, l:var)
		endif
		unlet l:var
	endfor
	call yavimim#util#debugprint(l:list)
endfunction
function! yavimim#getim(...)
	call s:init()
	if len(a:000)
		let im_id = a:0
		return s:yavimim.backends.{im_id}
	else
		return s:yavimim.backends.wubi_qq
	endif
endfunction