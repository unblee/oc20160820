#!/bin/bash

git_rev=$(git rev-parse --short HEAD)
cmd_prefix="bundle exec"
dump_file="stackprof/${git_rev}"
time_file="time/${git_rev}"

red=31
green=32
yellow=33
blue=34

function cecho {
  local color=$1
  shift
  echo -e "\033[${color}m$@\033[m"
}

function err {
  cecho $red "[ERROR] Invalid subcommand"
  usage
  exit 1
}

function prof {
  local command="${cmd_prefix} stackprof ${dump_file}"
  echo ${command}
  eval ${command}
}

function cattime {
  local command="cat time/${git_rev}"
  echo ${command}
  eval ${command}
}

function exe {
  [[ ! -d stackprof ]] && mkdir stackprof
  [[ ! -d time ]] && mkdir time
  [[ -d dic ]] && rm -fr dic
  [[ -z ${1} ]] && err

  # Remove no exist id file
  local grep_cmd="grep -v"
  for exist_id in `git log --pretty=format:"%h"`
  do
    grep_cmd="${grep_cmd} -e '${rev}'"
  done
  (
    cd time
    for f in `ls | eval ${grep_cmd}`
    do
      rm -f ${f}
    done
  )
  (
    cd stackprof
    for f in `ls | eval ${grep_cmd}`
    do
      rm -f ${f}
    done
  )

  local command="(time ${cmd_prefix} ruby ${1}) > ${time_file} 2>&1"
  echo ${command}
  eval ${command}
}

function file_prof {
  local command="${cmd_prefix} stackprof ${dump_file} --file ${1}"
  [[ -z ${1} ]] && err
  echo ${command}
  eval ${command}
}

function method_prof {
  local command="${cmd_prefix} stackprof ${dump_file} --method '${1}'"
  [[ -z ${1} ]] && err
  echo ${command}
  eval ${command}
}

function func_prof {
  local command="${cmd_prefix} stackprof ${dump_file} --method 'Object#${1}'"
  [[ -z ${1} ]] && err
  echo ${command}
  eval ${command}
}

function func_list {
  [[ -z ${1} ]] && err
  grep 'def ' ${1} | sed -r 's/\(.*//g;s/def //'
}

function func_prof_list {
  [[ -z ${1} ]] && err
  for FUNC in $(func_list ${1})
  do
    func_prof ${FUNC}
  done
}

function web_url {
  if ${1}; then
    echo "http://localhost:9292"
  else
    echo "http://localhost:9292/file?path=${PWD}/${1}"
  fi
}

function web_prof {
  local command="${cmd_prefix} stackprof-webnav -f ${dump_file}"
  echo ${command}
  eval ${command}
}

function usage {
    cat <<EOF
Usage:
    ./$(basename ${0}) [command] [<options>]

    ./$(basename ${0}) prof

    ./$(basename ${0}) cattime

    ./$(basename ${0}) exe <file_name>

        e.g. ./$(basename ${0}) exe main.rb

    ./$(basename ${0}) file_prof <file_name>

        e.g. ./$(basename ${0}) file_prof main.rb

    ./$(basename ${0}) method_prof <method_name>

        e.g. ./$(basename ${0}) method_prof "Object#main"

    ./$(basename ${0}) func_prof <function_name>

        e.g. ./$(basename ${0}) func_prof "main"

    ./$(basename ${0}) func_list <file_name>

        e.g. ./$(basename ${0}) func_list main.rb

    ./$(basename ${0}) func_prof_list <file_name>

        e.g. ./$(basename ${0}) func_prof_list main.rb

    ./$(basename ${0}) web_url [<file_name>]

    ./$(basename ${0}) web_prof

Options:
    --help, -h        print this
EOF
}

case ${1} in
  prof)
    prof ${2}
    ;;
  cattime)
    cattime
    ;;
  exe)
    exe ${2}
    ;;
  file_prof)
    file_prof ${2}
    ;;
  method_prof)
    method_prof ${2}
    ;;
  func_prof)
    func_prof ${2}
    ;;
  func_list)
    func_list ${2}
    ;;
  func_prof_list)
    func_prof_list ${2}
    ;;
  web_url)
    web_url ${2}
    ;;
  web_prof)
    web_prof
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    err
    ;;
esac
