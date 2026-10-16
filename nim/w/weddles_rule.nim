const MaxPanels = 64'i64
const MaxStepNanounits = 1_000_000_000'i64
const MaxSampleMicro = 1_000_000'i64
const InvalidResult = -1.0e300

proc weddles_rule*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "weddles_rule".} =
  if values == nil or length < 9 or length > 387: return InvalidResult
  let panels = values[0]
  let stepNanounits = values[1]
  if panels < 1 or panels > MaxPanels or length != csize_t(6 * panels + 3) or
      stepNanounits < -MaxStepNanounits or stepNanounits > MaxStepNanounits:
    return InvalidResult

  let sampleCount = 6 * panels + 1
  var weightedSum = 0.0
  var index = 1'i64
  while index + 1 < sampleCount:
    let sampleMicro = values[index + 2]
    if sampleMicro < -MaxSampleMicro or sampleMicro > MaxSampleMicro: return InvalidResult
    var weight: int64
    if index mod 2 == 0 and index mod 3 != 0: weight = 1
    elif index mod 2 != 0 and index mod 3 != 0: weight = 5
    elif index mod 6 == 0: weight = 2
    else: weight = 6
    weightedSum += float64(weight) * (float64(sampleMicro) / 1_000_000.0)
    inc index

  let firstMicro = values[2]
  let lastMicro = values[sampleCount + 1]
  if firstMicro < -MaxSampleMicro or firstMicro > MaxSampleMicro or
      lastMicro < -MaxSampleMicro or lastMicro > MaxSampleMicro:
    return InvalidResult
  let stepSize = float64(stepNanounits) / 1_000_000_000.0
  0.3 * stepSize * (weightedSum + float64(firstMicro) / 1_000_000.0 +
                    float64(lastMicro) / 1_000_000.0)
