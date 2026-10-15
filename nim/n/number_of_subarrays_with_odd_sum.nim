## Count subarrays with an odd sum, modulo 1,000,000,007.
const Modulus = 1_000_000_007'i64

proc number_of_subarrays_with_odd_sum*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_of_subarrays_with_odd_sum".} =
  if length > 100_000 or (length > 0 and values.isNil): return -1
  var evenPrefixes = 1'i64
  var oddPrefixes = 0'i64
  var result = 0'i64
  var parity = 0'i64
  for index in 0 ..< int(length):
    let value = values[index]
    if value < -2_147_483_648 or value > 2_147_483_647: return -1
    if value mod 2 != 0: parity = 1 - parity
    if parity == 0:
      result = (result + oddPrefixes) mod Modulus
      inc evenPrefixes
    else:
      result = (result + evenPrefixes) mod Modulus
      inc oddPrefixes
  result
