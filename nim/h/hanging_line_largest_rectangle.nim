type
  HeightInput = ptr UncheckedArray[int64]

const
  MaxLength = 64
  MaxHeight = 1_000_000'i64
  InvalidResult = low(int64)

proc hanging_line_largest_rectangle*(heights: HeightInput, length: csize_t): int64
    {.cdecl, exportc: "hanging_line_largest_rectangle".} =
  if length == 0: return 0
  if heights.isNil or length > MaxLength: return InvalidResult
  for i in 0 ..< int(length):
    if heights[i] < 0'i64 or heights[i] > MaxHeight: return InvalidResult

  var left: array[MaxLength, int]
  var right: array[MaxLength, int]
  for i in 0 ..< int(length):
    left[i] = i
    while left[i] > 0 and heights[i] <= heights[left[i] - 1]:
      left[i] = left[left[i] - 1]
  for i in countdown(int(length) - 1, 0):
    right[i] = i
    while right[i] + 1 < int(length) and heights[i] <= heights[right[i] + 1]:
      right[i] = right[right[i] + 1]

  var best = 0'i64
  for i in 0 ..< int(length):
    let width = int64(right[i] - left[i] + 1)
    best = max(best, heights[i] * width)
  best
