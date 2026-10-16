## Selected entry in the Haskell complementary-filter scan trace.
const MaxSamples = 32
const Scale = 1_000_000'i64
const MaxSignalMicro = 1_000_000'i64
const InvalidResult = -1.0e300

proc comp_filt*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "comp_filt".} =
  if values == nil or length < 6 or length > 68: return InvalidResult
  let alphaPpm = values[0]
  let deltaTMicro = values[1]
  let countValue = values[2]
  let outputIndexValue = values[3]
  if alphaPpm < 0 or alphaPpm > Scale or deltaTMicro < 0 or deltaTMicro > Scale or
      countValue < 1 or countValue > MaxSamples or outputIndexValue < 0 or outputIndexValue > countValue:
    return InvalidResult
  let count = int(countValue)
  let outputIndex = int(outputIndexValue)
  if length != csize_t(4 + 2 * count): return InvalidResult
  for i in 0 ..< count:
    let rate = values[4 + i]
    let reference = values[4 + count + i]
    if rate < -MaxSignalMicro or rate > MaxSignalMicro or
        reference < -MaxSignalMicro or reference > MaxSignalMicro: return InvalidResult
  let alpha = float64(alphaPpm) / float64(Scale)
  let deltaT = float64(deltaTMicro) / float64(Scale)
  var theta = float64(values[4 + count]) / float64(Scale)
  for i in 0 ..< outputIndex:
    let rate = float64(values[4 + i]) / float64(Scale)
    let reference = float64(values[4 + count + i]) / float64(Scale)
    theta = alpha * (theta + rate * deltaT) + (1.0 - alpha) * reference
  theta
