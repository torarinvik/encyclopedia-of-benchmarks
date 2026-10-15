const MaxLength = 256

proc z_function*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "z_function".} =
  if length > csize_t(MaxLength) or (length > 0 and input.isNil): return -1
  for index in 0 ..< int(length):
    if input[index] < 0 or input[index] > 127: return -1
  let required = int(length) * 8
  if int(capacity) < required or (required > 0 and output.isNil): return -2

  var z: array[MaxLength, int64]
  var left = 0
  var right = 0
  for index in 1 ..< int(length):
    if index <= right:
      let prior = int(z[index - left])
      let window = right - index + 1
      z[index] = int64(min(window, prior))
    while index + int(z[index]) < int(length) and input[int(z[index])] == input[index + int(z[index])]:
      inc z[index]
    if index + int(z[index]) > right + 1:
      left = index
      right = index + int(z[index]) - 1
  for index in 0 ..< int(length):
    let bits = cast[uint64](z[index])
    for byte in 0 ..< 8:
      output[8 * index + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)
  int64(required)
