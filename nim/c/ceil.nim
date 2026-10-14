const MaxValues = 256
const MaxInputValues = 1 + 2 * MaxValues
const NumeratorLimit = 1_000_000_000_000'i64
const DenominatorLimit = 1_000_000'i64
const ResultOffset = 1_000_000_000_001'i64

proc ceilDivision(numerator, denominator: int64): int64 =
  if numerator >= 0:
    result = numerator div denominator
    if numerator mod denominator != 0: inc result
  else:
    result = -((-numerator) div denominator)

proc ceil_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ceil_benchmark".} =
  if length < 1 or length > MaxInputValues.csize_t: return -1
  let countValue = values[0]
  if countValue < 0 or countValue > MaxValues.int64: return -1
  let count = countValue.int
  if length.int != 1 + 2 * count: return -1
  for i in 0 ..< count:
    let numerator = values[1 + 2 * i]
    let denominator = values[2 + 2 * i]
    if numerator < -NumeratorLimit or numerator > NumeratorLimit or
        denominator < 1 or denominator > DenominatorLimit: return -1
  var checksum = 0'i64
  for i in 0 ..< count:
    let result = ceilDivision(values[1 + 2 * i], values[2 + 2 * i])
    checksum += (i + 1).int64 * (result + ResultOffset)
  checksum
