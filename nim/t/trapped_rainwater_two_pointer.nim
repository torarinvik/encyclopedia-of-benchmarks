## Process the smaller endpoint, validating each bar as it enters the window.
proc trapped_rainwater_two_pointer*(heights: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "trapped_rainwater_two_pointer".} =
  if length > 4096 or (length > 0 and heights.isNil): return -1
  if length == 0: return 0

  var left = 0
  var right = int(length) - 1
  var leftHeight = cast[uint64](heights[left])
  var rightHeight = cast[uint64](heights[right])
  if leftHeight > 1_000_000 or rightHeight > 1_000_000: return -1

  var leftMax, rightMax, trapped: uint32
  while left < right:
    if leftHeight < rightHeight:
      let height = uint32(leftHeight)
      leftMax = max(leftMax, height)
      trapped += leftMax - height
      inc left
      leftHeight = cast[uint64](heights[left])
      if leftHeight > 1_000_000: return -1
    else:
      let height = uint32(rightHeight)
      rightMax = max(rightMax, height)
      trapped += rightMax - height
      dec right
      rightHeight = cast[uint64](heights[right])
      if rightHeight > 1_000_000: return -1
  int64(trapped)
