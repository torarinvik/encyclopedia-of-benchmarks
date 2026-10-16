## Backward recursive linear search over a bounded integer array.
proc searchFromEnd(values: ptr UncheckedArray[int64], offset, count: csize_t,
                   target: int64): int64 =
  if count == 0: return -1
  if values[offset + count - 1] == target: return int64(count - 1)
  searchFromEnd(values, offset, count - 1, target)

proc recursive_linear_search*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "recursive_linear_search".} =
  if values == nil or length < 2 or length > 67: return -1
  let countValue = values[0]
  let target = values[1]
  if countValue < 1 or countValue > 64: return -1
  let count = csize_t(countValue)
  if length != count + 2: return -1
  searchFromEnd(values, 2, count, target)
