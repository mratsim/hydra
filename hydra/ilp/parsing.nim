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

type
  FormulaKind = enum
    # Presburger Formula kind
    fkAdd
    fkSub
    fkEQ        # equal
    # fkLE      # lower or equal
    # fkLT      # lower
    fkGE        # greater or equal
    fkGT        # greater
    # pfkNE     # not equal
    fkMul       # Multiply (lhs must be const)
    # pfkLexLE
    # pfkLexLR
    fkLexGE     # Lexicographically greater or equal (i, j) >>= (k, l)
    fkLexGR
    fkMod       # Modulo
    fkTrue      # True
    fkFalse     # False
    fkAnd       # And
    fkOr        # Or
    fkNot       # Negation
    fkImplies   # Implies
    fkExists    # Exists
    fkNotExists # Not exists