## Sum trapped water using per-position prefix and suffix maxima.
proc trapped_rainwater*(heights: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "trapped_rainwater".} =
  if length > 4096 or (length > 0 and heights.isNil): return -1
  for index in 0 ..< int(length):
    if heights[index] < 0 or heights[index] > 1_000_000: return -1
  if length < 3: return 0

  var leftMax, rightMax: array[4096, int64]
  leftMax[0] = heights[0]
  for index in 1 ..< int(length):
    leftMax[index] = max(leftMax[index - 1], heights[index])
  let last = int(length) - 1
  rightMax[last] = heights[last]
  var index = last
  while index > 0:
    dec index
    rightMax[index] = max(rightMax[index + 1], heights[index])

  var water = 0'i64
  for index in 0 ..< int(length):
    water += min(leftMax[index], rightMax[index]) - heights[index]
  water
