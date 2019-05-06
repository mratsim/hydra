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
  ./context, ./matrix, ./datatypes

{.experimental: "notnil".}

func dim*(space: Space, kind: static DimKind): Natural {.inline.} =
  when kind == DimParams:
    space.nparams
  elif kind == DimIn:
    space.n_in
  elif kind in {DimOut, DimSet}:
    space.n_out
  else:
    static: assert kind == DimAll
    space.nparams + space.n_in + space.n_out

func `==`*(a, b: Space not nil): bool =
  if system.`==`(a, b):
    # Same memory address
    return true
  if a.dim(DimParams) != b.dim(DimParams):
    return false
  if  a.tuple_id.dimIn != b.tuple_id.dimIn or
      a.tuple_id.dimOut != b.tuple_id.dimOut:
    return false
  return a.nested == b.nested

func dim*(ls: LocalSpace, kind: static DimKind): Natural {.inline.} =
  when kind == DimDiv:
    ls.divs.n_rows
  elif kind == DimAll:
    result = ls.space.dim(DimAll)
    result += ls.divs.n_rows
  else:
    ls.space.dim(kind)

func markAsSet(space: Space) {.inline.} =
  space.tuple_id.dimIn = LabelNone

func newSetSpace*(
        ctx: Context not nil,
        nparams: int,
        dim: int
        ): Space =
  new result
  result.ctx = ctx
  result.nparams = nparams
  result.n_out = dim
  result.markAsSet()

func newLocalSpace(space: Space not nil, n_div: Natural = 0): LocalSpace =
  let total = space.dim(DimAll)
  result.space = space
  result.divs = space.ctx.newMatrix(n_div, 1 + 1 + total + n_div)

func offset*(ls: LocalSpace not nil, kind: static DimKind): Natural =
  when kind == DimCst:
    0
  elif kind == DimParams:
    1
  elif kind == DimIn:
    1 + ls.space.nparams
  elif kind in {DimOut, DimSet}:
    1 + ls.space.nparams + ls.space.n_in
  elif kind == DimDiv:
    1 + ls.space.nparams + space.n_in + space.n_out
  else:
    0