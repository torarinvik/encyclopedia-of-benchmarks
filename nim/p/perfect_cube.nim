## Test whether a signed value is an exact integer cube.
proc perfect_cube*(value: int64): int64 {.cdecl, exportc: "perfect_cube".} =
  if value < -1_000_000_000_000'i64 or value > 1_000_000_000_000'i64: return -1
  let target = uint64(if value < 0: -value else: value)
  if target < 2: return 1
  let root_limit =
    if target <= 1000: 10'u64
    elif target <= 1000000: 100'u64
    elif target <= 1000000000: 1000'u64
    else: 10000'u64
  var low = 1'u64
  var high = min(target div 2, root_limit)
  while low <= high:
    let middle = (low + high) shr 1
    let cube = middle * middle * middle
    if cube == target: return 1
    if cube < target:
      if middle == high: return 0
      low = middle + 1
    else:
      if middle == low: return 0
      high = middle - 1
  0
