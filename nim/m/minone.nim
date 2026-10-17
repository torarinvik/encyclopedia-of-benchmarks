const MaxLength = 64
const MinValue = -1_000_000'i64
const MaxValue = 1_000_000'i64

proc minone*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minone".} =
  if input == nil or length < 1 or length > csize_t(MaxLength): return -1
  var total = 0'i64
  for index in 0 ..< int(length):
    let value = input[index]
    if value < MinValue or value > MaxValue: return -1
    total += value * value
  total
