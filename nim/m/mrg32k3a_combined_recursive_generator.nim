const
  M1 = 4_294_967_087'i64
  M2 = 4_294_944_443'i64
  MaxCount = 64

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc residue(value: int64, modulus: int64): int64 =
  result = value mod modulus
  if result < 0: result += modulus

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc mrg32k3a_combined_recursive_generator*(input: I64Input,
    length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "mrg32k3a_combined_recursive_generator".} =
  if input.isNil or length != 7: return -1
  var x1: array[3, int64]
  var x2: array[3, int64]
  for index in 0 ..< 3:
    x1[index] = input[index]
    x2[index] = input[index + 3]
    if x1[index] < 0 or x1[index] >= M1: return -1
    if x2[index] < 0 or x2[index] >= M2: return -1
  if (x1[0] == 0 and x1[1] == 0 and x1[2] == 0) or
      (x2[0] == 0 and x2[1] == 0 and x2[2] == 0):
    return -1
  let countValue = input[6]
  if countValue < 0 or countValue > MaxCount: return -1
  let count = int(countValue)
  let required = count * 8
  if count == 0: return 0
  if capacity < csize_t(required) or output.isNil: return -2

  for step in 0 ..< count:
    let next1 = residue(1_403_580 * x1[1] - 810_728 * x1[0], M1)
    let next2 = residue(527_612 * x2[2] - 1_370_589 * x2[0], M2)
    x1[0] = x1[1]; x1[1] = x1[2]; x1[2] = next1
    x2[0] = x2[1]; x2[1] = x2[2]; x2[2] = next2
    var z = next1 - next2
    if z < 0: z += M1
    putI64Le(output, step * 8, z)
  int64(required)
