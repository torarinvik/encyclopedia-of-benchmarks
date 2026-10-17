const
  MaxNodeCount = 63
  MaxParseableInputLength = 65

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

## Bounded Morris inorder traversal over a complete level-order tree.
proc morrisinorder*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "morrisinorder".} =
  if values == nil or length < 1 or length > csize_t(MaxParseableInputLength): return -1
  let rawCount = values[0]
  if rawCount < 0 or rawCount > MaxNodeCount: return -1
  let count = int(rawCount)
  if length != csize_t(count + 1): return -1
  for index in 0 ..< count:
    let node = values[index + 1]
    if node < -2147483648'i64 or node > 2147483647'i64: return -1

  let byteCount = count * 4
  if output == nil or outputCapacity < csize_t(byteCount): return -2

  var leftNodes: array[MaxNodeCount, int]
  var rightNodes: array[MaxNodeCount, int]
  for index in 0 ..< count:
    let leftIndex = 2 * index + 1
    let rightIndex = 2 * index + 2
    leftNodes[index] = if leftIndex < count: leftIndex else: -1
    rightNodes[index] = if rightIndex < count: rightIndex else: -1

  var current = if count == 0: -1 else: 0
  var written = 0
  while current >= 0:
    if leftNodes[current] < 0:
      storeI32Le(output, written * 4, int32(values[current + 1]))
      inc written
      current = rightNodes[current]
    else:
      var predecessor = leftNodes[current]
      while rightNodes[predecessor] >= 0 and rightNodes[predecessor] != current:
        predecessor = rightNodes[predecessor]
      if rightNodes[predecessor] < 0:
        rightNodes[predecessor] = current
        current = leftNodes[current]
      else:
        rightNodes[predecessor] = -1
        storeI32Le(output, written * 4, int32(values[current + 1]))
        inc written
        current = rightNodes[current]
  int64(byteCount)
