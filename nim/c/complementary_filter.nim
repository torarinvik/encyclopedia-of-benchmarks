const MaxSamples = 32
const Scale = 1_000_000'i64
const MaxSignalMicro = 1_000_000'i64
const InvalidResult = -1.0e300

proc complementary_filter*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "complementary_filter".} =
  if values == nil or length < 2: return InvalidResult
  let coefficientPpm = values[0]
  let sampleCountValue = values[1]
  if coefficientPpm < 1 or coefficientPpm >= Scale or sampleCountValue < 1 or sampleCountValue > MaxSamples:
    return InvalidResult
  let sampleCount = int(sampleCountValue)
  if length != csize_t(2 + 3 * sampleCount): return InvalidResult
  for sample in 0 ..< sampleCount:
    let rate = values[2 + 3 * sample]
    let reference = values[3 + 3 * sample]
    let elapsed = values[4 + 3 * sample]
    if rate < -MaxSignalMicro or rate > MaxSignalMicro or reference < -MaxSignalMicro or
        reference > MaxSignalMicro or elapsed < 1 or elapsed > Scale: return InvalidResult
  let coefficient = float64(coefficientPpm) / float64(Scale)
  var value = 0.0
  for sample in 0 ..< sampleCount:
    let rate = float64(values[2 + 3 * sample]) / float64(Scale)
    let reference = float64(values[3 + 3 * sample]) / float64(Scale)
    let elapsed = float64(values[4 + 3 * sample]) / float64(Scale)
    if sample == 0: value = reference
    else: value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference
  value
