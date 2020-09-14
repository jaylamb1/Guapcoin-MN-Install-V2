#!/bin/bash

declare -a status=$(guapcoin-cli listmasternodes | grep "GVAoFzHLpVh8ML7mXNpM9cEbjHoBdbQtJH" -A5 -B7)

echo "{$status[@]}"
