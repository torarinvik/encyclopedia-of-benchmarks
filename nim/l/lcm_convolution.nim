const
  MaxN = 128
  MaxInputLength = 1 + 2 * MaxN + 1
  Modulus = 998244353'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: csize_t, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + csize_t(byte)] = uint8((bits shr (8 * byte)) and 255)

proc lcmConvolution*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lcm_convolution".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN): return -1
  let n = int(nValue)
  if length != csize_t(1 + 2 * n): return -1
  for index in 0 ..< 2 * n:
    let value = input[1 + index]
    if value < 0 or value >= Modulus: return -1
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var a: array[MaxN + 1, int64]
  var b: array[MaxN + 1, int64]
  var c: array[MaxN + 1, int64]
  for index in 1 .. n:
    a[index] = input[index]
    b[index] = input[n + index]
  for divisor in countdown(n, 1):
    var multiple = 2 * divisor
    while multiple <= n:
      a[multiple] += a[divisor]
      if a[multiple] >= Modulus: a[multiple] -= Modulus
      b[multiple] += b[divisor]
      if b[multiple] >= Modulus: b[multiple] -= Modulus
      multiple += divisor
  for index in 1 .. n: c[index] = (a[index] * b[index]) mod Modulus
  for divisor in 1 .. n:
    var multiple = 2 * divisor
    while multiple <= n:
      c[multiple] -= c[divisor]
      if c[multiple] < 0: c[multiple] += Modulus
      multiple += divisor
  for index in 1 .. n:
    storeI64Le(output, csize_t(8 * (index - 1)), c[index])
  int64(outputBytes)
