## Recursively unlink matching nodes from an indexed linked-list representation.
const MaxNodes = 1024

proc removeChain(input: ptr UncheckedArray[int64], nextNode: ptr UncheckedArray[csize_t],
    node, none: csize_t, target: int64): csize_t =
  if node == none: return none
  let next = nextNode[node]
  if input[node + 1] == target:
    return removeChain(input, nextNode, next, none, target)
  nextNode[node] = removeChain(input, nextNode, next, none, target)
  node

proc remove_linked_list_elements*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "remove_linked_list_elements".} =
  if input == nil or length == 0 or length > csize_t(MaxNodes + 1): return -1
  let target = input[0]
  if target < int64(low(int32)) or target > int64(high(int32)): return -1
  let nodeCount = length - 1
  var nextStorage: array[MaxNodes + 1, csize_t]
  for index in 0 ..< int(nodeCount):
    let value = input[index + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    nextStorage[index] = csize_t(index + 1)
  nextStorage[int(nodeCount)] = nodeCount
  let nextNode = cast[ptr UncheckedArray[csize_t]](addr nextStorage[0])
  let head = removeChain(input, nextNode, (if nodeCount == 0: nodeCount else: 0), nodeCount, target)
  var survivorCount: csize_t = 0
  var node = head
  while node != nodeCount:
    inc survivorCount
    node = nextNode[node]
  let outputBytes = survivorCount * 4
  if outputCapacity < outputBytes or (outputBytes != 0 and output == nil): return -2
  var written: csize_t = 0
  node = head
  while node != nodeCount:
    let bits = cast[uint32](int32(input[node + 1]))
    for byte in 0 ..< 4:
      output[written * 4 + csize_t(byte)] = uint8((bits shr (byte * 8)) and 0xff'u32)
    inc written
    node = nextNode[node]
  int64(written)
