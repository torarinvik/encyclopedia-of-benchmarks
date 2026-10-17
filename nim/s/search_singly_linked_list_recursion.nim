const MaxNodes = 64

type Node = object
  value: int32
  next: int

proc searchRecursion(nodes: openArray[Node], current: int, key: int32): bool =
  if current < 0: return false
  nodes[current].value == key or searchRecursion(nodes, nodes[current].next, key)

proc search_singly_linked_list_recursion_impl(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "search_singly_linked_list_recursion".} =
  if input.isNil or length < 2 or length > csize_t(MaxNodes + 2): return -1
  let countValue = input[0]
  let keyValue = input[1]
  if countValue < 0 or countValue > int64(MaxNodes) or int64(length) != countValue + 2 or
      keyValue < int64(low(int32)) or keyValue > int64(high(int32)): return -1
  let count = int(countValue)
  var nodes = newSeq[Node](count)
  for index in 0 ..< count:
    let value = input[index + 2]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    nodes[index] = Node(value: int32(value), next: if index + 1 < count: index + 1 else: -1)
  if searchRecursion(nodes, if count == 0: -1 else: 0, int32(keyValue)): 1 else: 0
