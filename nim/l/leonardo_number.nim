## Iteratively compute the Leonardo recurrence.
proc leonardo_number*(input: int64): int64 {.cdecl, exportc: "leonardo_number".} =
  if input < 0 or input > 89: return -1
  var previous = 1'i64
  var current = 1'i64
  var index = 2'i64
  while index <= input:
    let next = current + previous + 1
    previous = current
    current = next
    inc index
  current
