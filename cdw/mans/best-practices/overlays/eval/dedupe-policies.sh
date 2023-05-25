#!/usr/bin/env bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

SCRIPT_NAME=
SCRIPT_NAME=$(basename "$0")

TARGET_DIR="$PWD"
EKUST_DIR=
EKUST_FILE=
AKUST_DIR=
AKUST_FILE=


############################################################
# Help                                                     #
############################################################
help() {
   # Display Help
   echo "Test kustomize output for duplicate kyverno policies"
   echo
   echo "Syntax: $SCRIPT_NAME [-d|h]"
   echo "options:"
   echo "d     The target directory containing both 'audit' and 'enforce' policies."
   echo
   echo "h     Print this Help."
   echo
   echo
}


############################################################
# Process the input options. Add options as needed.        #
############################################################
parse_args() {
  # Get the options
  while getopts ":hd:" option; do
     case $option in
        h) # display Help
           help
           exit;;
        d) # Enter a directory
           TARGET_DIR=$OPTARG;;
       \?) # Invalid option
           echo "Error: Invalid option"
           exit;;
     esac
  done
}


valid_args() {
  if [[ -z "$TARGET_DIR" ]]; then
    echo -e "\033[31mERROR: the target directory for finding kyverno policy was not set."
    echo -e "\033[0m"
    help
    exit 1
  fi

  if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "\033[31mERROR: the target directory '$TARGET_DIR' does not exist"
    echo -e "\033[0m"
    help
    exit 1
  fi

  local edir
  edir=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -name "enforce")

  local adir
  adir=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -name "audit")

  if [[ -z "$edir" || -z "$adir" ]]; then
    echo -e "\033[31mERROR: did not find expected directories 'enforce' and/or 'audit' under $TARGET_DIR"
    echo -e "\033[0m"
    help
    exit 1
  fi

  local eyaml
  eyaml=$(find "$edir" -mindepth 1 -maxdepth 1 -type f -name kustomization.yaml)

  local eyml
  eyml=$(find "$edir" -mindepth 1 -maxdepth 1 -type f -name kustomization.yml)

  if [[ -z "$eyaml" && -z "$eyml" ]]; then
    echo -e "\033[31mERROR: the 'enforce' directory '$edir' does not have a kustomization yaml file"
    echo -e "\033[0m"
    help
    exit 1
  elif [[ -n "$eyaml" ]]; then
    EKUST_FILE="$eyaml"
  else
    EKUST_FILE="$eyml"
  fi

  echo "enforce: $EKUST_FILE"
  EKUST_DIR="$edir"

  local ayaml
  ayaml=$(find "$adir" -mindepth 1 -maxdepth 1 -type f -name kustomization.yaml)

  local ayml
  ayml=$(find "$adir" -mindepth 1 -maxdepth 1 -type f -name kustomization.yml)

  if [[ -z "$ayaml" && -z "$ayml" ]]; then
    echo -e "\033[31mERROR: the 'audit' directory '$adir' does not have a kustomization yaml file"
    echo -e "\033[0m"
    help
    exit 1
  elif [[ -n "$ayaml" ]]; then
    AKUST_FILE="$ayaml"
  else
    AKUST_FILE="$ayml"
  fi

  echo "audit: $AKUST_FILE"
  AKUST_DIR="$adir"
}


prereqs() {
  if [[ -z "$(command -v yq)" ]]; then
    echo -e "\033[31mERROR: the yq yaml utility is required."
    echo -e "\033[31m       see https://mikefarah.gitbook.io/yq/"
    echo -e "\033[0m"
    exit 1
  fi

  if [[ -z "$(command -v jq)" ]]; then
    echo -e "\033[31mERROR: the jq json utility is required."
    echo -e "\033[31m       see https://stedolan.github.io/jq/"
    echo -e "\033[0m"
    exit 1
  fi

  if [[ -z "$(command -v kustomize)" ]]; then
    echo -e "\033[31mERROR: the kustomize k8s utility is required."
    echo -e "\033[31m       see https://kustomize.io/"
    echo -e "\033[0m"
    exit 1
  fi

}


dupe_check() {
  apolicies=()
  while IFS='' read -r line; do apolicies+=("$line"); done < <(kustomize build "$AKUST_DIR" | yq -o=json | jq -s 'sort_by(.metadata.name)' | jq -r .[].metadata.name)

  epolicies=()
  while IFS='' read -r line; do epolicies+=("$line"); done < <(kustomize build "$EKUST_DIR" | yq -o=json | jq -s 'sort_by(.metadata.name)' | jq -r .[].metadata.name)

  dupes=()

  for a in "${apolicies[@]}"; do
    if [[ "${epolicies[*]}" =~ ${a} ]]; then
      dupes+=("${a}")
    fi
  done

  if (( ${#dupes[@]} != 0 )); then
    echo
    echo
    echo -e "\033[31mERROR: there are duplicate policies:"
    for d in "${dupes[@]}"; do
      echo "$d"
    done
    echo -e "\033[0m"
    exit 1
  else
    echo
    echo
    echo "There were no duplicate policies found between 'audit' and 'enforce'"
  fi
}


main() {

  # Perform sanity check on command line arguments
  valid_args

  prereqs

  dupe_check
}


parse_args "$@"
main
