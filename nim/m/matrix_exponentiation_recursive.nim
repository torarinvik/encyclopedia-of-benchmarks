proc multiply(a, b: array[4, int64]): array[4, int64] =
  for r in 0 .. 1:
    for c in 0 .. 1:
      for k in 0 .. 1: result[r*2+c] += a[r*2+k] * b[k*2+c]

proc power(a: array[4, int64], exponent: int64): array[4, int64] =
  if exponent == 0: return [1'i64, 0'i64, 0'i64, 1'i64]
  if (exponent mod 2) == 1: return multiply(power(a, exponent-1), a)
  let half = power(a, exponent div 2)
  multiply(half, half)

proc storeI64Le(value: int64, output: ptr UncheckedArray[uint8], offset: int) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 255)

proc matrix_exponentiation_recursive*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "matrix_exponentiation_recursive".} =
  if input.isNil or length != 5 or input[0] < 0 or input[0] > 30: return -2
  for i in 1 .. 4:
    if input[i] < -1 or input[i] > 1: return -2
  if output.isNil or capacity < 32: return -3
  let result = power([input[1], input[2], input[3], input[4]], input[0])
  for i in 0 ..< 4: storeI64Le(result[i], output, i*8)
  4
