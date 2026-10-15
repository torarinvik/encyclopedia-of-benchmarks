const MaxN = 64
const MaxAbsValue = 1_000_000'i64
const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc weighted_average*(packed: I64Input, length: csize_t): float64 {.cdecl, exportc: "weighted_average".} =
  if packed == nil or length < 1 or length > 129: return InvalidResult
  let n = packed[0]
  if n < 1 or n > MaxN or length != csize_t(1 + 2 * n): return InvalidResult
  var weightedSum = 0'i64
  var totalWeight = 0'i64
  for index in 0 ..< int(n):
    let value = packed[1 + index]
    let weight = packed[1 + int(n) + index]
    if value < -MaxAbsValue or value > MaxAbsValue or weight < -MaxAbsValue or weight > MaxAbsValue:
      return InvalidResult
    weightedSum += value * weight
    totalWeight += weight
  if totalWeight == 0: return InvalidResult
  float64(weightedSum) / float64(totalWeight)
