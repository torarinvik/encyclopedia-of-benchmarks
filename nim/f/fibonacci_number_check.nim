## Check the Fibonacci square identity without overflowing signed 64-bit values.
proc square_i64(value: int64): bool =
  if value < 0: return false
  var low = 0'i64
  var high = 3_037_000_499'i64
  while low <= high:
    let middle = low + (high - low) div 2
    let square = middle * middle
    if square == value: return true
    if square < value: low = middle + 1
    else: high = middle - 1
  false

proc fibonacci_number_check*(number: int64): int64 {.cdecl, exportc: "fibonacci_number_check".} =
  if number < -1_300_000_000 or number > 1_300_000_000: return -1
  let value = 5 * number * number
  if square_i64(value + 4) or square_i64(value - 4): 1 else: 0
