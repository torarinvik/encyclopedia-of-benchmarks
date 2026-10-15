proc perimeter*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "perimeter".} =
  if values.isNil or length != 2: return -1
  let sides = values[0]
  let sideLength = values[1]
  if sides < 3 or sides > 256 or sideLength < 1 or sideLength > 255: return -1
  sides * sideLength
