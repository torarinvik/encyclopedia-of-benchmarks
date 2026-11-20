const MaxN = 64
const MaxQ = 64
const MaxInputLength = 195

proc arpa_offline_rmq*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "arpa_offline_rmq".} =
  if input.isNil or length < 2 or length > MaxInputLength: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 + n + 2 * q): return -1
  for i in 0 ..< n:
    if input[2 + i] < -1000 or input[2 + i] > 1000: return -1
  let queryStart = 2 + n
  for j in 0 ..< q:
    let left = input[queryStart + 2 * j]
    let right = input[queryStart + 2 * j + 1]
    if left < 0 or left > right or right >= nValue: return -1
  var parent: array[64, int64]
  var stack: array[64, int64]
  var head: array[64, int64]
  var queryNext: array[64, int64]
  for i in 0 ..< n:
    parent[i] = int64(i)
    head[i] = -1
  for j in 0 ..< q:
    let bucket = int(input[queryStart + 2 * j + 1])
    queryNext[j] = head[bucket]
    head[bucket] = int64(j)
  var checksum = 0'i64
  var stackSize = 0
  for right in 0 ..< n:
    while stackSize > 0 and input[2 + int(stack[stackSize - 1])] > input[2 + right]:
      dec stackSize
      parent[int(stack[stackSize])] = int64(right)
    stack[stackSize] = int64(right)
    inc stackSize
    var query = head[right]
    while query >= 0:
      let ordinal = int(query)
      var node = int(input[queryStart + 2 * ordinal])
      var root = node
      while int(parent[root]) != root: root = int(parent[root])
      while int(parent[node]) != node:
        let next = int(parent[node])
        parent[node] = int64(root)
        node = next
      checksum += int64(ordinal + 1) * int64(root + 1)
      query = queryNext[ordinal]
  checksum
