## Case-sensitive Burrows-Wheeler transform over packed ASCII bytes.
proc rotationLess(values: ptr UncheckedArray[int64], n, left, right: int): bool =
  for offset in 0 ..< n:
    let a = values[1 + (left + offset) mod n]
    let b = values[1 + (right + offset) mod n]
    if a != b: return a < b
  left < right

proc burrows_wheeler_transform*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "burrows_wheeler_transform".} =
  const MaxLength = 256
  if values == nil or length < 2 or values[0] < 1 or values[0] > MaxLength: return -1
  let n = int(values[0])
  if length != csize_t(n + 1): return -1
  for i in 1 ..< int(length):
    if values[i] < 0 or values[i] > 127: return -1
  let outputLength = n + 4
  if outputCapacity < csize_t(outputLength) or output == nil: return -2

  var order: array[MaxLength, int]
  for i in 0 ..< n: order[i] = i
  for i in 1 ..< n:
    let key = order[i]
    var position = i
    while position > 0 and rotationLess(values, n, key, order[position - 1]):
      order[position] = order[position - 1]
      dec position
    order[position] = key

  var primaryIndex = 0
  for row in 0 ..< n:
    if order[row] == 0: primaryIndex = row
  let encodedIndex = uint32(primaryIndex)
  for byte in 0 ..< 4: output[byte] = uint8((encodedIndex shr (8 * byte)) and 0xff'u32)
  for row in 0 ..< n: output[4 + row] = uint8(values[1 + (order[row] + n - 1) mod n])
  int64(outputLength)
