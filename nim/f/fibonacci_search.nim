## Fibonacci search in an ascending sequence for the shared benchmark contract.
proc fibonacci_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "fibonacci_search".} =
  if length == 0:
    return -1
  var fibMinusTwo = csize_t(0)
  var fibMinusOne = csize_t(1)
  var fib = csize_t(1)
  while fib < length:
    fibMinusTwo = fibMinusOne
    fibMinusOne = fib
    fib = fibMinusTwo + fibMinusOne

  var offsetPlusOne = csize_t(0)
  while fib > 1:
    var index = offsetPlusOne + fibMinusTwo - 1
    if index >= length:
      index = length - 1
    let value = values[index]
    if value == target:
      return int64(index)
    if value < target:
      fib = fibMinusOne
      fibMinusOne = fibMinusTwo
      fibMinusTwo = fib - fibMinusOne
      offsetPlusOne = index + 1
    else:
      fib = fibMinusTwo
      fibMinusOne -= fibMinusTwo
      fibMinusTwo = fib - fibMinusOne

  if fibMinusOne != 0 and offsetPlusOne < length and values[offsetPlusOne] == target:
    return int64(offsetPlusOne)
  return -1
