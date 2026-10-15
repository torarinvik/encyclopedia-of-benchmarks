proc polygonal_numbers*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "polygonal_numbers".} =
  if length != 2:
    return -1
  let num = packed[0]
  let sides = packed[1]
  if num < 0 or num > 100000000 or sides < 3 or sides > 64:
    return -1
  let square = num * num
  let leading = (sides - 2) * square
  let trailing = (sides - 4) * num
  (leading - trailing) div 2
