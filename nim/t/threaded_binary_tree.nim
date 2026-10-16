const MaxNodes = 128

type Node = object
  key: int32
  left: int
  right: int
  leftIsThread: bool
  rightIsThread: bool

proc putI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u32)

proc threaded_binary_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "threaded_binary_tree".} =
  if input.isNil or length < 1: return -1
  if input[0] < 0 or input[0] > MaxNodes: return -1
  let count = int(input[0])
  if int(length) != 1 + count: return -1
  for i in 0 ..< count:
    if input[i + 1] < -2147483648'i64 or input[i + 1] > 2147483647'i64: return -1

  let required = count * 4
  if required > 0 and (output.isNil or int(outputCapacity) < required): return -2

  var nodes: array[MaxNodes, Node]
  var root = -1
  for inserted in 0 ..< count:
    let node = inserted
    let key = int32(input[inserted + 1])
    nodes[node] = Node(key: key, left: -1, right: -1, leftIsThread: false, rightIsThread: false)
    if root == -1:
      root = node
      continue

    var current = root
    var parent = -1
    while true:
      parent = current
      if key < nodes[current].key:
        if not nodes[current].leftIsThread and nodes[current].left != -1:
          current = nodes[current].left
        else:
          break
      elif not nodes[current].rightIsThread and nodes[current].right != -1:
        current = nodes[current].right
      else:
        break

    if key < nodes[parent].key:
      nodes[node].left = nodes[parent].left
      nodes[node].leftIsThread = nodes[parent].leftIsThread
      nodes[node].right = parent
      nodes[node].rightIsThread = true
      nodes[parent].left = node
      nodes[parent].leftIsThread = false
    else:
      nodes[node].right = nodes[parent].right
      nodes[node].rightIsThread = nodes[parent].rightIsThread
      nodes[node].left = parent
      nodes[node].leftIsThread = true
      nodes[parent].right = node
      nodes[parent].rightIsThread = false

  var current = root
  while current != -1 and not nodes[current].leftIsThread and nodes[current].left != -1:
    current = nodes[current].left
  var written = 0
  while current != -1:
    putI32Le(output, written, nodes[current].key)
    written += 4
    if nodes[current].rightIsThread:
      current = nodes[current].right
    else:
      current = nodes[current].right
      while current != -1 and not nodes[current].leftIsThread and nodes[current].left != -1:
        current = nodes[current].left
  int64(written)
