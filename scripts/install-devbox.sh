#!/usr/bin/env bash
#set -euo pipefail
set -eo pipefail

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

function error() {
  >&2 echo "ERROR: $1"
  exit 1
}

uname_os() {
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$os" in
    cygwin_nt*) os="windows" ;;
    mingw*) os="windows" ;;
    msys_nt*) os="windows" ;;
  esac
  echo "$os"
}

uname_os_check() {
  os=$(uname_os)
  case "$os" in
    darwin) return 1 ;;
    dragonfly) return 1 ;;
    freebsd) return 1 ;;
    linux) return 0 ;;
    android) return 1 ;;
    nacl) return 1 ;;
    netbsd) return 1 ;;
    openbsd) return 1 ;;
    plan9) return 1 ;;
    solaris) return 1 ;;
    windows) return 1 ;;
  esac
  error "uname_os_check '$(uname -s)' got converted to '$os' which is not an expected value."
}

if ! uname_os_check; then
  error "as this script is intended for GitHub Actions Workflows, only linux is supported"
fi

distro="$(grep ^ID= /etc/os-release | cut -d= -f2)"
if [ "${distro}" != "ubuntu" ] && [ "${distro}" != "alpine" ]; then
  error "only ubuntu and alpine are supported"
fi

if [ -z "${GITHUB_WORKSPACE:-}" ]; then
  error "doesn't appear to be running withing a GitHub Action workflow"
fi

function check_or_install() {
  cmd="${1}"
  if ! hash "${cmd}" >/dev/null 2>&1; then
    echo "Installing ${cmd}"
    if [ "${distro}" = "ubuntu" ]; then
      case "${cmd}" in
        xz)
          pkg="xz-utils";;
        *)
          pkg="${cmd}";;
      esac
      apt-get -y install "${pkg}"
    fi
    if [ "${distro}" = "alpine" ]; then
      sudo apk add "${cmd}"
    fi

    if ! hash "${cmd}" >/dev/null 2>&1; then
      error "Unable to find ${cmd}"
    fi
  fi
}

needed=(
  curl
  git
  sudo
  xz
)

need_to_run_update="no"
for pkg in "${needed[@]}"; do
  if ! hash "${pkg}" >/dev/null 2>&1; then
    need_to_run_update="yes"
    break
  fi
done

if [ "${need_to_run_update}" != "no" ]; then
  if [ "${distro}" = "ubuntu" ]; then
    echo "Running apt-get update"
    apt-get update
  fi
  if [ "${distro}" = "alpine" ]; then
    echo "Running apk update"
    sudo apk update
  fi
  for pkg in "${needed[@]}"; do
    check_or_install "${pkg}"
  done
fi

if ! [ -e "/usr/local/bin/devbox" ]; then
  user="$(whoami)"

  if [ "${distro}" = "alpine" ]; then
    sudo addgroup -g 30000 -S nixbld
    for num in $(seq 1 32); do
      id=$((num + 30000))
      sudo adduser \
        -h /var/empty \
        -g "Nix build user ${num}" \
        -G nixbld \
        -S \
        -s /sbin/nologin \
        -u "${id}" \
        "nixbld${num}"
    done

    devbox_dir="${HOME}/.local/share/devbox"
    if ! [ -e "${devbox_dir}" ]; then
      sudo mkdir -p "${devbox_dir}"
      sudo chmod g-s "${devbox_dir}"
      sudo chown "${user}:${user}" "${devbox_dir}"
      mkdir -p "${devbox_dir}/global/default"
    fi
  fi

  if ! [ -e "/nix" ]; then
    curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon --yes
  fi

  sudo chown -R "${user}:${user}" /nix

  if ! [ -e "/usr/local/bin/devbox" ]; then
    curl -fsSL https://get.jetpack.io/devbox | FORCE=1 bash
  fi

  # Add path
  bashrc="${HOME}/.bashrc"
  if ! grep -qxF "PATH=\$PATH:\$HOME/.local/share/devbox/global/default/.devbox/nix/profile/default/bin" "${bashrc}" 2>/dev/null; then
    echo "PATH=\$PATH:\$HOME/.local/share/devbox/global/default/.devbox/nix/profile/default/bin" >> "${bashrc}"
  fi

  # Setup devbox global devbox.json
  devbox_dir="${HOME}/.local/share/devbox/global/default"
  echo
  echo "setting ${devbox_dir}/devbox.json to ${GITHUB_WORKSPACE}/devbox.json"
  [ -e "${devbox_dir}" ] || mkdir -p "${devbox_dir}"
  [ -e "${devbox_dir}/devbox.json" ] || ln -sf "${GITHUB_WORKSPACE}/devbox.json" "${devbox_dir}/devbox.json"
fi
