## Inclusive Fibonacci range sum for the shared unsigned pair ABI.
proc fibonacci_sum*(start, end_value: uint64): int64 {.cdecl, exportc: "fibonacci_sum".} =
  if end_value > 90 or start > end_value:
    return -1
  var previous = 0'i64
  var current = 1'i64
  var lower = 0'i64
  var lower_current = 1'i64
  let lower_index = start + 1
  let upper_index = end_value + 2
  for i in 1'u64 ..< upper_index:
    let next = previous + current
    previous = current
    current = next
    if i < lower_index:
      let lower_next = lower + lower_current
      lower = lower_current
      lower_current = lower_next
  current - lower_current
