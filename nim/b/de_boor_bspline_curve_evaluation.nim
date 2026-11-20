import std/math

const MaxInputLength = 24

proc exactInteger(x: float64, low, high: int64): bool =
  classify(x) notin {fcNan, fcInf, fcNegInf} and x >= float64(low) and x <= float64(high) and float64(int64(x)) == x

proc evaluate(p, n: int, u: float64, knots, controls: ptr UncheckedArray[float64]): float64 =
  var span = p
  if u == knots[n]: span = n-1
  else:
    while span < n-1 and u >= knots[span+1]: inc span
  var local: array[4, float64]
  for j in 0..p: local[j] = controls[span-p+j]
  for level in 1..p:
    for slot in countdown(p,level):
      let left = span-p+slot
      let right = span+slot-level+1
      let denominator = knots[right]-knots[left]
      let alpha = if denominator == 0.0: 0.0 else: (u-knots[left])/denominator
      local[slot] = (1.0-alpha)*local[slot-1]+alpha*local[slot]
  local[p]

proc de_boor_bspline_curve_evaluation*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or inputLength < 3 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0],1,3): return -1
  let p = int(input[0])
  if not exactInteger(input[1],int64(p+1),8) or classify(input[2]) in {fcNan,fcInf,fcNegInf}: return -1
  let n = int(input[1])
  let knotCount = n+p+1
  if inputLength != (3+knotCount+n).csize_t: return -1
  let knots = cast[ptr UncheckedArray[float64]](addr input[3])
  let controls = cast[ptr UncheckedArray[float64]](addr input[3+knotCount])
  var run = 1
  for i in 0..<knotCount:
    if classify(knots[i]) in {fcNan,fcInf,fcNegInf} or knots[i] < -1000.0 or knots[i] > 1000.0: return -1
    if i > 0:
      if knots[i] < knots[i-1]: return -1
      run = (if knots[i] == knots[i-1]: run+1 else: 1)
      if run > p+1: return -1
  for i in 0..<n:
    let value = controls[i]
    if classify(value) in {fcNan,fcInf,fcNegInf} or value < -1000.0 or value > 1000.0: return -1
  if not (knots[p] < knots[n] and input[2] >= knots[p] and input[2] <= knots[n]): return -1
  if output == nil or outputCapacity < 1: return -2
  let result = evaluate(p,n,input[2],knots,controls)
  if classify(result) in {fcNan,fcInf,fcNegInf}: return -1
  output[0] = result
  1
