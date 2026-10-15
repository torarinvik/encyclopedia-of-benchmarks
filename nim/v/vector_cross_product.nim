## Cross two bounded integer vectors and encode components plus magnitude.
import math

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc vector_cross_product*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "vector_cross_product".} =
  if input == nil or inputLength != 6: return -1
  for index in 0 ..< 6:
    if input[index] < -1_000_000 or input[index] > 1_000_000: return -1
  let x = input[1] * input[5] - input[2] * input[4]
  let y = -((input[0] * input[5]) - (input[2] * input[3]))
  let z = input[0] * input[4] - input[1] * input[3]
  let magnitude = sqrt(float64(x) * float64(x) + float64(y) * float64(y) + float64(z) * float64(z))
  let magnitudeMicro = int64(magnitude * 1_000_000.0 + 0.5)
  if output == nil or outputCapacity < 32: return -2
  storeI64Le(output, 0, x); storeI64Le(output, 8, y)
  storeI64Le(output, 16, z); storeI64Le(output, 24, magnitudeMicro)
  32
