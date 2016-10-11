_awsm() {
  local current_word_index=$COMP_CWORD
  local current_word=${COMP_WORDS[COMP_CWORD]}
  local previous_word=${COMP_WORDS[COMP_CWORD-1]}
  if [ "${previous_word}" == "_" ]; then
    COMPREPLY=( $(compgen -W "$(ls $(which awsm)/awsm-cli/internal | cut -d '.' -f 1)" -- "$current_word") )
  else
    case $current_word_index in
      1)
        COMPREPLY=( $(compgen -W "$(awsm _ subcommands)" -- "$current_word") )
        ;;
      2)
        COMPREPLY=( $(compgen -W "$(awsm _ subcommand-actions --subcommand "$previous_word")" -- "$current_word") )
        ;;
      *)
        COMPREPLY=()
        ;;
    esac
  fi
}
