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
  ./datatypes,
  ./space, ./presburger_simplify, ./constraint,
  ./matrix

{.experimental:"notnil".}

func newPresburger(
        bp: var BasicPset or BasicPMap,
        space: Space not nil,
        extra: Natural,
        n_eq: Natural,
        n_ineq: Natural 
      ) =
  ## Allocate a BasicPMap 

  new bp
  bp.space = space

  let n_var = space.dim(DimAll)
  let row_size = 1 + n_var + extra

  bp.ctx = space.ctx
  bp.ineq = bp.ctx.newMatrix(row_size, n_ineq)
  bp.eq = bp.ctx.newMatrix(row_size, n_eq)

  if extra > 0:
    bp.divs = bp.ctx.newMatrix(1 + row_size, extra)

func universe*(
    T: typedesc[BasicPset or BasicPMap],
    space: Space not nil
  ): T =
  newPresburger(
    result,
    space,
    0, 0, 0
  )
  result.finalize()

func fromSpace*(
    T: typedesc[BasicPSet or BasicPMap],
    ls: LocalSpace not nil
  ): T =

  let n_div = ls.dim(DimDiv)
  result.newPresburger(ls.space, n_div, 0, 2 * n_div)

  doAssert n_div < extra
  # TODO we overwrite result.div which was initialized previously
  result.divs = ls.divs

  # result.addKnownDivConstraints()


func fromConstraint*(
    T: typedesc[BasicPSet or BasicPMap],
    constraint: Constraint not nil
  ): T =

  # TODO: Sink constraint
  result = fromSpace(constraint.ls)
  