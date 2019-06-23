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
      `rawSet`.space.idents = initTable[string, Term](initialSize = 8)
    for p in envParams:
      let p_str = $p
      let id_p = ident("envParam_" & p_str)
      result.envLabels.add id_p
      result.statement.add newLetStmt(id_p, newCall(bindSym"newLabel", newLit p_str))

      let envTerm = quote do:
        Term(kind: tkEnvParam, envParam: `id_p`)

      result.statement.add quote do:
        `rawSet`.space.envParams.add `id_p`
        `rawSet`.space.idents[`p_str`] = `envTerm`

      result.envTerms.add envTerm

proc spaceSetup(rawSet: NimNode,
                init: bool,
                spaceAST: NimNode):
                tuple[statement: NimNode, varTerms: seq[NimNode]] =
  ## Check that the spaces are the same
  ## Initialize them
  ## Return statements and sequence
  spaceAST.expectKind({nnkBracket, nnkBracketExpr})

  result.statement = newStmtList()

  if init:
    var offset: int
    # Named space - S[T, N]
    if spaceAST.kind == nnkBracketExpr:
      let name = $spaceAST[0]
      result.statement.add quote do:
        `rawSet`.space.name = `name`

      offset = 1
    # Anonymous space - [T, N]
    else:
      offset = 0

    let rank = spaceAST.len - offset
    result.statement.add quote do:
      `rawSet`.space.rank = `rank`
    for i in offset ..< spaceAST.len:
      let dim = i - offset
      let variable = quote do:
        Term(kind: tkVar, varDim: `dim`)

      let v_str = $spaceAST[i]
      result.statement.add quote do:
        `rawSet`.space.idents[`v_str`] = `variable`

      result.varTerms.add variable

macro incl*(rawset: RawSet, expression: untyped): untyped =
  ## Add a constraint to an existing raw set
  ## Constraints added are cumulative to the existing ones
  result = newStmtList()
  echo expression.treeRepr

  expression.expectKind nnkStmtList
  expression[0].expectKind({nnkInfix, nnkTableConstr})

  let init = true # TODO

  if init:
    result.add quote do:
      assert `rawset`.space.name.len == 0
      assert `rawSet`.space.envParams.len == 0
      assert `rawset`.space.rank == 0
      assert `rawset`.space.idents.len == 0

  # Parsing: [T,N] -> { S[t,i] : 1<=t<=T and 1<=i<=N }
  if expression[0].kind == nnkInfix:
    # Parsing the environment declaration
    # [T, N] -> ...
    assert expression[0][0].eqIdent"->"
    expression[0][1].expectKind nnkBracket

    let (envStmt, envLabels, envTerms) = envParamSetup(rawset, true, expression[0][1])
    result.add nnkBlockStmt.newTree(
      ident"envSetup", envStmt
    )

    # Parsing the space declaration
    # ... -> { S[t,i] : ... }
    expression[0][2].expectKind nnkTableConstr
    expression[0][2][0].expectKind nnkExprColonExpr

    let (spaceStmt, spaceVars) = spaceSetup(rawset, true, expression[0][2][0][0])
    result.add nnkBlockStmt.newTree(
      ident"spaceSetup", spaceStmt
    )

    # Parsing the constraints
    # ... -> { ... : 1<=t<=T and 1<=i<=N }
    var constraints = newStmtList()
    rawSet.parseSetConstraints(expression[0][2][0][1], constraints)

    result.add nnkBlockStmt.newTree(
      ident"constraintSetup", constraints
    )

  echo result.toStrLit
