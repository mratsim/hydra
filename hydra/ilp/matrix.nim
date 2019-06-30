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
  Matrix* = object
    ## A simple matrix type
    ## to represent matrices of constraints
    ## and polyhedral loop transformations
    # The type must work at Nim compile-time
    # The matrix is row-major
    nrows, ncols: int
    data: seq[int]

func newMatrix*(nrows, ncols: int): Matrix =
  result = Matrix(
    nrows: nrows,
    ncols: ncols,
    data: newSeq[int](nrows * ncols)
  )

func `[]`*(m: Matrix, row, col: int): int =
  m.data[row*m.ncols + col]

func `[]=`*(m: var Matrix, row, col, val: int) =
  m.data[row*m.ncols + col] = val

func appendCoefsAndConstant*(m: var Matrix, coefs: openarray[int], constant: int) =
  # We store our coefficients + constant in columns
  doAssert coefs.len + 1 == m.ncols

  m.data.add coefs
  m.data.add constant
  m.nrows += 1

func `$`*(m: Matrix): string =

  for row in 0 ..< m.nrows:
    result.add "\n|"
    for col in 0 ..< m.ncols:
      result.add "\t" & $m[row, col]
    result.add "\t|"
