import std/ffi

const
  MaxN = 64
  MaxParseableLength = 65

proc gbstBuildInterval(lo, hi: int, path: var array[MaxN, int],
                       prefix: var array[MaxN + 1, int],
                       gbstParent, leftChild, rightChild, localSize: var array[MaxN, int]): int =
  let totalWeight = prefix[hi] - prefix[lo]
  var low = lo
  var high = hi
  while high - low > 1:
    let middle = (low + high) div 2
    if 2 * (prefix[middle] - prefix[lo]) <= totalWeight:
      low = middle
    else:
      high = middle
  let pivot = low
  let node = path[pivot]
  localSize[node] = hi - lo
  if lo < pivot:
    let child = gbstBuildInterval(lo, pivot, path, prefix, gbstParent,
                                  leftChild, rightChild, localSize)
    leftChild[node] = child
    gbstParent[child] = node
  if pivot + 1 < hi:
    let child = gbstBuildInterval(pivot + 1, hi, path, prefix, gbstParent,
                                  leftChild, rightChild, localSize)
    rightChild[node] = child
    gbstParent[child] = node
  node

proc global_balanced_binary_tree*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "global_balanced_binary_tree".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN): return -1
  if length != csize_t(nValue): return -1
  let n = int(nValue)

  var parent, heavyChild, gbstParent, leftChild, rightChild, localSize: array[MaxN, int]
  var subtreeSize: array[MaxN, int]
  var path: array[MaxN, int]
  var prefix: array[MaxN + 1, int]
  for vertex in 0 ..< n:
    parent[vertex] = -1
    subtreeSize[vertex] = 1
    heavyChild[vertex] = -1
    gbstParent[vertex] = -1
    leftChild[vertex] = -1
    rightChild[vertex] = -1
    localSize[vertex] = 0
  for vertex in 1 ..< n:
    let p = input[vertex]
    if p < 0 or p >= int64(vertex): return -1
    parent[vertex] = int(p)

  var cursor = n - 1
  while cursor > 0:
    subtreeSize[parent[cursor]] += subtreeSize[cursor]
    dec cursor
  for vertex in 1 ..< n:
    let p = parent[vertex]
    let current = heavyChild[p]
    if current < 0 or subtreeSize[vertex] > subtreeSize[current]:
      heavyChild[p] = vertex

  for head in 0 ..< n:
    if head > 0 and heavyChild[parent[head]] == head: continue
    var pathLength = 0
    var vertex = head
    prefix[0] = 0
    while vertex < n:
      let child = heavyChild[vertex]
      var weight = subtreeSize[vertex]
      if child >= 0: weight -= subtreeSize[child]
      path[pathLength] = vertex
      prefix[pathLength + 1] = prefix[pathLength] + weight
      inc pathLength
      if child < 0: break
      vertex = child
    let root = gbstBuildInterval(0, pathLength, path, prefix,
                                 gbstParent, leftChild, rightChild, localSize)
    gbstParent[root] = if head == 0: -1 else: parent[head]

  var checksum = 0'i64
  for vertex in 0 ..< n:
    let record = int64(gbstParent[vertex] + 1)
      + 65'i64 * int64(leftChild[vertex] + 1)
      + 4225'i64 * int64(rightChild[vertex] + 1)
      + 274625'i64 * int64(localSize[vertex])
    checksum += int64(vertex + 1) * record
  checksum
