#!/bin/sh

base=`dirname $0`

export PATH="$base:$PATH"

"$base/test.sh"
