const MaxLength = 64
const Unreachable = 1_000_000_000_000'i64

proc min_number_of_jumps*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "min_number_of_jumps".} =
  if values.isNil or length < 1 or length > MaxLength: return -1
  let count = int(length)
  for i in 0 ..< count:
    if values[i] < 0 or values[i] > MaxLength: return -1
  var jumps: array[MaxLength, int64]
  for i in 0 ..< MaxLength: jumps[i] = Unreachable
  jumps[0] = 0
  for i in 1 ..< count:
    for j in 0 ..< i:
      if values[j] + int64(j) >= int64(i) and jumps[j] + 1 < jumps[i]:
        jumps[i] = jumps[j] + 1
  jumps[count - 1]
