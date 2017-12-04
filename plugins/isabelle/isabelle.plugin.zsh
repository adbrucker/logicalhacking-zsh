# vim:ft=zsh ts=4 sw=2 sts=2
#
# Isabelle Plugin for ZSH
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

zmodload zsh/pcre

isabelle-strip-comments() {
    local stripped
    stripped=` echo "$1" | awk -e '
        BEGIN {
            found=0;
        }{
            spos=index($0,"(*");
            epos=index($0,"*)");
            if(spos > 0 && epos ==0) {
                printf("%s\n",substr($0,1,spos-1));
                found=1;
            } else if(spos == 0 && epos >0) {
                found=0;
                if(length($0) != epos+1) {
                    printf("%s\n",substr($0,epos+2));
                }
            } else if(spos > 0 && epos > 0) {
                printf("%s %s\n",substr($0,1,spos-1),substr($0,epos+2));
            } else if(found==0) {
                print;
            }
        }' `
     echo "$stripped"   
}

isabelle-list-sessions() {
    local dir root roots accum
    [[ -n $1 ]] && dir="$1" || dir="."
    if [[ -f "$dir/ROOT" ]]; then 
        root="$(<$dir/ROOT)"
        root=$( isabelle-strip-comments "$root" )
        pcre_compile -xms 'session\s+("[^"]*"|\S+)'
        accum=()
        pcre_match -b -- $root
        while [[ $? -eq 0 ]] do
            b=($=ZPCRE_OP)
            accum+=${${MATCH//\"/}//session /} #"
            pcre_match -b -n $b[2] -- $root
        done
        print -l $accum
    fi
    if [[ -f "$dir/ROOTS" ]]; then
        roots="$(<$dir/ROOTS)"
        roots=$( isabelle-strip-comments "$roots" )
        roots=("${(f)roots}")
        for d in $roots; do
            d="${d//\"/}" #"
            isabelle-list-sessions "$dir/$d"
        done
    fi
} 

