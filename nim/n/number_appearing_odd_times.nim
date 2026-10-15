const MaxLength = 4096
const InvalidResult = -2_147_483_649'i64
const Int32MinValue = -2_147_483_648'i64
const Int32MaxValue = 2_147_483_647'i64

## XOR-fold an int32 array to find its unique odd-frequency value.
proc number_appearing_odd_times*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_appearing_odd_times".} =
  if length == 0 or length > csize_t(MaxLength) or values == nil: return InvalidResult
  var accumulated = 0'i32
  for index in 0 ..< int(length):
    let value = values[index]
    if value < Int32MinValue or value > Int32MaxValue: return InvalidResult
    accumulated = accumulated xor int32(value)
  int64(accumulated)
