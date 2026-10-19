# PolyBench/C trmm kernel, bounded port. Ohio State Software Distribution License: see benchmarks/t/trmm/LICENSE.txt.

import std/math

const MaxM = 8
const MaxN = 8

proc trmm*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "trmm".} =
  if input.isNil or length != csize_t(2): return -1
  let mValue = input[0]
  let nValue = input[1]
  if not mValue.isFinite or not nValue.isFinite or mValue != floor(mValue) or nValue != floor(nValue) or
      mValue < 1.0 or mValue > float64(MaxM) or nValue < 1.0 or nValue > float64(MaxN): return -1
  let m = int(mValue)
  let n = int(nValue)
  let required = m*n
  if output.isNil or capacity < csize_t(required): return -2
  var a: array[MaxM, array[MaxM, float64]]
  var b: array[MaxM, array[MaxN, float64]]
  for i in 0 ..< m:
    for j in 0 ..< i: a[i][j] = float64((i+j) mod m) / float64(m)
    a[i][i] = 1.0
    for j in 0 ..< n: b[i][j] = float64((n+i-j) mod n) / float64(n)
  for i in 0 ..< m:
    for j in 0 ..< n:
      for k in i+1 ..< m: b[i][j] += a[k][i] * b[k][j]
      b[i][j] *= 1.5
  var staged: array[MaxM*MaxN, float64]
  for i in 0 ..< m:
    for j in 0 ..< n: staged[i*n+j] = b[i][j]
  for i in 0 ..< required: output[i] = staged[i]
  int64(required)
