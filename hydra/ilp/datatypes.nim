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
  ./context, ./matrix

{.experimental:"notnil".}

type
  DimKind* = enum
    DimCst
    DimParams
    DimIn
    DimOut
    DimSet
    DimDiv
    DimAll

  Space* = ref object {.acyclic.}
    ## Represent the space a set or relation (Map) lives in
    ctx*: Context not nil
    nparams*: Natural
    n_in*: Natural
    n_out*: Natural
    tuple_id*: tuple[dimIn, dimOut: Label]
    nested*: (Space, Space)

    n_id*: Natural
    ids*: ref seq[Label]

  LocalSpace* = ref object
    ## Space with existentially quantified
    ## variables
    space*: Space not nil
    divs*: Matrix not nil

  BasicMapFlags* = enum
    Final
    Empty
    NoImplicit
    NoRedundant
    Rational
    Sorted
    NormalizedDivs
    AllEqualities
    ReducedCoefficients

  BasicPMap* = ref object
    # Presburger Map
    flags*: set[BasicMapFlags]
    ctx*: Context not nil

    space*: Space not nil
    extra*: Natural

    n_eq*: Natural   # Number of equalities
    n_ineq*: Natural # Number of inequalities

    size*: Natural
    eq*: Matrix
    ineq*: Matrix

    n_div*: Natural
    divs*: Matrix

    sample*: seq[int]

  MapFlags = enum
    Disjoint
    Normalized

  PMap* = ref object
    flags: MapFlags
    cached_simple_hull: array[2, BasicPMap]
    ctx: Context
    dim: Space not nil
    n: Natural
    size: Natural
    p: BasicPMap

  BasicPSet* = distinct BasicPMap
  PSet* = distinct PMap

  ConstraintKind* = enum
    CkInequality
    CkEquality

  Constraint* = ref object
    kind*: ConstraintKind
    ls*: LocalSpace not nil
    vec*: seq[int]
