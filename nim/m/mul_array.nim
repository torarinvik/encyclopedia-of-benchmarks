const MaxInputLength = 9

proc mul_array*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mul_array".} =
  if length > MaxInputLength.csize_t: return -1
  if length == 0: return 1
  if values.isNil: return -1

  var product = 1'i64
  for index in 0 ..< length.int:
    let value = values[index]
    if value < 0 or value > 99: return -1
    product *= value
  product
