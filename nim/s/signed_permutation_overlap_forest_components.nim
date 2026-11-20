const MaxN = 8
const MaxVertices = 2 * MaxN + 2
const MaxCycles = MaxN + 1
const MaxInput = MaxN + 2
const MaxOutput = 8 * (1 + 3 * MaxCycles)

proc storeWord(bytes: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    bytes[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc signed_permutation_overlap_forest_components*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "signed_permutation_overlap_forest_components".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN or int(length) != int(nValue) + 1: return -1
  let n = int(nValue)
  let vertexCount = 2 * n + 2
  var pi: array[MaxVertices, int]
  pi[vertexCount - 1] = vertexCount - 1
  var seen = 0'u16
  for position in 0 ..< n:
    let gene = input[position + 1]
    if gene == 0 or gene < -nValue or gene > nValue: return -1
    let absolute = int(if gene < 0: -gene else: gene)
    let bit = 1'u16 shl (absolute - 1)
    if (seen and bit) != 0: return -1
    seen = seen or bit
    var left = 2 * absolute - 1
    var right = 2 * absolute
    if gene < 0: swap(left, right)
    pi[2 * position + 1] = left
    pi[2 * position + 2] = right

  var gray: array[MaxVertices, int]
  for pair in 0 .. n:
    let left = pi[2 * pair]
    let right = pi[2 * pair + 1]
    gray[left] = right
    gray[right] = left
  var cycleOf: array[MaxVertices, int]
  for vertex in 0 ..< MaxVertices: cycleOf[vertex] = -1
  var beginAt, endAt: array[MaxCycles, int]
  var cycleCount = 0
  for seed in 0 ..< vertexCount:
    if cycleOf[seed] >= 0: continue
    let cid = cycleCount
    inc cycleCount
    var vertex = seed
    var low, high = seed
    while cycleOf[vertex] < 0:
      cycleOf[vertex] = cid
      low = min(low, vertex)
      high = max(high, vertex)
      vertex = gray[vertex xor 1]
    beginAt[cid] = low
    endAt[cid] = high

  var parent: array[MaxCycles, int]
  for cid in 0 ..< cycleCount: parent[cid] = cid
  var stackId, stackBegin, stackEnd: array[MaxCycles, int]
  var top = 0
  for vertex in 0 ..< vertexCount:
    let cid = cycleOf[vertex]
    let low = beginAt[cid]
    let high = endAt[cid]
    if vertex == low:
      stackId[top] = cid
      stackBegin[top] = low
      stackEnd[top] = high
      inc top
    var extentBegin = low
    var extentEnd = high
    while top > 0 and stackBegin[top - 1] > low:
      dec top
      let popped = stackId[top]
      extentBegin = min(extentBegin, stackBegin[top])
      extentEnd = max(extentEnd, stackEnd[top])
      parent[popped] = cid
    if top == 0: return -1
    stackBegin[top - 1] = min(stackBegin[top - 1], extentBegin)
    stackEnd[top - 1] = max(stackEnd[top - 1], extentEnd)
    if vertex == stackEnd[top - 1]: dec top

  var component: array[MaxCycles, int]
  for cid in 0 ..< cycleCount:
    component[cid] = if parent[cid] == cid: beginAt[cid] else: component[parent[cid]]
  var words: array[1 + 3 * MaxCycles, int64]
  words[0] = int64(cycleCount)
  for cid in 0 ..< cycleCount:
    words[1 + 3 * cid] = int64(beginAt[cid])
    words[2 + 3 * cid] = int64(endAt[cid])
    words[3 + 3 * cid] = int64(component[cid])
  let outputBytes = (1 + 3 * cycleCount) * 8
  if output.isNil or int(capacity) < outputBytes: return -2
  var staged: array[MaxOutput, uint8]
  for word in 0 ..< 1 + 3 * cycleCount: storeWord(addr staged[0], word, words[word])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
