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
  # Standard library
  macros, random, hashes, tables,
  # Internals
  ./datatypes, ./constraints

{.experimental: "notnil".}

type
  RawMap* = object
    ## A raw map or relation is:
    ## * An in-space
    ## * An out-space
    ## * Constraints
    ##
    ## The constraints represent a transformation that maps
    ## the input space (domain space) to an output space (range space)
    ##
    ## For example, given a statement S that depends on i, j iteration variables:
    ##
    ## ```Nim
    ## for i in 1 .. 2:
    ##   for j in 1 .. 3:
    ##     S(i, j)
    ## ```
    ##
    ## The original schedule (ordering)
    ##   - S(1, 1), S(1, 2), S(1, 3)
    ##   - S(2, 1), S(2, 2), S(2, 3)
    ##
    ## Graphically:
    ##  j ^
    ##    |
    ##    |
    ##  3 + 3 6
    ##    |
    ##  2 + 2 5
    ##    |
    ##  1 + 1 4
    ##    |
    ##    +-+-+-+-->
    ##      1 2 3  i
    ##
    ## This is represented by the inequality constraints (i.e `set`):
    ##
    ## |  1  0 |       (-1)   (0)
    ## | -1  0 | (i)   ( 2)   (0)
    ## |  0  1 | (j) + (-1) ≥ (0)
    ## |  0 -1 |       ( 3)   (0)
    ##
    ## in canonical form Ax + a ≥ 0
    ##
    ## If we want interchange the loop:
    ## ```Nim
    ## for i' in 1 .. 3:
    ##   for j' in 1 .. 2:
    ##     S(j', i')
    ## ```
    ##
    ## The new schedule is
    ##   - S(1, 1), S(2, 1)
    ##   - S(1, 2), S(2, 2)
    ##   - S(1, 3), S(2, 3)
    ## (j'==i and i' == j)
    ##
    ## Graphically:
    ## j' ^
    ##    |
    ##    |
    ##  3 +
    ##    |
    ##  2 + 4 5 6
    ##    |
    ##  1 + 1 2 3
    ##    |
    ##    +-+-+-+-->
    ##      1 2 3  i'
    ##
    ## This is represented by the inequality constraints (i.e `set`):
    ##
    ## |  0  1 |        (-1)   (0)
    ## |  0 -1 | (i')   ( 2)   (0)
    ## |  1  0 | (j') + (-1) ≥ (0)
    ## | -1  0 |        ( 3)   (0)
    ##
    ## The Map/Relation is the transformation T that respects the following proprieties:
    ##
    ## - (AT^-1)y + a ≥ 0
    ## - y = Tx
    ##
    ## we have:
    ##   (i')   | 0 1 | (i)
    ##   (j') = | 1 0 | (j)
    ##
    ## in Hydra syntax:
    ## { S[i,j] -> [j,i] }

    in_space*: Space not nil
    out_space*: Space not nil
    constraints*: seq[Constraint]
