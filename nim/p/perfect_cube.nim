## Test whether a signed value is an exact integer cube.
proc perfect_cube*(value: int64): int64 {.cdecl, exportc: "perfect_cube".} =
  if value < -1_000_000_000_000'i64 or value > 1_000_000_000_000'i64: return -1
  let target = if value < 0: -value else: value
  var low = 0'i64
  var high = 10_000'i64
  while low <= high:
    let middle = low + (high - low) div 2
    let cube = middle * middle * middle
    if cube == target: return 1
    if cube < target: low = middle + 1
    else: high = middle - 1
  0
