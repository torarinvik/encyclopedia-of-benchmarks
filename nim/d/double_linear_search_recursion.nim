## Search from both ends inward in the pinned source's left-then-right order.
const MaxItems = 1024
const InvalidResult = -2'i64

proc searchRange(values: ptr UncheckedArray[int64], key: int64, left, right: int64, offset: int): int64 =
  if left > right: return -1
  if values[offset + int(left)] == key: return left
  if values[offset + int(right)] == key: return right
  searchRange(values, key, left + 1, right - 1, offset)

proc double_linear_search_recursion*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "double_linear_search_recursion".} =
  if values.isNil or length < 2 or length > MaxItems + 2: return InvalidResult
  let count = values[0]
  let key = values[1]
  if count < 0 or count > MaxItems or key < low(int32).int64 or key > high(int32).int64 or
      length != csize_t(2 + count): return InvalidResult
  for index in 0 ..< int(count):
    let value = values[2 + index]
    if value < low(int32).int64 or value > high(int32).int64: return InvalidResult
  searchRange(values, key, 0, count - 1, 2)
