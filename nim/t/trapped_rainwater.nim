proc trappedWaterWithSuffix(heights: ptr UncheckedArray[int64], length: int,
                            suffix: var openArray[uint32]): int64 =
  var boundary = 0'u32
  var index = length
  while index > 0:
    dec index
    let raw = cast[uint64](heights[index])
    if raw > 1_000_000: return -1
    boundary = max(boundary, uint32(raw))
    suffix[index] = boundary

  var water = 0'u32
  boundary = 0
  for index in 0 ..< length:
    let height = uint32(heights[index])
    boundary = max(boundary, height)
    water += min(boundary, suffix[index]) - height
  int64(water)

## Sum trapped water using stored suffix maxima and a running prefix maximum.
proc trapped_rainwater*(heights: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "trapped_rainwater".} =
  if length > 4096 or (length > 0 and heights.isNil): return -1
  if length <= 16:
    var suffix: array[16, uint32]
    return trappedWaterWithSuffix(heights, int(length), suffix)
  var suffix: array[4096, uint32]
  trappedWaterWithSuffix(heights, int(length), suffix)
