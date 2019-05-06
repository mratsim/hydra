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

import
  ./context,
  sequtils

{.experimental: "notnil".}

type
  Matrix* = ref object
    ## Matrix object representing constraints
    ## Either == 0 or >= 0
    ctx: Context not nil # TODO - useful?
    data: seq[seq[int]]
      # TODO: Refactor away the double indirection
      #       The ISL C lib has too much memory management boilerplate
      #       and field access indirection
      #       compared to actual functionality

template n_rows*(m: Matrix): Natural =
  m.data.len
template n_cols*(m: Matrix): Natural =
  m.data[0].len

func newMatrix*(ctx: Context, n_rows, n_cols: Natural): Matrix not nil =
  new result
  result.data = newSeqWith(n_rows, newSeq[int](n_cols))

template `[]`*(m: Matrix, i, j: Natural): int =
  m.data[i][j]