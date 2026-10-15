const MaxInputLength = 4096
const MaxAbsValue = 1_000_000_000'i64
const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc average*(values: I64Input, length: csize_t): float64 {.cdecl, exportc: "average".} =
  if length == 0 or length > MaxInputLength: return InvalidResult
  var sum = 0'i64
  for index in 0 ..< int(length):
    let value = values[index]
    if value < -MaxAbsValue or value > MaxAbsValue: return InvalidResult
    sum += value
  float64(sum) / float64(length)
