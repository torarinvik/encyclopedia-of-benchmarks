const MaxN = 128
const MaxInputLength = MaxN + 1

proc reverse_a_linked_list*(input: ptr UncheckedArray[int64], length: csize_t,
                            output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "reverse_a_linked_list".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < int64(low(int32)) or input[i + 1] > int64(high(int32)): return -1
  let outputBytes = csize_t(4 * n)
  if output == nil or capacity < outputBytes: return -2

  var nodes: array[MaxN, int32]
  var next: array[MaxN, int]
  var head = -1
  for i in 0 ..< n:
    nodes[i] = int32(input[i + 1])
    next[i] = -1
    if head < 0: head = i
    else:
      var tail = head
      while next[tail] >= 0: tail = next[tail]
      next[tail] = i
  var previous = -1
  var current = head
  while current >= 0:
    let nextNode = next[current]
    next[current] = previous
    previous = current
    current = nextNode
  head = previous
  for index in 0 ..< n:
    var node = head
    for _ in 0 ..< index: node = next[node]
    let bits = cast[uint32](nodes[node])
    for byte in 0 ..< 4:
      output[index * 4 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(outputBytes)
