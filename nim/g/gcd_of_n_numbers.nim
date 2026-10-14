## Fold positive signed 32-bit values with Euclid's GCD algorithm.
proc gcdPair(leftInput, rightInput: int64): int64 =
  var left = leftInput
  var right = rightInput
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc gcdOfNNumbers*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "gcd_of_n_numbers".} =
  if length == 0 or length > 64: return -1
  for index in 0 ..< int(length):
    if values[index] < 1 or values[index] > 2147483647: return -1
  var result = values[0]
  var index = 1
  while index < int(length) and result != 1:
    result = gcdPair(result, values[index])
    inc index
  result
