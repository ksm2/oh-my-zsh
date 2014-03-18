#!/bin/bash

CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''
SEGMENT_SEPARATOR_LIGHT=''

BLUE="%{${fg[blue]}%}"
RED="%{${fg[red]}%}"
GREEN="%{${fg[green]}%}"
CYAN="%{${fg[cyan]}%}"
MAGENTA="%{${fg[magenta]}%}"
YELLOW="%{${fg[yellow]}%}"
WHITE="%{${fg[white]}%}"
NO_COLOR="%{${reset_color}%}"

GIT_CLEAN="${fg[green]}☑️"
GIT_DIRTY="${fg[red]}✗"
GIT_AHEAD="${fg[yellow]}⚡"
GIT_UNTRACKED="${fg[white]}✭"
GIT_ADDED="${fg[blue]}✚"

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
  	if [[ $CURRENT_BG = 'black' ]]; then
  		echo -n " %{$bg%F{white}%}$SEGMENT_SEPARATOR_LIGHT%{$fg%} "
  	else
    	echo -n "%{$bg%}%{$fg%} "
    fi
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  	if [[ -n $CURRENT_BG ]]; then
  		if [[ $CURRENT_BG = 'black' ]]; then
    		echo -n " %{%k%F{white}%}$SEGMENT_SEPARATOR_LIGHT"
    	else
    		echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
    	fi
  	else
    	echo -n "%{%k%}"
  	fi
  	echo -n "%{%f%}"
  	CURRENT_BG=''
}

function curr_user() {
	if (( EUID == 0 )); then
		username_color="${RED}"
	else
		username_color="${BLUE}"
	fi

	echo "%B${username_color}%n%b${NO_COLOR}@${YELLOW}%m${NO_COLOR}"
}

function prompt_dir() {
	current_dir="${PWD/$HOME/~}"
	b=("${(s/\/)current_dir}")
	started=0

	IFS='/'; for i in $current_dir; do
	    if [ $started = 0 ]; then
	    	[ -z $i ] && continue
	    	prompt_segment blue white "$i"   
	    	prompt_vcs 
	    else
	    	prompt_segment black default "$i"
	    fi
	    started=1
	done
}

function prompt_vcs() {
	# ensure this is a git repository
	# TODO other VCS (maybe..)
	$(git rev-parse --is-inside-work-tree 2> /dev/null) || return;
		
	git_status=$(git status --porcelain 2> /dev/null)
	git_status_icon=""

	if $(echo -n "$git_status" | grep -v "??" &> /dev/null); then
		git_status_color="yellow"
	else
		git_status_color="green"
	fi

	if $(echo "$git_status" | grep '^A  ' &> /dev/null); then
		git_status_icon="${git_status_icon} ${GIT_ADDED}"
	elif $(echo "$git_status" | grep '^M  ' &> /dev/null); then
		git_status_icon="${git_status_icon} ${GIT_ADDED}"
	fi
	if $(echo "$git_status" | grep "??" &> /dev/null); then
		git_status_icon="${git_status_icon}${GIT_UNTRACKED}"
	fi

	unpushed_commits=$(git log origin/$(current_branch).. --pretty=oneline 2> /dev/null | wc -l)
	if [ $unpushed_commits -gt 0 ]; then
		git_status_icon="${git_status_icon}${GIT_AHEAD}"
	fi
	
	git_stat=$(git diff --numstat | awk -v white="${fg[white]}" \
										-v yellow="${fg[yellow]}" \
										-v cyan="${fg[cyan]}" \
										-v cyanbg="${bg[cyan]}" \
										-v red="${fg[red]}" \
										-v redbg="${bg[red]}" \
										-v green="${fg[green]}" \
										-v greenbg="${bg[green]}" \
										-v sep="${SEGMENT_SEPARATOR}" \
										'BEGIN { added = 0; deleted = 0}
										{ added += $1; deleted += $2 }
										END { if (NR > 0 || $added > 0 || $deleted > 0)  print " " cyanbg yellow sep " " white "#" NR " " cyan greenbg sep white " +" added " " redbg green sep white " -" deleted}')

	prompt_segment ${git_status_color} black "$(current_branch)${git_status_icon}"

	[[ -n $git_stat ]] && echo -n $git_stat && CURRENT_BG=red
}

## Main prompt
build_prompt() {
	RETVAL=$?

	prompt_dir
	prompt_end

	echo ""
	echo -n "${YELLOW} %#${NO_COLOR}"
}

## Main prompt
build_rprompt() {
	RETVAL=$?

	curr_status="${RED}%(?..%? ${NO_COLOR}- )"
	curr_time="${YELLOW}%T ${NO_COLOR}-"

	echo -n "${curr_status}${curr_time} $(curr_user)"
}

# RPROMPT='${curr_status}${curr_time} $(curr_user)'

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='$(build_rprompt)'
