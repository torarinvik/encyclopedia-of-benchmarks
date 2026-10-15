## Sum trapped water by advancing the side with the smaller current boundary.
const MaxLength = 4096

proc trapped_rainwater_two_pointer*(heights: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "trapped_rainwater_two_pointer".} =
  if length > csize_t(MaxLength) or (length > 0 and heights.isNil): return -1
  let n = int(length)
  for index in 0 ..< n:
    if heights[index] < 0 or heights[index] > 1_000_000: return -1
  if n <= 2: return 0

  var left = 0
  var right = n - 1
  var leftMax = 0'u32
  var rightMax = 0'u32
  var trapped = 0'u32
  while left < right:
    if heights[left] < heights[right]:
      let height = uint32(heights[left])
      if height >= leftMax: leftMax = height
      else: trapped += leftMax - height
      inc left
    else:
      let height = uint32(heights[right])
      if height >= rightMax: rightMax = height
      else: trapped += rightMax - height
      dec right
  int64(trapped)
