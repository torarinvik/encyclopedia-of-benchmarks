import std/math

const MaxClasses = 4
const MaxSamples = 16
const MaxInput = 22
const MinMargin = 1e-8

proc exactInteger(value: float64, minimum, maximum: int): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf} or value < float64(minimum) or value > float64(maximum): return false
  float64(int(value)) == value

proc linear_discriminant_analysis*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "linear_discriminant_analysis".} =
  if input == nil or inputLength == 0 or inputLength > csize_t(MaxInput): return -1
  if not exactInteger(input[0], 2, MaxClasses): return -1
  let classCount = int(input[0])
  if inputLength < csize_t(1 + classCount): return -1
  var counts: array[MaxClasses, int]
  var totalCount = 0
  for k in 0 ..< classCount:
    if not exactInteger(input[1 + k], 2, 6): return -1
    counts[k] = int(input[1 + k])
    totalCount += counts[k]
  if totalCount > MaxSamples or inputLength != csize_t(1 + classCount + totalCount): return -1

  var groups: array[MaxClasses, array[6, float64]]
  var means: array[MaxClasses, float64]
  var offset = 1 + classCount
  for k in 0 ..< classCount:
    var sum = 0.0
    for j in 0 ..< counts[k]:
      let x = input[offset]
      inc offset
      if not exactInteger(x, -32, 32): return -1
      groups[k][j] = x
      sum += x
    means[k] = sum / float64(counts[k])
    if not exactInteger(means[k], -32, 32): return -1

  var squaredSum = 0.0
  for k in 0 ..< classCount:
    for j in 0 ..< counts[k]:
      let delta = groups[k][j] - means[k]
      squaredSum += delta * delta
  let variance = (1.0 / float64(totalCount - classCount)) * squaredSum
  if classify(variance) in {fcNan, fcInf, fcNegInf} or variance <= 0.0: return -1
  var priors: array[MaxClasses, float64]
  for k in 0 ..< classCount: priors[k] = float64(counts[k]) / float64(totalCount)

  var staged: array[MaxSamples, float64]
  var n = 0
  for group in 0 ..< classCount:
    for j in 0 ..< counts[group]:
      let x = groups[group][j]
      var best = -Inf
      var second = -Inf
      var winner = 0
      for k in 0 ..< classCount:
        let score = x * (means[k] / variance) - (means[k] * means[k] / (2.0 * variance)) + ln(priors[k])
        if score > best:
          second = best
          best = score
          winner = k
        elif score > second:
          second = score
      if classify(best) notin {fcNormal, fcSubnormal, fcZero} or best - second < MinMargin: return -1
      staged[n] = float64(winner)
      inc n
  if output == nil or capacity < csize_t(n): return -2
  for i in 0 ..< n: output[i] = staged[i]
  int64(n)
