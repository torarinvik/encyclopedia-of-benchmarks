const MaxN = 128
const MaxQ = 32
type Query = object
  left, right, id, blockId: int

proc lower(a: array[MaxN, int64], n: int, value: int64): int =
  var lo = 0
  var hi = n
  while lo < hi:
    let mid = lo + (hi - lo) div 2
    if a[mid] < value: lo = mid + 1 else: hi = mid
  lo

proc bitSum(bit: array[MaxN + 1, int64], countValue: int): int64 =
  var i = countValue
  var total = 0'i64
  while i > 0:
    total += bit[i]
    i -= i and -i
  total

proc bitAdd(bit: var array[MaxN + 1, int64], rank: int, delta: int64) =
  var i = rank + 1
  while i <= MaxN:
    bit[i] += delta
    i += i and -i

proc before(a, b: Query): bool =
  if a.blockId != b.blockId: return a.blockId < b.blockId
  if a.right != b.right:
    if (a.blockId and 1) == 1: return a.right > b.right
    return a.right < b.right
  a.id < b.id

proc put64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc static_range_inversions_query*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "static_range_inversions_query".} =
  if input.isNil or length < 2 or length > 195: return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > MaxN or q64 < 1 or q64 > MaxQ: return -1
  let n = int(n64)
  let q = int(q64)
  if length != csize_t(2 + n + 2 * q): return -1
  var values, sorted: array[MaxN, int64]
  for i in 0 ..< n:
    values[i] = input[2 + i]
    if values[i] < 0 or values[i] > 1_000_000_000: return -1
    sorted[i] = values[i]
  for i in 1 ..< n:
    let value = sorted[i]
    var j = i
    while j > 0 and sorted[j - 1] > value:
      sorted[j] = sorted[j - 1]
      dec j
    sorted[j] = value
  var distinct = 0
  for i in 0 ..< n:
    if distinct == 0 or sorted[i] != sorted[distinct - 1]:
      sorted[distinct] = sorted[i]
      inc distinct
  var ranks: array[MaxN, int]
  for i in 0 ..< n: ranks[i] = lower(sorted, distinct, values[i])
  var blockSize = 1
  while (blockSize + 1) * (blockSize + 1) <= n: inc blockSize
  var queries: array[MaxQ, Query]
  var offset = 2 + n
  for k in 0 ..< q:
    let left = input[offset]
    let right = input[offset + 1]
    offset += 2
    if left < 0 or left >= right or right > n64: return -1
    queries[k] = Query(left: int(left), right: int(right), id: k, blockId: int(left) div blockSize)
  for i in 1 ..< q:
    let query = queries[i]
    var j = i
    while j > 0 and before(query, queries[j - 1]):
      queries[j] = queries[j - 1]
      dec j
    queries[j] = query
  var bit: array[MaxN + 1, int64]
  var answers: array[MaxQ, int64]
  var left = 0
  var right = 0
  var window = 0
  var inversions = 0'i64
  for query in queries.toOpenArray(0, q - 1):
    while left > query.left:
      dec left
      let rank = ranks[left]
      inversions += bitSum(bit, rank)
      bitAdd(bit, rank, 1)
      inc window
    while right < query.right:
      let rank = ranks[right]
      inversions += int64(window) - bitSum(bit, rank + 1)
      bitAdd(bit, rank, 1)
      inc window
      inc right
    while left < query.left:
      let rank = ranks[left]
      inversions -= bitSum(bit, rank)
      bitAdd(bit, rank, -1)
      dec window
      inc left
    while right > query.right:
      dec right
      let rank = ranks[right]
      inversions -= int64(window) - bitSum(bit, rank + 1)
      bitAdd(bit, rank, -1)
      dec window
    answers[query.id] = inversions
  let bytes = 8 * q
  if output.isNil or capacity < csize_t(bytes): return -2
  for k in 0 ..< q: put64(output, 8 * k, answers[k])
  int64(bytes)
