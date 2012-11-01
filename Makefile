# http://vim.wikia.com/wiki/Using_VimBall_with_make
PLUGIN = yavimim

SOURCE = plugin/yavimim.vim
SOURCE += autoload/Powerline/Segments/yavimim.vim
SOURCE += autoload/yavimim/yavimim.vim
SOURCE += autoload/yavimim/highlight.vim
SOURCE += autoload/yavimim/util.vim
SOURCE += autoload/yavimim/user_config.vim
SOURCE += autoload/yavimim/wubi/qq.txt

all: ${PLUGIN}.vmb

archive: ${SOURCE}
	@tar Jcvf ${PLUGIN}.tar.xz ${SOURCE}

${PLUGIN}.vmb: ${SOURCE}
	@vim --cmd 'let g:plugin_name="${PLUGIN}"' -S build.vim -cq!

.PHONY : clean
clean:
	-rm -f ${PLUGIN}.vmb ${PLUGIN}.tar.xz
