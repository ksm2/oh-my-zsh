#!/bin/bash

BLUE="%{${fg[blue]}%}"
RED="%{${fg[red]}%}"
GREEN="%{${fg[green]}%}"
CYAN="%{${fg[cyan]}%}"
MAGENTA="%{${fg[magenta]}%}"
YELLOW="%{${fg[yellow]}%}"
WHITE="%{${fg[white]}%}"
NO_COLOR="%{${reset_color}%}"

function curr_user() {
	if (( EUID == 0 )); then
		username_color="${RED}"
	else
		username_color="${BLUE}"
	fi

	echo "%B${username_color}%n%b${NO_COLOR}@${YELLOW}%m${NO_COLOR}"
}

function vcs_info() {
	git branch &> /dev/null
	if [ $? -eq 0 ]; then
		
		ref=$(git symbolic-ref HEAD 2> /dev/null) || \
		ref=$(git rev-parse --short HEAD 2> /dev/null) || return;

		curr_branch=$(git name-rev --name-only HEAD)
		
		git status -s | grep -v "??" &> /dev/null
		if [ $? -eq 0 ]; then
			git_status_color="${RED}"
			git_status="✗"
		else
			git_status_color="${GREEN}"
			git_status="✓"
		fi

		unpushed_commits=$(git log origin/${curr_branch}.. 2> /dev/null | egrep "^commit" | wc -l)
		if [ $unpushed_commits -gt 0 ]; then
			git_unpushed="${YELLOW}⚡"
		fi

		git_changes=$(git diff --shortstat | sed -re "s/([0-9]+) files? changed(, ([0-9]+) insertions?\(\+\))?(, ([0-9]+) deletions?\(\-\))?/${MAGENTA}| ${CYAN}\\1 ${MAGENTA}| ${GREEN}\\3 ${MAGENTA}| ${RED}\\5/g")

		echo "(git)-${MAGENTA}[${git_status_color}${ref#refs/heads/} ${git_status}${git_unpushed}${git_changes}${MAGENTA}]"
	fi
}

PROMPT='[${YELLOW}%40<...<%B%~%b] $(vcs_info)
${YELLOW} %#${NO_COLOR} '
RPROMPT='${RED}%(?..%? ${NO_COLOR}- )${YELLOW}%T ${NO_COLOR}- $(curr_user)'
