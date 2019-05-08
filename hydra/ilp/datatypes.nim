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
  hashes

type
  Label* = ref object
    id*: Hash # Only needed in nimvm
    when defined(debug):
      name*: string

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
    label*: Label
    envParams*: seq[Label]
    rank*: Natural

    # Key-idents mapping.
    # Should be sorted, Hashtables would be overkill
    idents*: seq[tuple[ident: string, term: Term]]
