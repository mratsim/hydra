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
  macros, tables,
  # Internals
  ./datatypes

proc isCmp(node: NimNode): bool =
  node.kind == nnkInfix and (
    node[0].eqIdent"<" or
      node[0].eqIdent"<=" or
      node[0].eqIdent">" or
      node[0].eqIdent">="
  )

proc walkExpr*(rawSetOrMap, spaceFieldIdent, node: NimNode, coef: BiggestInt, constraint: NimNode, stmts: var NimNode): NimNode =
  ## Walk the expression
  ## returns the RHS of comparison
  ## to bubble it up for nested comparisons

  node.expectKind({nnkIdent, nnkIntLit, nnkInfix})
  case node.kind:
  of nnkIdent:
    # Find the term in the space
    let strId = $node
    stmts.add quote do:
      let term = `rawSetOrMap`.`spaceFieldIdent`.idents[`strId`]
      `constraint`.terms.add term
    stmts.add quote do:
      `constraint`.coefs.add `coef`
    return node
  of nnkIntLit:
    let val = coef * node.intVal
    stmts.add quote do:
      `constraint`.constant += `val`
    return node
  of nnkInfix:
    if node[0].eqIdent"+":
      discard walkExpr(rawSetOrMap, spaceFieldIdent, node[1], coef, constraint, stmts)
      discard walkExpr(rawSetOrMap, spaceFieldIdent, node[2], coef, constraint, stmts)
      return node
    elif node[0].eqIdent"-":
      if node.len == 2: # Unary
        discard walkExpr(rawSetOrMap, spaceFieldIdent, node[1], -coef, constraint, stmts)
      elif node.len == 3: # Binary
        discard walkExpr(rawSetOrMap, spaceFieldIdent, node[1], coef, constraint, stmts)
        discard walkExpr(rawSetOrMap, spaceFieldIdent, node[2], -coef, constraint, stmts)
      else:
        error"Unreachable"
      return node
    elif node[0].eqIdent"*":
      if node[1].kind == nnkIntLit:
        discard walkExpr(rawSetOrMap, spaceFieldIdent, node[2], coef * node[1].intVal, constraint, stmts)
      elif node[2].kind == nnkIntLit:
        discard walkExpr(rawSetOrMap, spaceFieldIdent, node[1], coef * node[2].intVal, constraint, stmts)
      else:
        error "[Non-affine constraint error] One of the multiplication term must be a integer constant."
      return node
    elif node[0].eqIdent">=":
      # Canonical form is "expr >= 0"
      # left hand-side is as is
      # right hand-side is negated
      # a >= b  <=> a - b >= 0
      let subconstraint = genSym(nskVar, "constraintGE_")
      stmts.add quote do:
        var `subconstraint` = Constraint(eqKind: ckGEZero)

      let lhs = walkExpr(rawSetOrMap, spaceFieldIdent, node[1], 1, subconstraint, stmts)
      let rhs = walkExpr(rawSetOrMap, spaceFieldIdent, node[2], -1, subconstraint, stmts)

      # Nested comparison 0 <= i < N
      # Solve 0 <= i then i < N
      if lhs != node[1]:
        discard walkExpr(rawSetOrMap, spaceFieldIdent, lhs, 1, subconstraint, stmts)

      stmts.add quote do:
        `rawSetOrMap`.constraints.add `subconstraint`
      return rhs
    elif node[0].eqIdent">":
      # a > 0   <=>   a - 1 >= 0
      let subconstraint = genSym(nskVar, "constraintGR_")
      stmts.add quote do:
        var `subconstraint` = Constraint(eqKind: ckGEZero, constant: -1)

      let lhs = walkExpr(rawSetOrMap, spaceFieldIdent, node[1], 1, subconstraint, stmts)
      let rhs = walkExpr(rawSetOrMap, spaceFieldIdent, node[2], -1, subconstraint, stmts)

      if lhs != node[1]:
        discard walkExpr(rawSetOrMap, spaceFieldIdent, lhs, 1, subconstraint, stmts)

      stmts.add quote do:
        `rawSetOrMap`.constraints.add `subconstraint`
      return rhs
    elif node[0].eqIdent"<=":
      # a <= 10   <=>   0 <= 10 - a  <=>  10 - a >= 0
      let subconstraint = genSym(nskVar, "constraintLE_")
      stmts.add quote do:
        var `subconstraint` = Constraint(eqKind: ckGEZero)

      let lhs = walkExpr(rawSetOrMap, spaceFieldIdent, node[1], -1, subconstraint, stmts)
      let rhs = walkExpr(rawSetOrMap, spaceFieldIdent, node[2], 1, subconstraint, stmts)

      if lhs != node[1]:
        discard walkExpr(rawSetOrMap, spaceFieldIdent, lhs, -1, subconstraint, stmts)

      stmts.add quote do:
        `rawSetOrMap`.constraints.add `subconstraint`
      return rhs
    elif node[0].eqIdent"<":
      # a < 10   <=>   0 < 10 - a  <=>  10 - a > 0 <=>  10 - a - 1 >= 0
      let subconstraint = genSym(nskVar, "constraintLR_")
      stmts.add quote do:
        var `subconstraint` = Constraint(eqKind: ckGEZero, constant: -1)

      let lhs = walkExpr(rawSetOrMap, spaceFieldIdent, node[1], -1, subconstraint, stmts)
      let rhs = walkExpr(rawSetOrMap, spaceFieldIdent, node[2], 1, subconstraint, stmts)

      if lhs != node[1]:
        discard walkExpr(rawSetOrMap, spaceFieldIdent, lhs, -1, subconstraint, stmts)

      stmts.add quote do:
        `rawSetOrMap`.constraints.add `subconstraint`
      return rhs
    elif node[0].eqIdent"and":
      discard walkExpr(rawSetOrMap, spaceFieldIdent, node[1], 1, NimNode(), stmts)
      discard walkExpr(rawSetOrMap, spaceFieldIdent, node[2], 1, NimNode(), stmts)
    elif node[0].eqIdent"or":
      error "[\"or\" operator error] Expression requires a disjoint set or map"
    else:
      error "Unsupported infix operator: " & $node[0]
  else:
    error "Unreachable"

proc parseSetConstraints*(rawSet, expression: NimNode, stmts: var NimNode) =
  discard walkExpr(rawSet, ident"space", expression, 1, NimNode(), stmts)

func `$`*(c: Constraint): string =
  assert c.terms.len == c.coefs.len
  assert c.terms.len >= 1

  for i in 0 ..< c.terms.len:
    # Print coef if != 0
    if c.coefs[i] > 1:
      if i != 0:
        result.add " + "
      result.add $c.coefs[i]
    elif c.coefs[i] == 1:
      if i != 0:
        result.add " + "
    elif c.coefs[i] == -1:
      if i == 0:
        result.add "-"
      else:
        result.add " - "
    elif c.coefs[i] < -1:
      if i == 0:
        result.add $c.coefs[i]
      else:
        result.add " - " & $(-c.coefs[i])

    # Print term
    if c.coefs[i] != 0:
      case c.terms[i].kind
      of tkVar:
        result.add 'i'
        result.add $c.terms[i].varDim
      of tkEnvParam:
        result.add c.terms[i].envParam.name
      of tkDivisor:
        raise newException(ValueError, "Not supported")

  # Print constant if != 0
  if c.constant > 0:
    result.add " + "
    result.add $c.constant
  elif c.constant < 0:
    result.add " - "
    result.add $(-c.constant)

  # Print in/equality constraint
  case c.eqKind
  of ckEqualZero:
    result.add " = 0"
  of ckGEZero:
    result.add " >= 0"
