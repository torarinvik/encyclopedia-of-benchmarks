const MaxArrayLength = 256
const MaxInputLength = MaxArrayLength + 1
const Int32Min = -2147483648'i64
const Int32Max = 2147483647'i64

proc how_many_times_rotated*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "how_many_times_rotated".} =
  if length > csize_t(MaxInputLength): return -1
  if length > csize_t(MaxArrayLength): return -1
  if length == 0: return 0
  if input == nil: return -1
  for index in 0 ..< int(length):
    if input[index] < Int32Min or input[index] > Int32Max: return -1

  var low = 0
  var high = int(length)
  if high > 0: dec high
  while low < high:
    let middle = low + (high - low) div 2
    if input[middle] > input[high]: low = middle + 1
    else: high = middle
  int64(low)
