const MaxIndex = 9999'i64

proc divisors_count_sequence*(index: int64): int64 {.cdecl, exportc: "divisors_count_sequence".} =
  if index < 0 or index > MaxIndex: return -1
  let n = index + 1
  if n == 1: return 1
  var count = 2'i64
  var k = 2'i64
  while k < n:
    if n mod k == 0: count += 1
    k += 1
  return count
