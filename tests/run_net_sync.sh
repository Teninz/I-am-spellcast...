#!/bin/sh
# Проверка сетевой игры: хозяин и гость играют по сети на одной машине, отпечатки должны совпасть.
#   sh tests/run_net_sync.sh /путь/к/godot
GODOT=${1:-godot}
PORT=${2:-7795}
OUT=${TMPDIR:-/tmp}
$GODOT --headless --path . --script res://tests/net_sync.gd -- role=host port=$PORT > $OUT/net_host.log 2>&1 &
sleep 3
$GODOT --headless --path . --script res://tests/net_sync.gd -- role=client port=$PORT > $OUT/net_client.log 2>&1
wait
grep "^SYNC\|^END" $OUT/net_host.log > $OUT/net_host.sync
grep "^SYNC\|^END" $OUT/net_client.log > $OUT/net_client.sync
cat $OUT/net_host.sync
if [ -s $OUT/net_host.sync ] && cmp -s $OUT/net_host.sync $OUT/net_client.sync; then
	echo "ok: у хозяина и гостя одинаковое состояние после каждого боя"
else
	echo "FAIL: состояния разошлись"; diff $OUT/net_host.sync $OUT/net_client.sync; exit 1
fi
