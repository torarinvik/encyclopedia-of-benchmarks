proc set_kth_bit*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "set_kth_bit".} =
  if input.isNil or length != 2: return -1
  let number = input[0]
  let bit = input[1]
  if number < 0 or number > 2147483647 or bit < 0 or bit > 30: return -1
  number or (1'i64 shl bit)
