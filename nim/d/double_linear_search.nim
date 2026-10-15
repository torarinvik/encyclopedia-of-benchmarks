const MaxItems = 100000'i64
const MaxSafeInteger = 9007199254740991'i64

## Two-ended linear search with source-compatible endpoint priority.
proc double_linear_search*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "double_linear_search".} =
  if values == nil or length < 2 or length > 100002: return -1
  let target = values[0]
  let countValue = values[1]
  if target < -MaxSafeInteger or target > MaxSafeInteger or countValue < 0 or countValue > MaxItems: return -1
  let count = csize_t(countValue)
  if length != count + 2: return -1
  var index = csize_t(0)
  while index < count:
    if values[index + 2] < -MaxSafeInteger or values[index + 2] > MaxSafeInteger: return -1
    inc index
  var start = csize_t(0)
  var right = count
  while start < right:
    if values[start + 2] == target: return int64(start)
    if values[right + 1] == target: return int64(right - 1)
    inc start
    dec right
  return -1
