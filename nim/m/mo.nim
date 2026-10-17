const MaxN = 64
const MaxQ = 64
const MaxValue = 255
const MaxParseableInputWords = 2 + MaxN + 2 * MaxQ + 1
const MaxOutputBytes = 4 * MaxQ

type Query = object
  left, right, index: int

proc ceilSqrt(n: int): int =
  result = 1
  while result * result < n: inc result

proc before(a, b: Query, blockSize: int): bool =
  let aBlock = a.left div blockSize
  let bBlock = b.left div blockSize
  if aBlock != bBlock: return aBlock < bBlock
  a.right < b.right

proc putI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc mo*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "mo".} =
  if input == nil or length < 2 or length > csize_t(MaxParseableInputWords): return -1
  let nRaw = input[0]
  if nRaw < 1 or nRaw > MaxN: return -1
  let n = int(nRaw)
  let qOffset = 1 + n
  if int(length) <= qOffset: return -1
  let qRaw = input[qOffset]
  if qRaw < 0 or qRaw > MaxQ: return -1
  let qCount = int(qRaw)
  if int(length) != qOffset + 1 + 2 * qCount: return -1
  for i in 0 ..< n:
    if input[1 + i] < 0 or input[1 + i] > MaxValue: return -1

  var queries: array[MaxQ, Query]
  for i in 0 ..< qCount:
    let leftRaw = input[qOffset + 1 + 2 * i]
    let rightRaw = input[qOffset + 2 + 2 * i]
    if leftRaw < 1 or rightRaw < leftRaw or rightRaw > nRaw: return -1
    queries[i] = Query(left: int(leftRaw - 1), right: int(rightRaw - 1), index: i)
  let bytes = 4 * qCount
  if output == nil or int(capacity) < bytes: return -2

  let blockSize = ceilSqrt(n)
  for i in 1 ..< qCount:
    let value = queries[i]
    var j = i
    while j > 0 and before(value, queries[j - 1], blockSize):
      queries[j] = queries[j - 1]
      dec j
    queries[j] = value

  var frequencies: array[MaxValue + 1, int32]
  var answers: array[MaxQ, int32]
  var distinct = 0'i32
  var left = 0
  var right = 0
  for i in 0 ..< qCount:
    let query = queries[i]
    while left < query.left:
      let value = int(input[1 + left])
      inc left
      dec frequencies[value]
      if frequencies[value] == 0: dec distinct
    while left > query.left:
      dec left
      let value = int(input[1 + left])
      inc frequencies[value]
      if frequencies[value] == 1: inc distinct
    while right <= query.right:
      let value = int(input[1 + right])
      inc frequencies[value]
      if frequencies[value] == 1: inc distinct
      inc right
    while right > query.right + 1:
      dec right
      let value = int(input[1 + right])
      dec frequencies[value]
      if frequencies[value] == 0: dec distinct
    answers[query.index] = distinct

  if bytes == 0: return 0
  var buffer: array[MaxOutputBytes, uint8]
  for i in 0 ..< qCount: putI32Le(addr buffer[0], i * 4, answers[i])
  for i in 0 ..< bytes: output[i] = buffer[i]
  int64(bytes)
