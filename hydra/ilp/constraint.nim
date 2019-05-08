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
  # Internals
  ./datatypes

type
  ConstraintKind* = enum
    ## Constraint kind
    ckEqualZero # Constraint = 0
    ckGEZero    # Constraint >= 0

  Constraint* = object
    ## Constraint in "canonical" form
    ## We will have to introduce extra divisors to the space
    ## to handle `div`, `mod` and `There exists` formulas.
    ##
    ## Constraints should always be attached to a Set or Map
    ## as they are always relative to their space.

    # space*: Space
    eqKind*: ConstraintKind

    terms*: seq[Term]
    coefs*: seq[int]

    constant*: int
