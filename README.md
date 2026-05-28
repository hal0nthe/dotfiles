# dotfiles

This repo contains the configuration to setup my machines with Hyprland installed. This is using [Chezmoi](https://chezmoi.io), the dotfile manager to setup the install.
And [Ansible](https://docs.ansible.com) to automating.

This automated setup is currently only configured for Arch machines.

## Install base package

```shell
sudo pacman -S git chezmoi ansible --needed
```

## How to run

```shell
export GITHUB_USERNAME=hal0nthe
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
~/.bootstrap
```
