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

proc walkExpr(rawSet, node: NimNode, coef: BiggestInt, constraint: NimNode, stmts: var NimNode): tuple[lhs, rhs: NimNode] =
  ## Walk the expression
  ## returns RHS and LHS of comparison
  ## to bubble them up for nested comparisons
  
  node.expectKind({nnkIdent, nnkIntLit, nnkInfix})
  case node.kind:
  of nnkIdent:
    # Find the term in the space
    let strId = $node
    stmts.add quote do:
      let term = `rawSet`.space.idents[`strId`]
      `constraint`.terms.add term
    stmts.add quote do:
      `constraint`.coefs.add `coef`
    return (node, node)
  of nnkIntLit:
    let val = coef * node.intVal
    stmts.add quote do:
      `constraint`.constant += `val`
    return (node, node)
  of nnkInfix:
    if node[0].eqIdent"+":
      discard walkExpr(rawSet, node[1], coef, constraint, stmts)
      discard walkExpr(rawSet, node[2], coef, constraint, stmts)
      return (node, node)
    elif node[0].eqIdent"-":
      if node.len == 2: # Unary
        discard walkExpr(rawSet, node[1], -coef, constraint, stmts)
      elif node.len == 3: # Binary
        discard walkExpr(rawSet, node[1], coef, constraint, stmts)
        discard walkExpr(rawSet, node[2], -coef, constraint, stmts)
      else:
        error"Unreachable"
      return (node, node)
    elif node[0].eqIdent"*":       
      if node[1].kind == nnkIntLit:
        discard walkExpr(rawSet, node[2], coef * node[1].intVal, constraint, stmts)
      elif node[2].kind == nnkIntLit:
        discard walkExpr(rawSet, node[1], coef * node[2].intVal, constraint, stmts)
      else:
        error "[Non-affine constraint error] One of the multiplication term must be a integer constant."
      return (node, node)
    elif node[0].eqIdent">=":
      # Canonical form is "expr >= 0"
      # left hand-side is as is
      # right hand-side is negated
      # a >= b  <=> a - b >= 0
      let subconstraint = genSym(nskVar, "constraintGE_")
      stmts.add quote do:
        var `subconstraint` = Constraint(eqKind: ckGEZero)
      let (_, lhs) = walkExpr(rawSet, node[1], 1, subconstraint, stmts)
      let (rhs, _) = walkExpr(rawSet, node[2], -1, subconstraint, stmts)
      stmts.add quote do:
        `rawSet`.constraints.add `subconstraint`
      return (lhs, rhs)
    elif node[0].eqIdent">":
      # a > 0   <=>   a - 1 >= 0
      let subconstraint = genSym(nskVar, "constraintGR_")
      stmts.add quote do:
        var `subconstraint` = Constraint(eqKind: ckGEZero, constant: -1)
      let (_, lhs) = walkExpr(rawSet, node[1], 1, subconstraint, stmts)
      let (rhs, _) = walkExpr(rawSet, node[2], -1, subconstraint, stmts)
      stmts.add quote do:
        `rawSet`.constraints.add `subconstraint`
      return (lhs, rhs)
    elif node[0].eqIdent"<=":
      # a <= 10   <=>   0 <= 10 - a  <=>  10 - a >= 0
      let subconstraint = genSym(nskVar, "constraintLE_")
      stmts.add quote do:
        var `subconstraint` = Constraint(eqKind: ckGEZero)
      let (_, lhs) = walkExpr(rawSet, node[1], -1, subconstraint, stmts)
      let (rhs, _) = walkExpr(rawSet, node[2], 1, subconstraint, stmts)
      stmts.add quote do:
        `rawSet`.constraints.add `subconstraint`
      return (lhs, rhs)
    elif node[0].eqIdent"<":
      # a < 10   <=>   0 < 10 - a  <=>  10 - a > 0 <=>  10 - a - 1 >= 0
      let subconstraint = genSym(nskVar, "constraintLR_")
      stmts.add quote do:
        var `subconstraint` = Constraint(eqKind: ckGEZero, constant: -1)
      let (_, lhs) = walkExpr(rawSet, node[1], -1, subconstraint, stmts)
      let (rhs, _) = walkExpr(rawSet, node[2], 1, subconstraint, stmts)
      stmts.add quote do:
        `rawSet`.constraints.add `subconstraint`
      return (lhs, rhs)
    elif node[0].eqIdent"and":
      discard walkExpr(rawSet, node[1], 1, NimNode(), stmts)
      discard walkExpr(rawSet, node[2], 1, NimNode(), stmts)
    elif node[0].eqIdent"or":
      error "[\"or\" operator error] Expression requires a disjoint set or map"
    else:
      error "Unsupported infix operator: " & $node[0]
  else:
    error "Unreachable"

proc parseConstraints*(rawSet, expression: NimNode, stmts: var NimNode) =
  discard walkExpr(rawSet, expression, 1, NimNode(), stmts)