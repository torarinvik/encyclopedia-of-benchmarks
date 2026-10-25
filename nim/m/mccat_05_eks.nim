/****
    Copyright (C) 1996 McGill University.
    Copyright (C) 1996 McCAT System Group.
    Copyright (C) 1996 ACAPS Benchmark Administrator
                       benadmin@acaps.cs.mcgill.ca

    This program is free software; you can redistribute it and/or modify
    it provided this copyright notice is maintained.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
****/
import math

const MinN = 3
const MaxN = 8
const MaxInput = 66
const InputScale = 1_000_000.0
const OutputScale = 1_000.0
const QrEpsilon = 1.0e-10
const MaxQrSteps = 4096

proc absd(value: float64): float64 =
  if value < 0.0: -value else: value

proc givens(a, b: float64): tuple[s, c: float64] =
  if b == 0.0: return (0.0, 1.0)
  if absd(b) > absd(a):
    let t = -a / b
    let s = 1.0 / sqrt(1.0 + t * t)
    return (s, s * t)
  let t = -b / a
  let c = 1.0 / sqrt(1.0 + t * t)
  (c * t, c)

proc applyGivens(a: var array[64, float64], n: int, s, c: float64,
                 i, j, start, ending: int) =
  for k in start .. ending:
    let x = a[i*n+k]
    let y = a[j*n+k]
    a[i*n+k] = c*x - s*y
    a[j*n+k] = s*x + c*y
  for k in start .. ending:
    let x = a[k*n+i]
    let y = a[k*n+j]
    a[k*n+i] = c*x - s*y
    a[k*n+j] = s*x + c*y

proc reduceBand(a: var array[64, float64], n, bandwidth: int) =
  for i in countdown(bandwidth, 2):
    for j in 0 ..< n-i:
      let (s, c) = givens(a[j*n+j+i-1], a[j*n+j+i])
      let ending = min(j+2*i, n-1)
      applyGivens(a, n, s, c, j+i-1, j+i, j, ending)
      var m = j+i
      while m < n-i:
        let (s2, c2) = givens(a[(m-1)*n+m+i-1], a[(m-1)*n+m+i])
        let end2 = min(m+2*i, n-1)
        applyGivens(a, n, s2, c2, m+i-1, m+i, m-1, end2)
        m += i

proc qrIterate(a: var array[64, float64], n: int): bool =
  var steps = 0
  while true:
    for i in 0 ..< n-1:
      if absd(a[(i+1)*n+i]) < (absd(a[i*n+i])+absd(a[(i+1)*n+i+1]))*QrEpsilon:
        a[(i+1)*n+i] = 0.0
        a[i*n+i+1] = 0.0
    var q = n-1
    while q > 0 and a[(q-1)*n+q] == 0.0: dec q
    if q == 0: return true
    inc steps
    if steps > MaxQrSteps: return false
    var p = q
    while p > 0 and a[(p-1)*n+p] != 0.0: dec p
    let d = (a[(q-1)*n+q-1] - a[q*n+q]) / 2.0
    let t = a[q*n+q-1] * a[q*n+q-1]
    let shiftSign = if d < 0.0: -1.0 else: 1.0
    let mu = a[q*n+q] - t / (d + shiftSign * sqrt(d*d+t))
    var x = a[p*n+p] - mu
    var z = a[(p+1)*n+p]
    for i in p ..< q:
      let (s, c) = givens(x, z)
      let l = if i > p: i-1 else: p
      let m = min(q, i+2)
      for k in l .. m:
        let u = a[i*n+k]
        let v = a[(i+1)*n+k]
        a[i*n+k] = c*u - s*v
        a[(i+1)*n+k] = s*u + c*v
      for k in l .. m:
        let u = a[k*n+i]
        let v = a[k*n+i+1]
        a[k*n+i] = c*u - s*v
        a[k*n+i+1] = s*u + c*v
      if i < q-1:
        x = a[(i+1)*n+i]
        z = a[(i+2)*n+i]
  false

proc project(value: float64): int32 =
  let scaled = value * OutputScale
  if scaled >= 0.0: int32(floor(scaled + 0.5)) else: int32(ceil(scaled - 0.5))

proc before(left, right: float64): bool =
  absd(left) > absd(right) or (absd(left) == absd(right) and left < right)

proc putI32Le(value: int32, output: var array[32, uint8], offset: int) =
  let bits = cast[uint32](value)
  for byteIndex in 0 ..< 4:
    output[offset+byteIndex] = uint8((bits shr (8*byteIndex)) and 255'u32)

proc mccat_05_eks*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mccat_05_eks".} =
  if input == nil or inputLength < 2 or inputLength > MaxInput: return -1
  let n64 = input[0]
  let bw64 = input[1]
  if n64 < MinN or n64 > MaxN or bw64 < 2 or bw64 > 5 or bw64 >= n64: return -1
  let n = int(n64)
  let bandwidth = int(bw64)
  if int(inputLength) != 2+n*n: return -1
  var a: array[64, float64]
  for row in 0 ..< n:
    for column in 0 ..< n:
      let value = input[2+row*n+column]
      if value < -1_000_000 or value > 1_000_000: return -1
      if row > column and value != input[2+column*n+row]: return -1
      if abs(row-column) > bandwidth and value != 0: return -1
      a[row*n+column] = float64(value) / InputScale
  let required = n*4
  if output == nil or outputCapacity < required: return -2
  reduceBand(a, n, bandwidth)
  if not qrIterate(a, n): return -1
  var eigenvalues: array[8, float64]
  for i in 0 ..< n: eigenvalues[i] = a[i*n+i]
  for i in 1 ..< n:
    let value = eigenvalues[i]
    var j = i
    while j > 0 and before(value, eigenvalues[j-1]):
      eigenvalues[j] = eigenvalues[j-1]
      dec j
    eigenvalues[j] = value
  var staged: array[32, uint8]
  for i in 0 ..< n: putI32Le(project(eigenvalues[i]), staged, 4*i)
  for i in 0 ..< required: output[i] = staged[i]
  int64(required)
