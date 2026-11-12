type
  I64Input = ptr UncheckedArray[int64]

proc powerAtMost(base, exponentInput, limit: int64): bool =
  if base == 0: return true
  var product = 1'i64
  var exponent = exponentInput
  while exponent > 0:
    if product > limit div base: return false
    product *= base
    exponent -= 1
  true

proc kth_root_integer*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "kth_root_integer".} =
  if input == nil or length != csize_t(2): return -1
  let number = input[0]
  let degree = input[1]
  if number < 0 or degree < 1 or degree > 64: return -1

  var low = 0'i64
  var high = number
  while low < high:
    let difference = high - low
    let candidate = low + difference div 2 + difference mod 2
    if powerAtMost(candidate, degree, number): low = candidate
    else: high = candidate - 1
  low
