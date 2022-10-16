#!/bin/bash

# colors
C_ORANGE='\033[0;33m'
C_RED='\033[0;31m'
C_DARK_GRAY='\033[1;30m'
C_LIGHT_BLUE='\033[1;34m'
NC='\033[0m'
L_WARN="${C_ORANGE}[WARNING]${NC}"
L_ERR="${C_RED}[ERROR]${NC}"
L_INFO="${C_LIGHT_BLUE}[INFO]${NC}"
L_DEB="${C_DARK_GRAY}[DEBUG]${NC}"

is_debug() {
  [[ "${DEBUG}" == "yes" ]] && return 0 || return 1
}

log_debug() {
  local msg="${1:=''}"
  _log "${msg}" "${C_DARK_GRAY}"  # is_debug && 
}

log_info() {
  local msg="${1:=''}"
  _log "${msg}" "${C_LIGHT_BLUE}"
}

log_warn() {
  local msg="${1}"
  _log "${msg}" "${C_ORANGE}"
}

log_err(){
  local msg="${1}"
  _log "${msg}" "${C_RED}"
}

_log(){
  local msg="${1}"
  local color="${2}"
  local data
  data="$(date +%T.%3N)"
  echo -e "${color}[${data}] ${msg}${NC}"
}
