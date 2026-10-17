const MaxN = 64

proc reverseLinks(next: var array[MaxN, int], previous, current: int): int =
  if next[current] >= 0:
    let head = reverseLinks(next, current, next[current])
    next[current] = previous
    next[previous] = -1
    return head
  next[current] = previous
  next[previous] = -1
  current

proc reverse_a_linked_list_using_recusion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "reverse_a_linked_list_using_recusion".} =
  if input == nil or length < 1 or length > csize_t(MaxN + 1): return -1
  if input[0] < 2 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < int64(low(int32)) or input[i + 1] > int64(high(int32)): return -1
  let bytes = csize_t(4 * n)
  if output == nil or capacity < bytes: return -2

  var nodes: array[MaxN, int32]
  var next: array[MaxN, int]
  for i in 0 ..< n:
    nodes[i] = int32(input[i + 1])
    next[i] = if i + 1 < n: i + 1 else: -1
  var node = reverseLinks(next, 0, next[0])
  for i in 0 ..< n:
    let bits = cast[uint32](nodes[node])
    for byte in 0 ..< 4:
      output[i * 4 + byte] = uint8((bits shr (byte * 8)) and 255)
    if i + 1 < n: node = next[node]
  int64(bytes)
