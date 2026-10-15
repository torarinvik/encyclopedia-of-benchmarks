## Iterative extended Euclid for positive signed-32-bit inputs.
proc storeI32(value: int64, output: ptr UncheckedArray[uint8], position: var int) =
  var magnitude: uint64
  if value < 0: magnitude = uint64(-value)
  else: magnitude = uint64(value)
  var bits = magnitude
  if value < 0: bits = (1'u64 shl 32) - magnitude
  for _ in 0 ..< 4:
    output[position] = uint8(bits mod 256)
    bits = bits div 256
    inc position

proc extendedEuclideanAlgorithm*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "extended_euclidean_algorithm".} =
  if length != 2 or input[0] < 1 or input[0] > high(int32) or
      input[1] < 1 or input[1] > high(int32): return -1
  if outputCapacity < 12: return -2

  var oldR = input[0]
  var remainder = input[1]
  var oldX = 1'i64
  var x = 0'i64
  var oldY = 0'i64
  var y = 1'i64
  while remainder != 0:
    let quotient = oldR div remainder
    let nextR = oldR - quotient * remainder
    oldR = remainder
    remainder = nextR
    let nextX = oldX - quotient * x
    oldX = x
    x = nextX
    let nextY = oldY - quotient * y
    oldY = y
    y = nextY
  if oldR > high(int32) or oldX < low(int32) or oldX > high(int32) or
      oldY < low(int32) or oldY > high(int32): return -1
  var position = 0
  storeI32(oldR, output, position)
  storeI32(oldX, output, position)
  storeI32(oldY, output, position)
  if position == 12: return 3
  -1
