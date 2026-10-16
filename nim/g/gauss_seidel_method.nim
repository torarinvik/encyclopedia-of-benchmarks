import std/math

const MaxN = 8
const MaxEntry = 1_000_000_000'i64
const Tolerance = 1.0e-10

proc putF64(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset+byte] = uint8((bits shr (byte*8)) and 0xff'u64)

proc gauss_seidel_method*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "gauss_seidel_method".} =
  if values.isNil or length < 1 or values[0] < 1 or values[0] > MaxN: return -1
  let n = int(values[0])
  if length != csize_t(1+n*n+n): return -1
  let rhs = 1+n*n
  for k in 1 ..< int(length):
    if values[k] < -MaxEntry or values[k] > MaxEntry: return -1
  for i in 0 ..< n:
    let diagonal = values[1+i*n+i]
    if diagonal <= 0: return -1
    var offSum = 0'i64
    for j in 0 ..< n:
      if values[1+i*n+j] != values[1+j*n+i]: return -1
      if i != j: offSum += abs(values[1+i*n+j])
    if diagonal <= offSum: return -1
  let outputBytes = n*8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  var a: array[MaxN*MaxN, float64]
  var b, x, old: array[MaxN, float64]
  for i in 0 ..< n*n: a[i] = float64(values[i+1])/1_000_000.0
  for i in 0 ..< n: b[i] = float64(values[rhs+i])/1_000_000.0
  for iteration in 0 ..< 1000:
    for i in 0 ..< n: old[i] = x[i]
    for i in 0 ..< n:
      var before = 0.0
      var after = 0.0
      for j in 0 ..< i: before += a[i*n+j]*x[j]
      for j in i+1 ..< n: after += a[i*n+j]*old[j]
      x[i] = (b[i]-before-after)/a[i*n+i]
    var done = true
    for i in 0 ..< n:
      if abs(x[i]-old[i]) >= Tolerance: done = false
    if done: break
  for i in 0 ..< n: putF64(output, i*8, round(x[i]*1.0e10)/1.0e10)
  int64(outputBytes)
