import std/math

const InputCount = 18
const MaxInputLength = 19
const OutputCount = 18
const Pi = 3.14159265358979323846264338327950288

proc mibench_lame_mdct_long*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mibench_lame_mdct_long".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  for k in 0 ..< int(inputLength):
    let value = input[k]
    if classify(value) in {fcNan, fcInf, fcNegInf} or value < -16.0 or value > 16.0: return -1
  if inputLength != InputCount.csize_t: return -1

  var staged: array[OutputCount, float64]
  for m in 0 ..< OutputCount:
    var sum = 0.0
    for k in 0 ..< InputCount:
      let offset = if k < 9: 38 else: 74
      let angle = Pi * float64(2 * m + 1) * float64(4 * k + offset) / 144.0
      sum += input[k] * cos(angle)
    staged[m] = (4.0 / 36.0) * sum
  if output == nil or outputCapacity < OutputCount.csize_t: return -2
  for m in 0 ..< OutputCount: output[m] = staged[m]
  OutputCount.int64
