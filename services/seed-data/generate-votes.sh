#!/bin/sh
set -e

VOTE_URL="${VOTE_URL:-http://vote/}"

SEED_A_REQUESTS="${SEED_A_REQUESTS:-100}"
SEED_B_REQUESTS="${SEED_B_REQUESTS:-100}"
SEED_A2_REQUESTS="${SEED_A2_REQUESTS:-100}"
SEED_CONCURRENCY="${SEED_CONCURRENCY:-5}"

echo "Seeding votes to ${VOTE_URL} (concurrency=${SEED_CONCURRENCY})..."

ab -n "${SEED_A_REQUESTS}" -c "${SEED_CONCURRENCY}" -p posta -T "application/x-www-form-urlencoded" "${VOTE_URL}"
ab -n "${SEED_B_REQUESTS}" -c "${SEED_CONCURRENCY}" -p postb -T "application/x-www-form-urlencoded" "${VOTE_URL}"
ab -n "${SEED_A2_REQUESTS}" -c "${SEED_CONCURRENCY}" -p posta -T "application/x-www-form-urlencoded" "${VOTE_URL}"

echo "Done seeding"
