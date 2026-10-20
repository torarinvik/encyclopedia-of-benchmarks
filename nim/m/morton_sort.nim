type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc spread16(valueIn: uint32): uint32 =
  var value = valueIn
  value = (value or (value shl 8)) and 0x00ff00ff'u32
  value = (value or (value shl 4)) and 0x0f0f0f0f'u32
  value = (value or (value shl 2)) and 0x33333333'u32
  (value or (value shl 1)) and 0x55555555'u32

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc morton_sort*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "morton_sort".} =
  if values == nil or length < 3 or length > 513: return -1
  let rawCount = values[0]
  if rawCount < 1 or rawCount > 256: return -1
  let count = int(rawCount)
  if length != csize_t(1 + 2 * count): return -1
  var keys: array[256, uint32]
  var order: array[256, int]
  for index in 0 ..< count:
    let x = values[1 + 2 * index]
    let y = values[2 + 2 * index]
    if x < 0 or x > 65535 or y < 0 or y > 65535: return -1
    keys[index] = spread16(uint32(x)) or (spread16(uint32(y)) shl 1)
    order[index] = index
  let bytes = count * 8
  if output == nil or outputCapacity < csize_t(bytes): return -2
  for index in 1 ..< count:
    let current = order[index]
    var position = index
    while position > 0 and (keys[order[position - 1]] > keys[current] or
        (keys[order[position - 1]] == keys[current] and order[position - 1] > current)):
      order[position] = order[position - 1]
      dec position
    order[position] = current
  for index in 0 ..< count:
    storeI64Le(output, index * 8, int64(order[index]))
  int64(bytes)
