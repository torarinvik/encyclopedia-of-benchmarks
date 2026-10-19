import std/math

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset+b] = uint8(bits shr (8*b))

proc nbench_neural_network*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "nbench_neural_network".} =
  if input.isNil or length != 1: return -1
  let passes = input[0]
  if passes < 1 or passes > 8: return -1
  if output.isNil or capacity < 88: return -2
  let pattern: array[35,float64] = [0.0,1,1,1,0,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,1,1,1,0]
  let target: array[8,float64] = [0.0,1,0,0,1,1,1,1]
  var mw: array[8,array[35,float64]]; var ow: array[8,array[8,float64]]
  var mc: array[8,array[35,float64]]; var oc: array[8,array[8,float64]]
  var mm: array[8,array[35,float64]]; var om: array[8,array[8,float64]]
  var mout: array[8,float64]; var oout: array[8,float64]
  for n in 0..<8:
    for w in 0..<35: mw[n][w] = float64((n*17+w*7) mod 101 - 50) / 1000.0
  for n in 0..<8:
    for w in 0..<8: ow[n][w] = float64((n*13+w*5) mod 71 - 35) / 1000.0
  for pass in 0..<int(passes):
    for n in 0..<8:
      for w in 0..<35:
        mc[n][w] = mm[n][w]
        mm[n][w] = 0.0
    for n in 0..<8:
      for w in 0..<8:
        oc[n][w] = om[n][w]
        om[n][w] = 0.0
    for forward in 0..<2:
      for n in 0..<8:
        var total = 0.0
        for w in 0..<35: total += mw[n][w] * pattern[w]
        mout[n] = 1.0 / (1.0 + exp(-total))
    for n in 0..<8:
      var total = 0.0
      for w in 0..<8: total += ow[n][w] * mout[w]
      oout[n] = 1.0 / (1.0 + exp(-total))
    var oe, me: array[8,float64]
    for n in 0..<8: oe[n] = target[n] - oout[n]
    for n in 0..<8:
      var total = 0.0
      for i in 0..<8: total += ow[i][n] * oe[i]
      me[n] = mout[n] * (1.0 - mout[n]) * total
    for n in 0..<8:
      for w in 0..<8:
        var delta = 0.09 * oe[n] * mout[w]
        delta += 0.09 * oc[n][w]
        ow[n][w] += delta
        om[n][w] += delta
    for n in 0..<8:
      for w in 0..<35:
        var delta = 0.09 * me[n] * pattern[w]
        delta += 0.09 * mc[n][w]
        mw[n][w] += delta
        mm[n][w] += delta
  var encoded: array[11,int64]; encoded[0] = passes
  for n in 0..<8: encoded[n+1] = int64(oout[n] * 1_000_000.0)
  var ms, os = 0.0
  for n in 0..<8:
    for w in 0..<35: ms += mw[n][w]
  for n in 0..<8:
    for w in 0..<8: os += ow[n][w]
  encoded[9] = int64(ms * 1_000_000.0)
  encoded[10] = int64(os * 1_000_000.0)
  for i in 0..<11: putI64(output, i*8, encoded[i])
  88
