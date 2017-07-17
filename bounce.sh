#!/usr/bin/env bash

set -e
set -x

# Stop all apps
br apps | awk 'NR>1 {print $1}' | while read id ; do ( echo stop $id && br app $id effector stop invoke ) ; done

# Uninstall
$( dirname $0 )/uninstall.sh

# Install
br catalog add catalog

# Deploy a blueprint
br deploy sample-blueprint.yaml
