const MaxInputLength = 64
const InvalidResult = low(int64)

proc largest_rectangle_histogram*(heights: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "largest_rectangle_histogram".} =
  if length == 0: return 0
  if heights.isNil or length > MaxInputLength: return InvalidResult
  for i in 0 ..< int(length):
    if heights[i] < 0'i64 or heights[i] > 1_000_000'i64: return InvalidResult

  var stack: array[MaxInputLength, int]
  var top = 0
  var best = 0'i64
  for i in 0 ..< int(length):
    while top > 0 and heights[stack[top - 1]] > heights[i]:
      dec top
      let bar = stack[top]
      let left = if top == 0: 0 else: stack[top - 1] + 1
      best = max(best, heights[bar] * int64(i - left))
    stack[top] = i
    inc top
  while top > 0:
    dec top
    let bar = stack[top]
    let left = if top == 0: 0 else: stack[top - 1] + 1
    best = max(best, heights[bar] * int64(int(length) - left))
  best
