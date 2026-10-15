## Delete the floor(n / 2)-indexed node using the source's fast/slow traversal.
const MaxNodes = 1024

proc delete_middle_node*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "delete_middle_node".} =
  if length > csize_t(MaxNodes) or (length != 0 and input == nil): return -1
  for index in 0 ..< int(length):
    if input[index] < int64(low(int32)) or input[index] > int64(high(int32)): return -1
  if length <= 1: return 0
  var nextStorage: array[MaxNodes + 1, csize_t]
  for index in 0 ..< int(length): nextStorage[index] = csize_t(index + 1)
  nextStorage[int(length)] = length
  let nextNode = cast[ptr UncheckedArray[csize_t]](addr nextStorage[0])
  var nodeCount: csize_t = 0
  var cursor: csize_t = 0
  while cursor != length:
    inc nodeCount
    cursor = nextNode[cursor]
  var fast: csize_t = 0
  var slow: csize_t = 0
  var previous = length
  while nextNode[fast] != length and nextNode[nextNode[fast]] != length:
    previous = slow
    slow = nextNode[slow]
    fast = nextNode[nextNode[fast]]
  if nodeCount mod 2 == 0:
    previous = slow
    slow = nextNode[slow]
  nextNode[previous] = nextNode[slow]
  let survivorCount = nodeCount - 1
  let outputBytes = survivorCount * 4
  if outputCapacity < outputBytes or (outputBytes != 0 and output == nil): return -2
  var written: csize_t = 0
  var node: csize_t = 0
  while node != length:
    let bits = cast[uint32](int32(input[node]))
    for byte in 0 ..< 4:
      output[written * 4 + csize_t(byte)] = uint8((bits shr (byte * 8)) and 0xff'u32)
    inc written
    node = nextNode[node]
  int64(written)
