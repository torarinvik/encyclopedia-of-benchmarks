## XOR a consecutive signed 32-bit range using portable zero-extended bit patterns.
const MaxValues = 1024
const InvalidResult = -2147483649'i64

proc encodeI32(value: int64): uint64 =
  if value < 0: uint64(value + 4294967296'i64) else: uint64(value)

proc missing_number_in_range*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "missing_number_in_range".} =
  if values == nil or length < 2 or length > csize_t(MaxValues): return InvalidResult
  var low = values[0]
  var high = low
  for index in 0 ..< int(length):
    let value = values[index]
    if value < -2147483648'i64 or value > 2147483647'i64: return InvalidResult
    if value < low: low = value
    if value > high: high = value
  if high - low != int64(length): return InvalidResult
  var seen: array[MaxValues + 1, bool]
  var actual = 0'u64
  for index in 0 ..< int(length):
    let value = values[index]
    let slot = int(value - low)
    if seen[slot]: return InvalidResult
    seen[slot] = true
    actual = actual xor encodeI32(value)
  var expected = 0'u64
  var value = low
  while value <= high:
    expected = expected xor encodeI32(value)
    inc value
  let result = expected xor actual
  if result <= 2147483647'u64: return int64(result)
  int64(result) - 4294967296'i64
