const InvalidResult = -1.0e300
type I64Input = ptr UncheckedArray[int64]

proc yin*(input: I64Input, length: csize_t): float64 {.cdecl, exportc: "yin".} =
  if input == nil or length < 7 or length > 261: return InvalidResult
  let countValue = input[0]
  let rate = input[1]
  let minHz = input[2]
  let maxHz = input[3]
  let threshold = input[4]
  if countValue < 2 or countValue > 256 or length != csize_t(5 + countValue) or
      rate < 1 or rate > 192000 or minHz < 1 or maxHz <= minHz or maxHz > rate div 2 or
      threshold < 1 or threshold > 999999: return InvalidResult
  let count = int(countValue)
  for i in 0 ..< count:
    if input[5 + i] < -32768 or input[5 + i] > 32767: return InvalidResult
  let minLagValue = rate div maxHz
  let maxLagValue = rate div minHz
  if minLagValue < 1 or minLagValue > maxLagValue or maxLagValue > min(64, int64(count - 1)):
    return InvalidResult
  let minLag = int(minLagValue)
  let maxLag = int(maxLagValue)
  var cmndf: array[65, float64]
  for i in 0 .. 64: cmndf[i] = 1.0
  var running = 0.0
  for lag in 1 .. maxLag:
    var sum = 0.0
    for i in 0 ..< count - lag:
      let delta = float64(input[5 + i]) - float64(input[5 + i + lag])
      sum += delta * delta
    running += sum
    cmndf[lag] = sum * float64(lag) / (if running == 0.0: 1.0e-10 else: running)
  let thresholdFloat = float64(threshold) / 1_000_000.0
  var lag = minLag
  while lag <= maxLag and not (cmndf[lag] < thresholdFloat): inc lag
  if lag > maxLag: return InvalidResult
  while lag < maxLag and cmndf[lag + 1] < cmndf[lag]: inc lag
  let left = if lag > 1: lag - 1 else: lag
  let right = min(maxLag, lag + 1)
  let denominator = cmndf[left] - 2.0 * cmndf[lag] + cmndf[right]
  let offset = if denominator == 0.0: 0.0 else: (cmndf[left] - cmndf[right]) / (2.0 * denominator)
  let refined = float64(lag) + offset
  if not (refined > 0.0): return InvalidResult
  float64(rate) / refined
