const Scale = 1_000_000'i64
const MinProbabilityMicro = 1'i64
const MaxProbabilityMicro = 999_999'i64
const MinRatioMicro = 1_000'i64
const MaxRatioMicro = 100_000_000'i64
const MaxInputLength = 3
const InvalidResult = -1.0e300

proc kelly_criterion*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "kelly_criterion".} =
  if values == nil or length != 2 or length > csize_t(MaxInputLength): return InvalidResult
  let probabilityMicro = values[0]
  let ratioMicro = values[1]
  if probabilityMicro < MinProbabilityMicro or probabilityMicro > MaxProbabilityMicro or ratioMicro < MinRatioMicro or ratioMicro > MaxRatioMicro: return InvalidResult
  let winProbability = float64(probabilityMicro) / float64(Scale)
  let winLossRatio = float64(ratioMicro) / float64(Scale)
  let lossProbability = 1.0 - winProbability
  (winProbability * winLossRatio - lossProbability) / winLossRatio
