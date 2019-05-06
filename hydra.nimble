# Hydra, MIT License
# Copyright (c) 2019 Mamy André-Ratsimbazafy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

packageName   = "hydra"
version       = "0.0.1"
author        = "Mamy André-Ratsimbazafy"
description   = "Integer sets, relation, Integer Linear Programming library and Polyhedral loops scheduling"
license       = "MIT"
skipDirs      = @["tests", "benchmarks"]
### Dependencies

requires "nim >= 0.19"

proc test(name: string, lang: string = "c") =
  if not dirExists "build":
    mkDir "build"
  --run
  switch("out", ("./build/" & name))
  setCommand lang, "tests/" & name & ".nim"

task test, "Run all tests - test and production implementation":
  test "sets"
