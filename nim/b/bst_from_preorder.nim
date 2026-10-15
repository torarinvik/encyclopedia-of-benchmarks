## Validate and serialize a strict BST reconstructed from preorder values.
proc validPreorder(values: ptr UncheckedArray[int64], start, endExclusive: int,
                   lower, upper: int64): bool =
  if start == endExclusive: return true
  let root = values[start]
  if root <= lower or root >= upper: return false
  var split = start + 1
  while split < endExclusive and values[split] < root: inc split
  validPreorder(values, start + 1, split, lower, root) and
    validPreorder(values, split, endExclusive, root, upper)

proc emitPreorderTree(values: ptr UncheckedArray[int64], start, endExclusive: int,
                      output: ptr UncheckedArray[uint8], position: int): int =
  if start == endExclusive:
    output[position] = 0
    return position + 1
  let root = values[start]
  var split = start + 1
  while split < endExclusive and values[split] < root: inc split
  output[position] = 1
  let encoded = cast[uint32](int32(root))
  output[position + 1] = uint8(encoded and 255)
  output[position + 2] = uint8((encoded shr 8) and 255)
  output[position + 3] = uint8((encoded shr 16) and 255)
  output[position + 4] = uint8(encoded shr 24)
  let nextPosition = emitPreorderTree(values, start + 1, split, output, position + 5)
  emitPreorderTree(values, split, endExclusive, output, nextPosition)

proc bst_from_preorder*(values: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bst_from_preorder".} =
  if length == 0 or length > 15: return -1
  for index in 0 ..< int(length):
    if values[index] < -2147483648 or values[index] > 2147483647: return -1
  if not validPreorder(values, 0, int(length), -2147483649, 2147483648): return -1
  let required = 6 * int(length) + 1
  if outputCapacity < csize_t(required) or output.isNil: return -2
  discard emitPreorderTree(values, 0, int(length), output, 0)
  int64(length)
