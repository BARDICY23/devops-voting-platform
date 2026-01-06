#!/bin/sh

ab -n 1000 -c 50 -p posta http://vote/
ab -n 1000 -c 50 -p postb http://vote/
ab -n 1000 -c 50 -p posta http://vote/

