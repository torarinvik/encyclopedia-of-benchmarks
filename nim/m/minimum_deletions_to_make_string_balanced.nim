## Minimum deletions to leave all a values before all b values.
proc minimum_deletions_to_make_string_balanced*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_deletions_to_make_string_balanced".} =
  if length > 256 or (length > 0 and values.isNil): return -1
  var aState = 0'i64
  var bState = 0'i64
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 0 or value > 1: return -1
    let nextA = aState + (if value == 1: 1'i64 else: 0'i64)
    let bWithA = bState + (if value == 0: 1'i64 else: 0'i64)
    let nextB = min(aState, bWithA)
    aState = nextA
    bState = nextB
  min(aState, bState)
