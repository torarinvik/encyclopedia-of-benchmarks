proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc xor_linked_list*(input: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "xor_linked_list".} =
  if input == nil or length < 1 or length > 66: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > 64 or length != csize_t(countValue + 1): return -1
  let count = int(countValue)
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1

  let needed = 8 + 8 * count
  if output == nil or capacity < csize_t(needed): return -2
  var nodeValues: array[65, int64]
  var both: array[65, int]
  var tail = 0
  for index in 0 ..< count:
    let nodeId = index + 1
    nodeValues[nodeId] = input[index + 1]
    both[nodeId] = tail
    if tail != 0: both[tail] = both[tail] xor nodeId
    tail = nodeId

  writeI64Le(output, 0, countValue)
  var out = 8
  var previous = 0
  var current = if count == 0: 0 else: 1
  while current != 0:
    writeI64Le(output, out, nodeValues[current])
    out += 8
    let nextId = previous xor both[current]
    previous = current
    current = nextId
  int64(needed)
