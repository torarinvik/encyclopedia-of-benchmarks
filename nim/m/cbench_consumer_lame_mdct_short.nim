import std/math

const Pi = 3.14159265358979323846264338327950288
const EnwindowMax = 0.030526638

proc cbench_consumer_lame_mdct_short*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cbench_consumer_lame_mdct_short".} =
  if input == nil or inputLength < 1 or inputLength > 19: return -1
  for k in 0 ..< int(inputLength):
    if classify(input[k]) in {fcNan, fcInf, fcNegInf} or input[k] < -32768.0 or input[k] > 32768.0: return -1
  if inputLength != 18: return -1

  var coefficients: array[36, float64]
  let scale = 4.0 / 12.0
  for i in 0 ..< 3:
    let w2 = cos(Pi / 12.0 * (float64(i) + 0.5)) * EnwindowMax / 32768.0 * scale
    for m in 0 ..< 6:
      coefficients[6 * m + i] = w2 * cos((Pi / 48.0) * float64(2 * m + 1) * float64(4 * i + 14))
      coefficients[6 * m + i + 3] = w2 * cos((Pi / 48.0) * float64(2 * m + 1) * float64(4 * i + 38))
  var staged: array[18, float64]
  for m in countdown(5, 0):
    for l in countdown(2, 0):
      let base = 6 * l
      var total = coefficients[6 * m] * input[base]
      for i in 1 ..< 6: total += coefficients[6 * m + i] * input[base + i]
      staged[3 * m + l] = total
  if output == nil or outputCapacity < 18: return -2
  for i in 0 ..< 18: output[i] = staged[i]
  18
