## Portable zero-based Tribonacci recurrence for the shared i64 contract.
proc tribonacci*(n: int64): int64 {.cdecl, exportc: "tribonacci".} =
  if n < 0 or n > 73:
    return -1
  if n == 0:
    return 0
  if n <= 2:
    return 1
  var previousThree = 0'i64
  var previousTwo = 1'i64
  var previousOne = 1'i64
  for index in 3'i64 .. n:
    let next = previousThree + previousTwo + previousOne
    previousThree = previousTwo
    previousTwo = previousOne
    previousOne = next
  previousOne
