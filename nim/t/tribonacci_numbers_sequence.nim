## Zero-based Tribonacci sequence with source seeds 1, 1, 1.
proc tribonacci_numbers_sequence*(index: int64): int64 {.cdecl, exportc: "tribonacci_numbers_sequence".} =
  if index < 0 or index > 60: return -1
  if index < 3: return 1

  var first = 1'i64
  var second = 1'i64
  var third = 1'i64
  for _ in 3'i64 .. index:
    let next = first + second + third
    first = second
    second = third
    third = next
  return third
