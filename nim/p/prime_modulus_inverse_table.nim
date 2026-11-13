const Modulus = 1_000_000_007'i64

proc prime_modulus_inverse_table*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "prime_modulus_inverse_table".} =
  if input.isNil or length < 1 or length > 34: return -1
  if input[0] < 0 or input[0] > 32: return -1
  let count = int(input[0])
  if int(length) != count + 1: return -1
  var maximum = 0
  for i in 0 ..< count:
    if input[i + 1] < 1 or input[i + 1] > 256: return -1
    maximum = max(maximum, int(input[i + 1]))
  if count == 0: return 0
  let bytes = 4 * count
  if output.isNil or capacity < csize_t(bytes): return -2
  var inverse: array[257, int64]
  inverse[1] = 1
  for i in 2 .. maximum:
    let value = int64(i)
    inverse[i] = Modulus - (Modulus div value) * inverse[int(Modulus mod value)] mod Modulus
  for i in 0 ..< count:
    let value = uint32(inverse[int(input[i + 1])])
    for byte in 0 ..< 4:
      output[4 * i + byte] = uint8((value shr (8 * byte)) and 255'u32)
  int64(bytes)
