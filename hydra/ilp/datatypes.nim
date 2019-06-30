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
  # Standard lib
  hashes, tables

type
  Label* = ref object
    id*: Hash     # Only needed in nimvm
    name*: string # Only needed for debug purposes

  TermKind* = enum
    tkVar
    tkEnvParam
    tkDivisor  ## Introduced for div, mod or quantifier elimination

  Term* = object
    case kind*: TermKind
    of tkVar:
      varDim*: Natural # Dimension in the space
    of tkEnvParam:
      envParam*: Label # Unique identifier
    of tkDivisor:
      divId*: Natural  # Div identifier in the space

  Space* = ref object
    ## A space is:
    ## * an optional label
    ## * optional environment parameters that are used in constraints
    ## * a fixed number of variables grouped into a variable vector.
    ##
    ## 2 spaces are considered equal if the have the same label,
    ## the same environment parameters and the same rank (i.e. number of variables/arity in the value vector).
    ##
    ## Especially, the 2 spaces B[i, j] and B[u, v] with:
    ## * label B
    ## * no environment parameter
    ## * variable vector of rank 2

    # TODO: use the number of variables as a static parameter.

    # Unique fields
    name*: string
    envParams*: seq[Label]
    rank*: Natural

    # Key-idents mapping.
    idents*: OrderedTable[string, Term]

  ConstraintKind* = enum
    ## Constraint kind
    ckEqualZero # Constraint = 0
    ckGEZero    # Constraint >= 0
    ckMap       # Mapping between i and i', j and j', ...
                # In a sequence of constraints,
                # position will determine if the constraints is for i', j', ...

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

    # Example:
    # Constraint(
    #   eqKind: ckGEZero
    #   terms: @[i, j, N, T]
    #   coefs: @[1, 2, -1, 1]
    #   constant: 3
    # )
    # Represents:
    # i + 2j - N - T + 3 >= 0


func `==`*(a, b: Term): bool =
  ## Object variants need an overload for equality
  ## otherwise we get
  ## "Error: parallel 'fields' iterator does not work for 'case' objects"
  if a.kind != b.kind:
    return false
  elif a.kind == tkVar and a.varDim != b.varDim:
    return false
  elif a.kind == tkEnvParam and a.envParam != b.envParam:
    return false
  elif a.kind == tkDivisor and a.divId != b.divId:
    return false
  else:
    return true
