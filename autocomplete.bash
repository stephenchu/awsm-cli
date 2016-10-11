#! /bin/bash

_awsm() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}

  case ${COMP_CWORD} in
    1)
      COMPREPLY=( $(compgen -W "ec2 autoscaling" ${cur}) )
      ;;
    2)
      case ${prev} in
        ec2)
          COMPREPLY=( $(compgen -W "describe-instances describe-vpcs" ${cur}) )
          ;;

        autoscaling)
          COMPREPLY=( $(compgen -W "describe-auto-scaling-groups" ${cur}) )
          ;;
      esac
      ;;
    *)
      COMPREPLY=(foo)
      ;;
  esac
}

complete -F _awsm awsm
