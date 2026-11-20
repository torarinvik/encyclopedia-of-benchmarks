const MaxOrder = 8'i64
type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc hilbertIndex(order, xValue, yValue: int64): int64 =
  var currentX = xValue
  var currentY = yValue
  var distance = 0'i64
  var bitIndex = order - 1
  while bitIndex >= 0:
    let bit = 1'i64 shl int(bitIndex)
    var xBit = 0'i64
    var yBit = 0'i64
    if (currentX and bit) != 0: xBit = 1
    if (currentY and bit) != 0: yBit = 1
    distance += bit * bit * ((3 * xBit) xor yBit)
    let mask = bit - 1
    var lowX = currentX and mask
    var lowY = currentY and mask
    if yBit == 0:
      if xBit != 0:
        lowX = mask - lowX
        lowY = mask - lowY
      currentX = lowY
      currentY = lowX
    else:
      currentX = lowX
      currentY = lowY
    dec bitIndex
  distance

proc storeI64Le(output: ByteArray, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8(bits and 255)
    bits = bits shr 8

proc hilbert_curve_index_encode*(input: I64Array, length: csize_t,
    output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "hilbert_curve_index_encode".} =
  if input.isNil or length != 3: return -1
  let order = input[0]
  if order < 1 or order > MaxOrder: return -1
  let side = 1'i64 shl int(order)
  let x = input[1]
  let y = input[2]
  if x < 0 or x >= side or y < 0 or y >= side: return -1
  if output.isNil or capacity < 8: return -2
  storeI64Le(output, hilbertIndex(order, x, y))
  8
