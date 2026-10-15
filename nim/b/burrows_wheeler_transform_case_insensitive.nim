## ASCII case-insensitive Burrows-Wheeler transform over packed bytes.
proc foldAscii(value: int64): uint8 =
  if value >= 65 and value <= 90: return uint8(value + 32)
  uint8(value)

proc rotationLess(values: ptr UncheckedArray[int64], n, left, right: int): bool =
  for offset in 0 ..< n:
    let a = foldAscii(values[1 + (left + offset) mod n])
    let b = foldAscii(values[1 + (right + offset) mod n])
    if a != b: return a < b
  left < right

proc rotationEqualsInput(values: ptr UncheckedArray[int64], n, start: int): bool =
  for offset in 0 ..< n:
    if values[1 + (start + offset) mod n] != values[1 + offset]: return false
  true

proc burrows_wheeler_transform_case_insensitive*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "burrows_wheeler_transform_case_insensitive".} =
  const MaxLength = 256
  if values == nil or length < 1 or values[0] < 0 or values[0] > MaxLength: return -1
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
    if rotationEqualsInput(values, n, order[row]): primaryIndex = row
  let encodedIndex = uint32(primaryIndex)
  for byte in 0 ..< 4: output[byte] = uint8((encodedIndex shr (8 * byte)) and 0xff'u32)
  for row in 0 ..< n: output[4 + row] = uint8(values[1 + (order[row] + n - 1) mod n])
  int64(outputLength)
