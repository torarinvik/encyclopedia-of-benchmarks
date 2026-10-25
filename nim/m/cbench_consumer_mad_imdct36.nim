import std/math

const InputCount = 18
const MaxInputLength = 19
const OutputCount = 36
const Pi = 3.14159265358979323846264338327950288

proc cbench_consumer_mad_imdct36*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cbench_consumer_mad_imdct36".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  for k in 0 ..< int(inputLength):
    let value = input[k]
    if classify(value) in {fcNan, fcInf, fcNegInf} or value < -16.0 or value > 16.0: return -1
  if inputLength != InputCount.csize_t: return -1

  var staged: array[OutputCount, float64]
  for n in 0 ..< OutputCount:
    var sum = 0.0
    for k in 0 ..< InputCount:
      let angle = Pi * float64(2 * n + 19) * float64(2 * k + 1) / 72.0
      sum += input[k] * cos(angle)
    staged[n] = sum
  if output == nil or outputCapacity < OutputCount.csize_t: return -2
  for n in 0 ..< OutputCount: output[n] = staged[n]
  OutputCount.int64
