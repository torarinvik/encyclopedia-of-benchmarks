proc select_bits*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "select_bits".} =
  if values.isNil or length < 1 or length > 3: return -1

  let number = values[0]
  if number < 0 or number > 9007199254740991'i64: return -1

  let first = if length >= 2: values[1] else: 1'i64
  let last = if length >= 3: values[2] else: 53'i64
  if first < 1 or first > 53 or last < 1 or last > 53: return -1

  let modulus = 1'i64 shl int(last)
  ((number mod modulus) shr int(first - 1))
