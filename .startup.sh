#!/bin/bash

set -eo pipefail

sh -c "$(curl -fsLS get.chezmoi.io)" -- init --verbose --apply jarodtaylor
