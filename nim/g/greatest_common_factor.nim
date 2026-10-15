const MaxItems = 256
const MaxSafeInteger = 9_007_199_254_740_991'i64
const InvalidResult = low(int64)

proc gcdNonnegative(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

proc greatest_common_factor*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "greatest_common_factor".} =
  if values == nil or length < 2 or length > csize_t(MaxItems + 1): return InvalidResult
  let count = values[0]
  if count < 1 or count > MaxItems or length != csize_t(count + 1): return InvalidResult
  var result = values[1]
  if result < 0 or result > MaxSafeInteger: return InvalidResult
  for index in 2 ..< int(length):
    let value = values[index]
    if value < 0 or value > MaxSafeInteger: return InvalidResult
    result = gcdNonnegative(result, value)
  return result
