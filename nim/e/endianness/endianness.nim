## Dispatch the seven pinned Python endianness helpers.
proc signedU64(bits: uint64): int64 =
  if bits <= uint64(high(int64)): return int64(bits)
  -1'i64 - int64(high(uint64) - bits)

proc swapBytes(bitsInput: uint64, count: int): uint64 =
  var bits = bitsInput
  var reversed = 0'u64
  for _ in 0 ..< count:
    reversed = (reversed shl 8) or (bits and 0xff'u64)
    bits = bits shr 8
  reversed

proc endianness*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "endianness".} =
  if input.isNil or length < 1: return -1
  let operation = input[0]
  if operation >= 0 and operation <= 2:
    if length != 2: return -1
    let value = input[1]
    if operation == 0:
      if value < 0 or value > 65535: return -1
      return int64(swapBytes(uint64(value), 2))
    if operation == 1:
      if value < 0 or uint64(value) > 0xffffffff'u64: return -1
      return int64(swapBytes(uint64(value), 4))
    return signedU64(swapBytes(cast[uint64](value), 8))
  if operation == 3 or operation == 4:
    if length < 3 or input[1] < 1 or input[1] > 8 or length != csize_t(input[1] + 2): return -1
    let count = int(input[1])
    var result = 0'u64
    for index in 0 ..< count:
      let byte = input[index + 2]
      if byte < 0 or byte > 255: return -1
      let shift = if operation == 3: 8 * index else: 8 * (count - 1 - index)
      result = result or (uint64(byte) shl shift)
    return signedU64(result)
  if operation == 5 or operation == 6:
    if length != 3 or input[2] < 1 or input[2] > 8: return -1
    let count = int(input[2])
    let value = cast[uint64](input[1])
    if count < 8 and (input[1] < 0 or (value shr (8 * count)) != 0): return -1
    return signedU64(if operation == 5: value else: swapBytes(value, count))
  -1
