" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
if exists('g:_yavimim_loaded')
	finish
endif
let g:_yavimim_loaded = 1

"===============================================================================
" 用户配置段
"===============================================================================
if !exists('g:yavimim_imlist')
	" 默认加载的输入法列表 五笔拼音 五笔QQ
	let g:yavimim_imlist            = 'wbpy,wbqq'
endif
if !exists('g:yavimim_im')
	let g:yavimim_im                = 'wbqq'      " 默认输入法 五笔QQ
endif
if !exists('g:yavimim_traditional')
	let g:yavimim_traditional       = 0           " 繁体 禁用
endif
if !exists('g:yavimim_number')
	" 逗号分隔，前一个数字代表命令行模式下的候选词个数，后一个数字代表插入模式下
	" 的候选词个数，如果为一个单独的数字，则表示这两种模式下候选词个数均为该值。
	let g:yavimim_number            = '5'         " 候选词个数 5 5
	let g:yavimim_number            = '5,10'      " 候选词个数，逗号分隔 5 10

endif
if !exists('g:yavimim_auto_commit')
	let g:yavimim_auto_commit       = 1           " 自动上屏 启用
endif
if !exists('g:yavimim_vkbl')
	let g:yavimim_vkbl              = 'pc103'     " 键盘布局 pc103
endif
if !exists('g:yavimim_verbose')
	let g:yavimim_verbose           = 1           " 提示信息 显示
endif
if !exists('g:yavimim_user_dir')
	" 用户数据目录
	" user.txt 用户词库数据
	" cache/ 数据缓存
	if has("win32")
		let g:yavimim_user_dir      = '~/yavimim/'
	else
		let g:yavimim_user_dir      = '~/.yavimim/'
	endif
endif
"===============================================================================
" 主程序
"===============================================================================
inoremap <silent> <expr>  yavimim#toggle_insert()
cnoremap <silent> <expr>  yavimim#toggle_cmdline()

" usage
" YDebug b:yavimim,g:yavimim
" YDebugEval b:yavimim,s:
" @TODO: 添加自定义补全，把 yavimim 中的脚本域的变量名和函数名全部加上
command -nargs=* -complete=var YDebug call yavimim#debug(<f-args>)
augroup YaVimIM
	autocmd VimEnter *
				\ if exists('g:Powerline_loaded') && g:Powerline_loaded
				\ | call Pl#Theme#RemoveSegment('yavimim:statusline')
				\ | call Pl#Theme#InsertSegment('yavimim:statusline',
					\'before', 'fileformat')
				\ | call yavimim#powerline#inject()
				\ | endif
	autocmd SourcePre *autoload/Powerline/Themes/*.vim
				\ if exists('g:Powerline_loaded') && g:Powerline_loaded
				\ | call yavimim#powerline#hook()
				\ | endif
augroup END
