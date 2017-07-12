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


# Define abstract names for the PowerLine symbols          
() {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH=$'\ue0a0'   # 
    PL_LN=$'\ue0a1'       # 
    PL_CPADLOCK=$'\ue0a2' # 
    PL_BRARROW=$'\ue0b0'  # 
    PL_RARROW=$'\ue0b1'   # 
    PL_BLARROW=$'\ue0b2'  # 
    PL_LARROW=$'\ue0b3'   # 
}

# Drawing of segments
CURRENT_BG='NONE'

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
    local bg fg
    [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
    [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
    if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
        echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
    else
        if [[ $CURRENT_BG != 'NONE' ]]; then
            echo -n "%{$bg%}%{$fg%}$SEGMENT_SEPARATOR_SAME_COLOR"
        fi
        echo -n "%{$bg%}%{$fg%}"
    fi
    CURRENT_BG=$1
    [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
    if [[ -n $CURRENT_BG ]]; then
        echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
    else
        echo -n "%{%k%}"
    fi
    echo -n "%{%f%}"
    CURRENT_BG=''
}

# Prompt: LH Logo
prompt_logo() {
    prompt_segment $1 $2 "{*λH*}"
}


# Prompt: working directory
prompt_dir() {
    prompt_segment $1 $2 "$(promptpwd)"
}


# Prompt: Isabelle Version
isa_version_cmd (){
    echo `Isabelle version  | sed -e 's/:.*//' -e 's/Isabelle//'`
}
isa_version_dir() {
    echo `which isabelle | sed -e 's/.*Isabelle//' -e 's/.bin.*//'`
}    
prompt_isabelle_env() {
    ISADIR=false
    if [[ -f ROOT || -f ROOTS ]]; then
        ISADIR=true
    else
        if (){ setopt localoptions nonomatch nocshnullglob; [ -f *.thy([1]) ] }
        then
            ISADIR=true
        fi
    fi
    if [ "$ISADIR" = true ]; then
        prompt_segment $1 $2 "(Isabelle $( $ISAVERSION ))"
    fi
}


# Prompt Setup and key bindings
build_prompt() {
    RETVAL=$?
    prompt_logo $LHORANGE black
    prompt_isabelle_env $LHCYAN black
    prompt_dir $LHLIGHTORANGE black
    prompt_end
}

build_inactive_prompt() {
    RETVAL=$?
    prompt_logo $LHDARKGRAY white
    prompt_isabelle_env $LHLIGHTGRAY white
    prompt_dir $LHLIGHTGRAY white
    prompt_end 
}

del-prompt-accept-line() {
    OLD_PROMPT="$PROMPT"
    PROMPT=$INACTIVEPROMPT
    zle reset-prompt
    PROMPT="$OLD_PROMPT"
    zle accept-line
}

zle -N del-prompt-accept-line
bindkey "^M" del-prompt-accept-line

# Actual prompt definition
PROMPT='%{%f%b%k%}$(build_prompt) '
INACTIVEPROMPT='%{%f%b%k%}$(build_inactive_prompt) '

# Default configuration
SEGMENT_SEPARATOR=$PL_BRARROW
SEGMENT_SEPARATOR_SAME_COLOR=" %{$fg[black]%}$PL_RARROW "
ISAVERSION=isa_version_dir

if [[ "$TERM" =~ ".*256.*" ]]; then
    LHORANGE="166"
    LHLIGHTORANGE="172"
    LHDARKGRAY="235"
    LHLIGHTGRAY="008"
    LHCYAN="014"
else
    LHORANGE="068"
    LHLIGHTORANGE="016"
    LHDARKGRAY="019"
    LHLIGHTGRAY="008"
    LHCYAN="014"
fi

