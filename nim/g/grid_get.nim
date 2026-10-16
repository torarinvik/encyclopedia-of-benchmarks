proc grid_get*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "grid_get".} =
  if values == nil or length < 3 or length > 4: return -1
  let operation=values[0]; let columns=values[1]; let index=values[2]
  if (operation != 0 and operation != 1) or columns < 1 or columns > 1000 or index < 0 or index > 10000: return -1
  if operation == 0:
    var remaining = index
    while remaining + 1 > columns: remaining -= columns
    return remaining + 1
  index div columns + 1
