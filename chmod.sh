#!/bin/bash

set -e

find . -type d | xargs chmod 755
find . -type f | xargs chmod 644
