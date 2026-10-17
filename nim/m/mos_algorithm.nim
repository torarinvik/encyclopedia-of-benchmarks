const MaxN = 256
const MaxQ = 256
const MaxInputLength = 1029
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc queryBefore(a, b: int, lefts, rights: openArray[int32], blockSize: int): bool =
  let blockA = lefts[a] div int32(blockSize)
  let blockB = lefts[b] div int32(blockSize)
  if blockA != blockB: return blockA < blockB
  if (blockA and 1) != 0: rights[a] < rights[b]
  else: rights[a] > rights[b]

proc hashResults(operation: uint8, count: int, results: array[MaxQ, int32]): int64 =
  var hashValue = FnvOffset
  hashValue = (hashValue xor uint64(operation)) *% FnvPrime
  let queryCount = uint16(count)
  hashValue = (hashValue xor uint64(uint8(queryCount))) *% FnvPrime
  hashValue = (hashValue xor uint64(uint8(queryCount shr 8))) *% FnvPrime
  for index in 0 ..< count:
    let bits = cast[uint32](results[index])
    for shift in countup(0, 24, 8):
      hashValue = (hashValue xor uint64(uint8(bits shr shift))) *% FnvPrime
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)

proc mos_algorithm*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "mos_algorithm".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  let operation = input[0]
  let n64 = input[1]
  let q64 = input[2]
  let target64 = input[3]
  if (operation != 0'i64 and operation != 1'i64) or n64 < 1'i64 or n64 > int64(MaxN) or
      q64 < 0'i64 or q64 > int64(MaxQ) or target64 < -1_000_000'i64 or target64 > 1_000_000'i64 or
      length != csize_t(4'i64 + n64 + 3'i64 * q64): return -1
  let n = int(n64)
  let q = int(q64)
  let target = int32(target64)

  var values: array[MaxN, int32]
  for index in 0 ..< n:
    if input[4 + index] < -1_000_000'i64 or input[4 + index] > 1_000_000'i64: return -1
    values[index] = int32(input[4 + index])

  var lefts: array[MaxQ, int32]
  var rights: array[MaxQ, int32]
  var indices: array[MaxQ, int32]
  var order: array[MaxQ, int]
  var seen: array[MaxQ, bool]
  let offset = 4 + n
  for query in 0 ..< q:
    let left = input[offset + 3 * query]
    let right = input[offset + 3 * query + 1]
    let index = input[offset + 3 * query + 2]
    if left < 0 or right < left or right >= n64 or index < 0 or index >= q64 or seen[int(index)]: return -1
    lefts[query] = int32(left)
    rights[query] = int32(right)
    indices[query] = int32(index)
    seen[int(index)] = true
    order[query] = query

  var blockSize = 1
  while (blockSize + 1) * (blockSize + 1) <= n: inc blockSize
  for query in 1 ..< q:
    let current = order[query]
    var position = query
    while position > 0 and queryBefore(current, order[position - 1], lefts, rights, blockSize):
      order[position] = order[position - 1]
      dec position
    order[position] = current

  var results: array[MaxQ, int32]
  var currentLeft = 0'i32
  var currentRight = -1'i32
  var aggregate = 0'i32
  for sorted in 0 ..< q:
    let query = order[sorted]
    let left = lefts[query]
    let right = rights[query]
    if operation == 0:
      while currentRight < right:
        inc currentRight
        aggregate += values[int(currentRight)]
      while currentRight > right:
        aggregate -= values[int(currentRight)]
        dec currentRight
      while currentLeft < left:
        aggregate -= values[int(currentLeft)]
        inc currentLeft
      while currentLeft > left:
        dec currentLeft
        aggregate += values[int(currentLeft)]
    else:
      while currentRight < right:
        inc currentRight
        if values[int(currentRight)] == target: inc aggregate
      while currentRight > right:
        if values[int(currentRight)] == target: dec aggregate
        dec currentRight
      while currentLeft < left:
        if values[int(currentLeft)] == target: dec aggregate
        inc currentLeft
      while currentLeft > left:
        dec currentLeft
        if values[int(currentLeft)] == target: inc aggregate
    results[int(indices[query])] = aggregate

  hashResults(uint8(operation), q, results)
