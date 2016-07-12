#!/bin/bash

test -f "$HOME/load.pid" && exit 0
echo $$ >"$HOME/load.pid" 2>/dev/null || exit 0

if [ -z "$DSC_SERVER" ]; then
  DSC_SERVER="test-server"
fi

if [ -z "$DSC_NODE" ]; then
  DSC_NODE="test-node"
fi

if [ ! -f "$HOME/labler.yaml" ]; then
  touch "$HOME/labler.yaml"
fi

find "$HOME/in" -type f -name '*.xml' |
  while read file; do
    test -f "$file.done" && continue
    perl -I"$HOME/dsc-datatool/lib" \
     "$HOME/dsc-datatool/bin/dsc-datatool" \
     --dataset pcap_stats,transport_vs_qtype,rcode,qtype,edns_bufsiz \
     --output ";Carbon;prefix=dsc;host=localhost;port=2003" \
     --transform ";Labler;*;yaml=$HOME/labler.yaml" \
     --server "$DSC_SERVER" \
     --node "$DSC_NODE" \
     --xml "$file" \
     -v -v -v >"$file.log" 2>&1 && touch "$file.done"
  done

if [ -z "$DSC_LOAD_NODELETE" ]; then
  find "$HOME/in" \
    -type f -name '*.done' -cmin +10 2>/dev/null |
      while read file; do
        rm -f "$file" "$HOME/in/`basename $file .done`" "$HOME/in/`basename $file .done`.log" 2>/dev/null
      done
fi

rm -f "$HOME/load.pid"
