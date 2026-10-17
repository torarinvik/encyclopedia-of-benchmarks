const MaxN = 64
const MaxK = int64(high(int32))

proc rotate_singly_linked_lists*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rotate_singly_linked_lists".} =
  if input == nil or length < 2 or length > csize_t(MaxN + 2): return -1
  if input[0] < 0 or input[0] > MaxN or input[1] < 0 or input[1] > MaxK: return -1
  let n = int(input[0])
  let k = input[1]
  if length != csize_t(n + 2): return -1
  for i in 0 ..< n:
    if input[i + 2] < int64(low(int32)) or input[i + 2] > int64(high(int32)): return -1
  let bytes = csize_t(8 * (n + 1))
  if output == nil or capacity < bytes: return -2

  var nodes: array[MaxN, int32]
  var next: array[MaxN, int]
  for i in 0 ..< n:
    nodes[i] = int32(input[i + 2])
    next[i] = if i + 1 < n: i + 1 else: -1
  var head = if n > 0: 0 else: -1
  if n > 1 and k > 0:
    let tail = n - 1
    next[tail] = head
    let shift = int(k mod int64(n))
    let steps = n - shift
    var newTail = tail
    for _ in 0 ..< steps: newTail = next[newTail]
    head = next[newTail]
    next[newTail] = -1
  let countBits = uint64(n)
  for byte in 0 ..< 8: output[byte] = uint8((countBits shr (byte * 8)) and 255)
  var node = head
  for i in 0 ..< n:
    let bits = cast[uint64](int64(nodes[node]))
    for byte in 0 ..< 8: output[8 + i * 8 + byte] = uint8((bits shr (byte * 8)) and 255)
    if i + 1 < n: node = next[node]
  int64(bytes)
