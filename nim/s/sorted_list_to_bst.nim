## Build a height-balanced BST from a sorted linked-list value sequence and serialize it.
proc emitTree(values: ptr UncheckedArray[int64], start, endExclusive: int,
              output: ptr UncheckedArray[uint8], position: int): int =
  if start == endExclusive:
    output[position] = 0
    return position + 1
  var middle = start
  var fast = start
  while fast < endExclusive and fast + 1 < endExclusive:
    fast += 2
    inc middle
  output[position] = 1
  let encoded = cast[uint32](int32(values[middle]))
  output[position + 1] = uint8(encoded and 255)
  output[position + 2] = uint8((encoded shr 8) and 255)
  output[position + 3] = uint8((encoded shr 16) and 255)
  output[position + 4] = uint8(encoded shr 24)
  let nextPosition = emitTree(values, start, middle, output, position + 5)
  emitTree(values, middle + 1, endExclusive, output, nextPosition)

proc sorted_list_to_bst*(values: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sorted_list_to_bst".} =
  if length > 64: return -1
  for index in 0 ..< int(length):
    if values[index] < -2147483648 or values[index] > 2147483647: return -1
    if index > 0 and values[index - 1] > values[index]: return -1
  let required = 6 * int(length) + 1
  if outputCapacity < csize_t(required) or output.isNil: return -2
  discard emitTree(values, 0, int(length), output, 0)
  int64(length)
