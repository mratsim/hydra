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
  macros, algorithm, random, hashes,
  # Internals
  ./datatypes

{.experimental: "notnil".}

type
  RawSet* = object
    ## A raw set is:
    ## * A space
    ## * Constraints
    space*: Space not nil
    constraints*: seq[Constraint]

var rng {.compileTime.} = initRand(0xDEADBEEF)
  ## Compile-time RNG seed

proc newLabel(name: string): Label =
  new result
  when defined(nimvm):
    result.id = rng.rand(high(int))
  else:
    result.id = cast[Hash](result)
  result.name = name

proc initRawSet*(): RawSet =
  new result.space

proc envParamSetup(rawSet: NimNode,
                   init: bool,
                   envParams: NimNode):
                   tuple[statement: NimNode, envLabels, envTerms: seq[NimNode]] =
  ## Check that environment parameters are the same
  ## Initialize them
  ## Return statements and sequence
  envParams.expectKind nnkBracket

  result.statement = newStmtList()

  if init:
    result.statement.add quote do:
      assert `rawset`.space.label.isNil
      assert `rawSet`.space.envParams.len == 0
      assert `rawset`.space.rank == 0
      assert `rawset`.space.idents.len == 0

    for p in envParams:
      let p_str = $p
      let id_p = ident("envParam_" & p_str)
      result.envLabels.add id_p
      result.statement.add newLetStmt(id_p, newCall(bindSym"newLabel", newLit p_str))
      
      let envTerm = quote do:
        Term(kind: tkEnvParam, envParam: `id_p`)
      
      result.statement.add quote do:
        `rawSet`.space.envParams.add `id_p`
        `rawSet`.space.idents.add (`p_str`, `envTerm`)
      
      result.envTerms.add envTerm

macro incl*(rs: RawSet, expression: untyped): untyped =
  ## Add a constraint to an existing raw set
  ## Constraints added are cumulative to the existing ones
  result = newStmtList()
  echo expression.treeRepr

  expression.expectKind nnkStmtList
  expression[0].expectKind({nnkInfix, nnkTableConstr})

  if expression[0].kind == nnkInfix:
    assert expression[0][0].eqIdent"->"
    expression[0][1].expectKind nnkBracket

    let (envStmt, envLabels, envTerms) = envParamSetup(rs, true, expression[0][1])


    result.add envStmt
    result.add quote do: `envTerms`