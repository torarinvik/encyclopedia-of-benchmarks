proc finding_number_of_digits_in_a_number*(value: int64): int64 {.cdecl, exportc: "finding_number_of_digits_in_a_number".} =
  if value < 0: return -1
  var remaining = uint64(value)
  var count = 0'i64
  while remaining != 0'u64:
    remaining = remaining div 10'u64
    inc count
  count
