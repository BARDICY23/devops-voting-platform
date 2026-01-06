#!/bin/sh
set -e

echo "Seeding votes (low concurrency)..."

ab -n 100 -c 5 -p posta -T "application/x-www-form-urlencoded" http://vote.voting.svc.cluster.local/
ab -n 100 -c 5 -p postb -T "application/x-www-form-urlencoded" http://vote.voting.svc.cluster.local/
ab -n 100 -c 5 -p posta -T "application/x-www-form-urlencoded" http://vote.voting.svc.cluster.local/

echo "Done seeding"

