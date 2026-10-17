const MaxN = 256
const MaxInputLength = MaxN + 2

proc reverse_k_group*(input: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "reverse_k_group".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let kValue = input[1]
  if nValue < 0 or nValue > MaxN or kValue < 1 or kValue > MaxN: return -1
  let n = int(nValue)
  let k = int(kValue)
  if length != csize_t(n + 2): return -1
  let outputBytes = csize_t(8 * n)
  if output == nil or capacity < outputBytes: return -2

  var nodes: array[MaxN, int64]
  var next: array[MaxN + 1, int]
  var head = -1
  for i in 0 ..< n:
    nodes[i] = input[i + 2]
    next[i] = -1
    if head < 0: head = i
    else:
      var tail = head
      while next[tail] >= 0: tail = next[tail]
      next[tail] = i
  var remaining = 0
  var node = head
  while node >= 0:
    inc remaining
    node = next[node]
  let dummy = MaxN
  next[dummy] = head
  var previous = dummy
  while remaining >= k:
    let current = next[previous]
    var moved = next[current]
    for _ in 1 ..< k:
      next[current] = next[moved]
      next[moved] = next[previous]
      next[previous] = moved
      moved = next[current]
    previous = current
    remaining -= k

  var result: array[MaxN, int64]
  var resultIndex = 0
  node = next[dummy]
  while node >= 0:
    result[resultIndex] = nodes[node]
    inc resultIndex
    node = next[node]
  for i in 0 ..< n:
    let bits = cast[uint64](result[i])
    for byte in 0 ..< 8:
      output[i * 8 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(outputBytes)
