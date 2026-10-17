proc rotateLeftBits(value: uint64, distance: int): uint64 =
  if distance == 0: value
  else: (value shl distance) or (value shr (64 - distance))

proc rotateRightBits(value: uint64, distance: int): uint64 =
  if distance == 0: value
  else: (value shr distance) or (value shl (64 - distance))

proc long_utils*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "long_utils".} =
  if input == nil or length != 3: return -1
  if input[0] < 0 or input[0] > 3 or input[2] < 0 or input[2] > 63: return -1
  if output == nil or capacity < 8: return -2
  let bits = cast[uint64](input[1])
  let distance = int(input[2])
  let rotated = if input[0] < 2: rotateLeftBits(bits, distance) else: rotateRightBits(bits, distance)
  for byte in 0 ..< 8:
    output[byte] = uint8((rotated shr (8 * byte)) and 255)
  8

