## Two-pointer maximum area between vertical lines.
proc container_with_most_water*(heights: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "container_with_most_water".} =
  if length > 4096:
    return -1
  var index = csize_t(0)
  while index < length:
    if heights[index] < 0'i64 or heights[index] > 2147483647'i64:
      return -1
    inc index
  if length < 2:
    return 0

  var left = csize_t(0)
  var right = length - 1
  var best = 0'i64
  while left < right:
    let left_height = heights[left]
    let right_height = heights[right]
    let height = min(left_height, right_height)
    let area = height * int64(right - left)
    if area > best:
      best = area
    if left_height <= right_height:
      inc left
    else:
      dec right
  best
