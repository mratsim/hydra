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

proc newLabel(name: string): Label =
  new result
  when defined(nimvm):
    result.id = rng.rand(high(int))
  else:
    result.id = cast[Hash](result)
  result.name = name

proc initRawMap*(): RawMap =
  new result.in_space
  new result.out_space

proc envParamSetup(rawMap: NimNode,
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
      `rawMap`.in_space.idents = initTable[string, Term](initialSize = 8)
      `rawMap`.out_space.idents = initTable[string, Term](initialSize = 8)
    for p in envParams:
      let p_str = $p
      let id_p = ident("envParam_" & p_str)
      result.envLabels.add id_p
      result.statement.add newLetStmt(id_p, newCall(bindSym"newLabel", newLit p_str))

      let envTerm = quote do:
        Term(kind: tkEnvParam, envParam: `id_p`)

      result.statement.add quote do:
        `rawMap`.in_space.envParams.add `id_p`
        `rawMap`.in_space.idents[`p_str`] = `envTerm`
        `rawMap`.out_space.envParams.add `id_p`
        `rawMap`.out_space.idents[`p_str`] = `envTerm`

      result.envTerms.add envTerm

proc spaceSetup(rawMap: NimNode,
                init: bool,
                spaceAST: NimNode):
                tuple[statement: NimNode, varTerms: seq[NimNode]] =
  ## Check that the domain spaces (in_space) are the same
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
        `rawMap`.in_space.name = `name`

      offset = 1
    # Anonymous space - [T, N]
    else:
      offset = 0

    let rank = spaceAST.len - offset
    result.statement.add quote do:
      `rawMap`.in_space.rank = `rank`
    for i in offset ..< spaceAST.len:
      let dim = i - offset
      let variable = quote do:
        Term(kind: tkVar, varDim: `dim`)

      let v_str = $spaceAST[i]
      result.statement.add quote do:
        `rawMap`.in_space.idents[`v_str`] = `variable`

      result.varTerms.add variable

proc parseSchedule*(rawMap, expression: NimNode, stmts: var NimNode) =
  ## Parse a schedule/map relation like
  ## { S[i,j] -> [j,i] }
  ##
  ## which creates a new set S' with i'=j and j'=i
  ##
  ## { S[i,j] -> S'[i',j']: i=j' and j=i'}
  ##
  ## In matrix form
  ##   (i')   | 0 1 | (i)
  ##   (j') = | 1 0 | (j)
  ##
  ## Input:
  ##   - the range (out space)
  ##     in the example it would be "[j, i]"

  # We have 1 constraint per iteration variable in the range space (out space)

  expression.expectKind nnkBracket
  for iterator_mapping in expression:
    let constraint = genSym(nskVar, "constraintMap")
    stmts.add quote do:
      var `constraint` = Constraint(eqKind: ckMap)
    rawMap.parseMapConstraints(iterator_mapping, constraint, stmts)
    stmts.add quote do:
      `rawMap`.constraints.add `constraint`

macro add*(rawmap: RawMap, expression: untyped): untyped =
  ## Add a relation to an existing map

  result = newStmtList()
  echo expression.treeRepr

  expression.expectKind nnkStmtList
  expression[0].expectKind(nnkInfix)

  let init = true # TODO

  if init:
    result.add quote do:
      assert `rawMap`.in_space.name.len == 0
      assert `rawMap`.in_space.envParams.len == 0
      assert `rawMap`.in_space.rank == 0
      assert `rawMap`.in_space.idents.len == 0

  # Parsing: [T,N] -> { S[i,j] -> [j, i] } (a loop interchange)
  if expression[0][1].kind == nnkBracket:
    # Parsing the environment declaration
    # [T, N] -> ...

    let (envStmt, envLabels, envTerms) = envParamSetup(rawmap, true, expression[0][1])
    result.add nnkBlockStmt.newTree(
      ident"envSetup", envStmt
    )

    # Parsing the domain space declaration
    # ... -> { S[i,j] -> ... }
    expression[0][2].expectKind nnkCurly
    expression[0][2][0].expectKind nnkInfix
    assert expression[0][2][0][0].eqIdent"->"

    let (spaceStmt, spaceVars) = spaceSetup(rawmap, true, expression[0][2][0][1])
    result.add nnkBlockStmt.newTree(
      ident"spaceSetup", spaceStmt
    )

    # Parsing the range space declaration (i.e. out space or new schedule)
    # ... -> { ... -> [j, i] }
    var constraints = newStmtList()
    rawmap.parseSchedule(expression[0][2][0][2], constraints)

    result.add nnkBlockStmt.newTree(
      ident"constraintSetup", constraints
    )

  echo result.toStrLit
