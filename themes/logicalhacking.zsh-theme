# vim:ft=zsh ts=4 sw=2 sts=2
#
# LogicalHacking Theme 
# An agnoster-inspired theme for ZSH
#
# Copyright (C) 2017 Achim D. Brucker, https://www.brucker.ch
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# SPDX-License-Identifier: MIT
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

prompt_git() {
    (( $+commands[git] )) || return
    local PL_BRANCH_CHAR
    () {
        local LC_ALL="" LC_CTYPE="en_US.UTF-8"
        PL_BRANCH_CHAR=$'\ue0a0'         # 
    }

    function +vi-git-stash() {
        local -a stashes

        if [[ -s ${hook_com[base]}/.git/refs/stash ]] ; then
            stashes=$(git stash list 2>/dev/null | wc -l)
            hook_com[misc]+=" (${stashes} stashed)"
        fi
    }
    function +vi-git-st() {
        local ahead behind remote
        local -a gitstatus
        
        remote=${$(git rev-parse --verify ${hook_com[branch]}@{upstream} \
                       --symbolic-full-name 2>/dev/null)/refs\/remotes\/}
        
        if [[ -n ${remote} ]] ; then
            ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
            (( $ahead )) && gitstatus+=( "${c3}+${ahead}${c2}" )
            
            behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)
            (( $behind )) && gitstatus+=( "${c4}-${behind}${c2}" )
            
            hook_com[branch]="${hook_com[branch]} [${remote} ${(j:/:)gitstatus}]"
        fi
    }

    local ref dirty mode repo_path
    repo_path=$(git rev-parse --git-dir 2>/dev/null)

    if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
        dirty=$(parse_git_dirty)
        ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
        if [[ -n $dirty ]]; then
            prompt_segment "$1" "$3"
        else
            prompt_segment "$2" "$3"
        fi

        if [[ -e "${repo_path}/BISECT_LOG" ]]; then
            mode=" <B>"
        elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
            mode=" >M<"
        elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge"
                                         || -e "${repo_path}/../.dotest" ]]; then
            mode=" >R>"
        fi

        setopt promptsubst
        autoload -Uz vcs_info

        zstyle ':vcs_info:*' enable git
        zstyle ':vcs_info:*' get-revision true
        zstyle ':vcs_info:*' check-for-changes true
        zstyle ':vcs_info:*' stagedstr '✚'
        zstyle ':vcs_info:*' unstagedstr '●'
        # zstyle ':vcs_info:*' formats ' %u%c'
        # zstyle ':vcs_info:*' actionformats ' %u%c'

         zstyle ':vcs_info:git*' formats " %b%m %u%c"
         zstyle ':vcs_info:git*' actionformats " %b%m %u%c"
         zstyle ':vcs_info:git*+set-message:*' hooks git-st git-stash
         vcs_info
         # echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
         echo -n "$PL_BRANCH_CHAR${vcs_info_msg_0_%% }${mode}"
    fi
}


# Prompt: Bazar
prompt_bzr() {
    (( $+commands[bzr] )) || return
    if (bzr status >/dev/null 2>&1); then
        status_mod=`bzr status | head -n1 | grep "modified" | wc -m`
        status_all=`bzr status | head -n1 | wc -m`
        revision=`bzr log | head -n2 | tail -n1 | sed 's/^revno: //'`
        if [[ $status_mod -gt 0 ]] ; then
            prompt_segment $1 $3
            echo -n "bzr@"$revision "✚ "
        else
            if [[ $status_all -gt 0 ]] ; then
                prompt_segment $1 $3
                echo -n "bzr@"$revision

            else
                prompt_segment $2 $3
                echo -n "bzr@"$revision
            fi
        fi
    fi
}



# Prompt Setup and key bindings
build_prompt() {
    RETVAL=$?
    prompt_logo $LHORANGE $LHBLACK
    prompt_isabelle_env $LHCYAN $LHBLACK
    prompt_dir $LHORANGEMEDIUM $LHBLACK
    prompt_git $LHGOLDMEDIUM $LHGOLDDARK $LHBLACK
    prompt_bzr $LHGOLDMEDIUM $LHGOLDDARK $LHBLACK
    prompt_end
}

build_inactive_prompt() {
    RETVAL=$?
    prompt_logo $LHDARKGRAY $LHWHITE
    prompt_isabelle_env $LHDARKGRAY $LHWHITE
    prompt_dir $LHDARKGRAY $LHWHITE
    prompt_git $LHDARKGRAY $LHDARKGRAY $LHWHITE
    prompt_bzr $LHDARKGRAY $LHDARKGRAY $LHWHITE
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
SEGMENT_SEPARATOR_SAME_COLOR=" %{$fg[$LHBLACK]%}$PL_RARROW "
ISAVERSION=isa_version_dir

if [[ "$TERM" =~ ".*256.*" ]]; then
    #    0 -  15: System colors (color theme might define up to color 21)
    #   16 - 231: 6x6x6 color cube, for R, G, B \in {0, ..., 5}:
    #                               index = 16 + R×6×6 + G×6 + B
    #  132 - 255: grayscale 
    #
    # 243 107  33    #F36B21   lhOrange
    LHORANGE=202     #FF5F00 
    #  65 242  34    #41F222   lhGreen
    LHGREEN=82       #5FFF00
    #  30 174 219    #1EAEDB   lhCyan
    LHCYAN=38        #00AFD7
    # 211  34 242    #D322F2   lhMagenta
    LHMAGENTA=165    #D700FF
    # 242 211  34    #F2D322   lhGold
    LHGOLD=220       #FFD700
    #
    # 156  69  22    #9C4516    lhOrangeMedium
    LHORANGEMEDIUM=130 #AF5F00
    #  42 156  22    #2A9C16    lhGreenMedium
    LHGREENMEDIUM=34 #00AF00
    #  22 109 156    #166D9C    lhCyanMedium
    LHCYANMEDIUM=25  #0055af
    # 135  22 156    #87169C    lhMagentaMedium
    LHMAGENTAMEDIUM=91 #8700AF
    # 156 135  22    #9C8716    lhGoldMedium
    LHGOLDMEDIUM=136 #AF8700
    #
    #  71  31  10    #471F0A    lhOrangeDark
    LHORANGEDARK=52  #%F0000
    #  19  71  10    #13470A    lhGreenDark
    LHGREENDARK=22   #005f00
    #  10  50  71    #0A3247    lhCyanDark
    LHCYANDARK=23    #005F5F
    #  62  10  71    #3E0A47    lhMagentaDark
    LHMAGENTADARK=53 #5F005F
    #  51  86  28    #33561C    lhGoldDark
    LHGOLDDARK=58    #5F5F00
    #
    # 204 204 204    #CCCCCC    lhLightGray
    LHLIGHTGRAY=188  #D7D7D7
    #  68  68  68    #444444    lhDarkGray
    LHDARKGRAY=59    #5F5F5F
    #   8   8   8    #080808    lhBlack
    LHBLACK=232      #080808
    # 248 248 248    #F8F8F8    lhWhite
    LHWHITE=255      #EEEEEE

else
    LHORANGE="068"
    LHORANGEMEDIUM="016"
    LHDARKGRAY="019"
    LHLIGHTGRAY="008"
    LHCYAN="014"
    LHGOLD="003"
    LHGREEN="002"
fi
