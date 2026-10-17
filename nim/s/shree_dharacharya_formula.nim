import std/math

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc shree_dharacharya_formula*(input: ptr UncheckedArray[int64], length: csize_t,
                                output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                                {.cdecl, exportc: "shree_dharacharya_formula".} =
  if input == nil or length != 3: return -1
  for index in 0 ..< 3:
    if input[index] < -1_000_000 or input[index] > 1_000_000: return -1
  if input[0] == 0: return -1
  let a = float64(input[0])
  let b = float64(input[1])
  let c = float64(input[2])
  let discriminant = b * b - 4.0 * a * c
  if discriminant < 0.0: return -1
  if output == nil or capacity < 16: return -2
  let root = sqrt(discriminant)
  let denominator = 2.0 * a
  let first = (-b + root) / denominator
  let second = (-b - root) / denominator
  writeF64Le(output, 0, first)
  writeF64Le(output, 8, second)
  16
