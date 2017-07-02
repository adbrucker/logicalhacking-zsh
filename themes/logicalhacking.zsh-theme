# vim:ft=zsh ts=4 sw=2 sts=2
# Copyright (C) 2017 Achim D. Brucker, https://www.brucker.ch
#
# LogicalHacking Theme 
# A Agnoster-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.

# Generic function for formatting the working directory - in particular,
# it allows zpresto-style shortening of the full path.
promptpwd() {
    setopt localoptions extendedglob
    
    local current_pwd="${PWD/#$HOME/~}"
    local ret_directory

    if [[ "$current_pwd" == (#m)[/~] ]]; then
        ret_directory="$MATCH"
        unset MATCH
    elif zstyle -m ':lh:module:prompt' pwd-length 'full'; then
        ret_directory=${PWD}
    elif zstyle -m ':lh:module:prompt' pwd-length 'long'; then
        ret_directory=${current_pwd}
    else
        ret_directory="${${${${(@j:/:M)${(@s:/:)current_pwd}##.#?}:h}%/}//\%/%%}/${${current_pwd:t}//\%/%%}"
    fi
    print "$ret_directory"
}
