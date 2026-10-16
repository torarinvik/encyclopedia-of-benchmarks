const MaxValue = 1_073_741_823'i64

proc non_repeating_element*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "non_repeating_element".} =
  if length < 2 or length > 64 or (length mod 2) != 0: return -1
  var xorResult = 0'i32
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > MaxValue: return -1
    xorResult = xorResult xor int32(values[index])
  let rightmostSetBit = xorResult and -xorResult
  var num1 = 0'i32
  var num2 = 0'i32
  for index in 0 ..< int(length):
    let value = int32(values[index])
    if (value and rightmostSetBit) != 0: num1 = num1 xor value
    else: num2 = num2 xor value
  (int64(num1) shl 32) or int64(uint32(num2))
