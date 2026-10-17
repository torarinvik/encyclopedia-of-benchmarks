const MaxN = 256
const MaxInputLength = MaxN + 1

proc reverse_linked_list*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "reverse_linked_list".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(n + 1): return -1
  let outputBytes = csize_t(8 * n)
  if output == nil or capacity < outputBytes: return -2

  var nodes: array[MaxN, int64]
  var next, previousLink: array[MaxN, int]
  for i in 0 ..< n:
    nodes[i] = input[i + 1]
    next[i] = if i + 1 < n: i + 1 else: -1
    previousLink[i] = if i > 0: i - 1 else: -1
  var previous = -1
  var current = 0
  while current >= 0:
    let nextNode = next[current]
    next[current] = previous
    previousLink[current] = nextNode
    previous = current
    current = nextNode
  var node = previous
  var expectedPrevious = -1
  var resultValues: array[MaxN, int64]
  for i in 0 ..< n:
    if node < 0 or previousLink[node] != expectedPrevious: return -1
    resultValues[i] = int64(nodes[node])
    expectedPrevious = node
    node = next[node]
  if node >= 0: return -1
  for i in 0 ..< n:
    let bits = cast[uint64](resultValues[i])
    for byte in 0 ..< 8:
      output[i * 8 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(outputBytes)
