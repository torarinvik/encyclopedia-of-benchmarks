proc k_folds*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "k_folds".} =
  if values == nil or length != 2:
    return -1
  let sampleCount = values[0]
  let foldCount = values[1]
  if sampleCount < 1 or sampleCount > 12 or foldCount < 1 or foldCount > 12:
    return -1
  let width = (sampleCount + foldCount - 1) div foldCount
  var packed = uint64(sampleCount) shl 48
  for index in 0 ..< int(sampleCount):
    let fold = uint64(index + int(width)) div uint64(width)
    packed = packed or (fold shl (4 * index))
  int64(packed)
