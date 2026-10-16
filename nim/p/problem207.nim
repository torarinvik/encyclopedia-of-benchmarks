const InvalidResult = -1.0e300
const MinProportion = 1.0e-5
const MaxProportion = 1.0
const MaxPartitions = 5_000_000'i64

proc isPowerOfTwo(value: int64): bool =
  value > 0 and (value and (value - 1)) == 0

proc problem207*(maxProportion: float64): float64 {.cdecl, exportc: "problem207".} =
  if maxProportion != maxProportion or maxProportion < MinProportion or maxProportion > MaxProportion:
    return InvalidResult
  var partitions = 0'i64
  var perfectPartitions = 0'i64
  while partitions < MaxPartitions:
    inc partitions
    let candidate = partitions * (partitions + 1)
    if isPowerOfTwo(partitions + 1): inc perfectPartitions
    if float64(perfectPartitions) / float64(partitions) < maxProportion:
      return float64(candidate)
  InvalidResult
