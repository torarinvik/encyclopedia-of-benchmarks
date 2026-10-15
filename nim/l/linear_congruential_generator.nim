proc putU64Le(output: ptr UncheckedArray[uint8], offset: int, value: uint64) =
  for byte in 0 ..< 8: output[offset + byte] = uint8((value shr (8 * byte)) and 0xFF'u64)

proc linear_congruential_generator*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "linear_congruential_generator".} =
  if input.isNil or length != 5: return -1
  let seed = input[0]; let multiplier = input[1]; let increment = input[2]; let modulo = input[3]; let count = input[4]
  if modulo < 2 or modulo > 4294967296'i64 or seed < 0 or seed >= modulo or multiplier < 0 or multiplier > 65535 or increment < 0 or increment > 4294967295'i64 or count < 0 or count > 512: return -1
  let n = int(count); let required = n * 8
  if capacity < csize_t(required) or (required > 0 and output.isNil): return -2
  var state = uint64(seed)
  for i in 0 ..< n:
    state = (uint64(multiplier) * state + uint64(increment)) mod uint64(modulo)
    putU64Le(output, i * 8, state)
  int64(required)
