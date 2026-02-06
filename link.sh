#!/bin/bash

set -e

rm -f TipTacItemRef/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua
rm -f TipTacOptions/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua
rm -f TipTacTalents/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua

ln ./TipTac/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua ./TipTacItemRef/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua
ln ./TipTac/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua ./TipTacOptions/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua
ln ./TipTac/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua ./TipTacTalents/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua
