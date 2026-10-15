proc check_polygon*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "check_polygon".} =
  discard output
  discard outputCapacity
  if values == nil or length < 3 or length > 256: return -1
  var total = 0'i64
  var maximum = 0'i64
  for index in 0 ..< int(length):
    let side = values[index]
    if side < 1 or side > 1_000_000_000: return -1
    total += side
    if side > maximum: maximum = side
  if maximum < total - maximum: 1 else: 0
