const
  Modulus = 998_244_353'i64
  MaxN = 16
  MaxInput = 34

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc composition_of_formal_power_series*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "composition_of_formal_power_series".} =
  if input == nil or length < 3 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + 2 * n: return -1
  for i in 0 ..< 2 * n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
  if input[1 + n] != 0: return -1
  let bytes = 8 * n
  if output == nil or int(capacity) < bytes: return -2

  var composed: array[MaxN, int64]
  for outer in countdown(n, 1):
    if n > 1:
      for degree in countdown(n - 1, 1):
        var sum = 0'i64
        for innerDegree in 1 .. degree:
          sum = (sum + composed[degree - innerDegree] * input[1 + n + innerDegree]) mod Modulus
        composed[degree] = sum
    composed[0] = input[outer]
  for i in 0 ..< n: storeLe(output, 8 * i, composed[i])
  int64(bytes)
