## Least cyclic rotation by two-candidate elimination.
proc minimum_string_representation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_string_representation".} =
  if length > 4096: return -1
  if length == 0: return 0
  if values.isNil: return -1
  for index in 0 ..< length:
    if values[index] < 0 or values[index] > 127: return -1

  var left: csize_t = 0
  var right: csize_t = 1
  var matched: csize_t = 0
  while left < length and right < length and matched < length:
    let a = values[(left + matched) mod length]
    let b = values[(right + matched) mod length]
    if a == b:
      matched += 1
      continue
    if a > b:
      left += matched + 1
      if left == right: left += 1
    else:
      right += matched + 1
      if left == right: right += 1
    matched = 0
  int64(min(left, right))
