import std/math

const Critical: array[9,float64] = [0.0,0.0,0.0,1.1543048513440384,1.48125,1.715037312343363,1.887145117783933,2.0199685076795957,2.126645087195462]
proc generalized_esd*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "generalized_esd".} =
  if values == nil or length < 5: return -1
  let n64 = values[0]
  let limit64 = values[1]
  if n64 < 3 or n64 > 8 or limit64 < 1 or limit64 > 3 or limit64 > n64-2 or length != csize_t(n64+2): return -1
  let n = int(n64)
  let limit = int(limit64)
  var x: array[8,float64]
  var idx: array[8,int]
  for i in 0..<n:
    let v = values[i+2]
    if v < -10000 or v > 10000: return -1
    x[i] = float64(v)
    idx[i] = i
  var remaining = n
  var accepted = 0
  var removed: array[3,int]
  for step in 1..limit:
    var mean = 0.0
    for i in 0..<remaining: mean += x[i]
    mean /= float64(remaining)
    var ss = 0.0
    for i in 0..<remaining:
      let d = x[i] - mean
      ss += d*d
    let sd = sqrt(ss/float64(remaining-1))
    if sd == 0.0: break
    var worst = 0
    var largest = -1.0
    for i in 0..<remaining:
      let d = abs(x[i]-mean)
      if d > largest:
        largest = d
        worst = i
    removed[step-1] = idx[worst]
    if largest/sd > Critical[remaining]: accepted = step
    dec remaining
    x[worst] = x[remaining]
    idx[worst] = idx[remaining]
  var mask = 0'i64
  for i in 0..<accepted: mask = mask or (1'i64 shl removed[i])
  return mask
