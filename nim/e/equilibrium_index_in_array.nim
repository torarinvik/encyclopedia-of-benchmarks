const MaxLength = 1024'i64
const MinI32 = -2147483648'i64
const MaxI32 = 2147483647'i64

proc equilibrium_index_in_array*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "equilibrium_index_in_array".} =
  if values == nil or length < 1 or length > csize_t(MaxLength + 1): return -2
  let n = values[0]
  if n < 0 or n > MaxLength or length != csize_t(n + 1): return -2
  var total = 0'i64
  for i in 1 ..< int(length):
    if values[i] < MinI32 or values[i] > MaxI32: return -2
    total += values[i]
  var left = 0'i64
  for i in 0 ..< int(n):
    let value = values[i + 1]
    total -= value
    if left == total: return int64(i)
    left += value
  -1
