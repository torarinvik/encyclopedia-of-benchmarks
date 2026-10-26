# Clean-room bounded PolyBench QR port. See package LICENSE.txt.
import std/math

const MaxSide = 6

proc polybench_gramschmidt*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "polybench_gramschmidt".} =
  if input.isNil or length != csize_t(2): return -1
  let mv = input[0]
  let nv = input[1]
  if not mv.isFinite or not nv.isFinite or mv != floor(mv) or nv != floor(nv) or
      mv < 1 or mv > float64(MaxSide) or nv < 1 or nv > float64(MaxSide) or nv > mv: return -1
  let m = int(mv)
  let n = int(nv)
  let qCells = m*n
  let rCells = n*n
  let total = qCells+rCells
  if output.isNil or capacity < csize_t(total): return -2
  var a: array[36,float64]
  var q: array[36,float64]
  var r: array[36,float64]
  var staged: array[72,float64]
  for i in 0 ..< m:
    for j in 0 ..< n:
      a[i*n+j] = (float64((i*j) mod m) / float64(m))*100.0 + 10.0
  for k in 0 ..< n:
    var normSquared = 0.0
    for i in 0 ..< m: normSquared += a[i*n+k]*a[i*n+k]
    r[k*n+k] = sqrt(normSquared)
    for i in 0 ..< m: q[i*n+k] = a[i*n+k]/r[k*n+k]
    for j in (k+1) ..< n:
      r[k*n+j] = 0.0
      for i in 0 ..< m: r[k*n+j] += q[i*n+k]*a[i*n+j]
      for i in 0 ..< m: a[i*n+j] = a[i*n+j]-q[i*n+k]*r[k*n+j]
  for x in 0 ..< rCells: staged[x] = r[x]
  for x in 0 ..< qCells: staged[rCells+x] = q[x]
  for x in 0 ..< total: output[x] = staged[x]
  int64(total)
