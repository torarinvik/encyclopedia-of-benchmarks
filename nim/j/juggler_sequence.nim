## Encode the Juggler sequence through its first 1 as little-endian u32 values.
proc floorSqrt(value: int64): int64 =
  var low = 0'i64
  var high = value + 1
  while high - low > 1:
    let middle = low + (high - low) div 2
    if middle <= value div middle: low = middle else: high = middle
  low

proc juggler_sequence*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "juggler_sequence".} =
  if value < 1 or value > 25: return -1
  var sequence: array[16, int64]
  var count = 1
  sequence[0] = value
  while sequence[count - 1] != 1:
    let current = sequence[count - 1]
    sequence[count] = if current mod 2 == 0: floorSqrt(current)
      else: floorSqrt(current * current * current)
    inc count
  let required = count * 4
  if output == nil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< count:
    let term = uint32(sequence[index])
    for byte in 0 ..< 4:
      output[4 * index + byte] = uint8((term shr (8 * byte)) and 255)
  int64(required)
