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
  unittest,
  ../hydra/ilp/[datatypes, presburger_set, constraints, matrix]

suite "Creating a Presburger set of constraints":
  test "Smoke test - with environment parameters":
    var x = initRawSet()

    x.incl:
      [T,N] -> { S[t,i] : 1<=t-i<T}

    echo "Raw set: "
    echo x

  test "Smoke test - without environment parameters":
    var x = initRawSet()

    x.incl:
      { S[i,j] : 1<=i<=2 and 1<=j<=3 }

    echo "Raw set: "
    echo x

    echo "\nFinalized set: "
    echo x.finalize().ineq

  test "Smoke test - with unused environment parameters":
    var x = initRawSet()

    x.incl:
      [T,N] -> { S[i,j] : 1<=i<=2 and 1<=j<=3 }

    echo "Raw set: "
    echo x

    echo "\nFinalized set: "
    echo x.finalize().ineq


  # test "Creating a set containing even integers between 10 and 42":
  #   discard
