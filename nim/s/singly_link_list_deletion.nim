const MaxN = 64

proc singly_link_list_deletion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "singly_link_list_deletion".} =
  if input == nil or length < 2 or length > csize_t(MaxN + 2): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(n + 2) or input[1] < 1 or input[1] > int64(n): return -1
  for i in 0 ..< n:
    if input[i + 2] < int64(low(int32)) or input[i + 2] > int64(high(int32)): return -1
  let bytes = csize_t(4 * (n - 1))
  if output == nil or capacity < bytes: return -2

  var nodes: array[MaxN, int32]
  var next: array[MaxN, int]
  for i in 0 ..< n:
    nodes[i] = int32(input[i + 2])
    next[i] = if i + 1 < n: i + 1 else: -1
  var head = 0
  let position = int(input[1])
  if position == 1: head = next[head]
  else:
    var previous = head
    for i in 2 ..< position: previous = next[previous]
    let removed = next[previous]
    next[previous] = next[removed]
  var node = head
  for i in 0 ..< n - 1:
    let bits = cast[uint32](nodes[node])
    for byte in 0 ..< 4:
      output[i * 4 + byte] = uint8((bits shr (byte * 8)) and 255)
    if i + 1 < n - 1: node = next[node]
  int64(bytes)
