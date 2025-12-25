if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

umask 022

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
PATH=$PATH:$HOME/bin:$HOME/sbin:$HOME/usr/bin:$HOME/usr/sbin:$HOME/usr/local/bin:$HOME/usr/local/sbin
export PATH="$(find ~/apps -type d -name 'bin' | paste -sd: -):$PATH"

if [ "64" = "`getconf LONG_BIT`" ]; then
        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib64:/usr/lib64:/usr/local/lib64; export LD_LIBRARY_PATH
else
        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib:/usr/lib:/usr/local/lib; export LD_LIBRARY_PATH
fi

USERNAME="`whoami`"
if [ "0" = "`id -u $USERNAME`" ]; then
        PS1="\u@\h:\w #"; export PS1
else
        PS1="\u@\h:\w $"; export PS1
fi
unset USERNAME

if [ "$TERM" != "dumb" ]; then
        eval "`dircolors -b`"
        alias l='ls --color=auto -l'
        alias ls='ls --color=auto -a'
        alias ll='ls --color=auto -al'
        alias dir='ls --color=auto --format=vertical'
        alias vdir='ls --color=auto --format=long'
fi

LANG="en_US.utf8"; export LANG
LANGUAGE="en_US.utf8"; export LANGUAGE
LC_ALL="en_US.utf8"; export LC_ALL
LC_CTYPE="en_US.utf8"; export LC_CTYPE
SUPPORTED=en_US.UTF8:en_US:en; export SUPPORTED

JAVA_HOME=~/apps/jdk; export JAVA_HOME
CLASSPATH=.:$JAVA_HOME/lib; export CLASSPATH
PATH=$JAVA_HOME/bin:$PATH; export PATH

TZ='Asia/Shanghai'; export TZ
