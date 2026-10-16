proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc count_min_sketch_width_one_collision*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "count_min_sketch_width_one_collision".} =
  if input.isNil or length < 1 or length > 513: return -1
  let count64 = input[0]
  if count64 < 0 or count64 > 256: return -1
  let count = int(count64)
  if length != csize_t(1 + count * 2): return -1
  var queries = 0
  for i in 0..<count:
    let operation = input[1 + 2 * i]
    let key = input[2 + 2 * i]
    if (operation != 0 and operation != 1) or key < -1_000_000'i64 or key > 1_000_000'i64: return -1
    if operation == 1: inc queries
  let required = queries * 8
  if capacity < csize_t(required) or (required > 0 and output.isNil): return -2
  var inserts = 0'i64
  var outputOffset = 0
  for i in 0..<count:
    if input[1 + 2 * i] == 0: inc inserts
    else:
      putI64Le(output, outputOffset, inserts)
      outputOffset += 8
  int64(required)
