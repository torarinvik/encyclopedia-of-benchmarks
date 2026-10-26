const
  MaxN = 16
  MaxQueries = 16
  MaxInput = 52

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc isMarked(bitmap: uint32, vertex: int): bool =
  (bitmap and (1'u32 shl vertex)) != 0

proc shortcutInverse(target, n: int, successor: array[MaxN, int], bitmap: uint32,
    shortcuts: array[MaxN, int]): int =
  var marker = target
  var steps = 0
  while steps < n and not isMarked(bitmap, marker):
    marker = successor[marker]
    inc steps
  if not isMarked(bitmap, marker):
    var previous = target
    var current = successor[target]
    while current != target:
      previous = current
      current = successor[current]
    return previous
  var rank = 0
  for vertex in 0 ..< marker:
    if isMarked(bitmap, vertex): inc rank
  var current = shortcuts[rank]
  var previous = current
  current = successor[current]
  for _ in 0 ..< n:
    if current == target: return previous
    previous = current
    current = successor[current]
  -1

proc permutation_shortcut_index*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "permutation_shortcut_index".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let nRaw = input[0]
  let strideRaw = input[1]
  if nRaw < 1 or nRaw > MaxN or strideRaw < 1 or strideRaw > MaxN: return -1
  let n = int(nRaw)
  let stride = int(strideRaw)
  let queryAt = 2 + n
  if int(length) <= queryAt: return -1
  let queryRaw = input[queryAt]
  if queryRaw < 0 or queryRaw > MaxQueries or int(length) != queryAt + 1 + 2 * int(queryRaw): return -1
  let queryCount = int(queryRaw)
  var successor: array[MaxN, int]
  var seen: array[MaxN, bool]
  for vertex in 0 ..< n:
    let value = input[2 + vertex]
    if value < 1 or value > nRaw or seen[int(value) - 1]: return -1
    seen[int(value) - 1] = true
    successor[vertex] = int(value) - 1
  for query in 0 ..< queryCount:
    let op = input[queryAt + 1 + 2 * query]
    let index = input[queryAt + 2 + 2 * query]
    if (op != 0 and op != 1) or index < 1 or index > nRaw: return -1

  var visited: array[MaxN, bool]
  var backPointer: array[MaxN, int]
  for vertex in 0 ..< n: backPointer[vertex] = -1
  var bitmap = 0'u32
  for start in 0 ..< n:
    if visited[start]: continue
    var cycle: array[MaxN, int]
    var cycleLength = 0
    var current = start
    while not visited[current]:
      visited[current] = true
      cycle[cycleLength] = current
      inc cycleLength
      current = successor[current]
    if cycleLength >= stride:
      var offset = 0
      while offset < cycleLength:
        let vertex = cycle[offset]
        bitmap = bitmap or (1'u32 shl vertex)
        var backOffset = (offset - stride) mod cycleLength
        if backOffset < 0: backOffset += cycleLength
        backPointer[vertex] = cycle[backOffset]
        offset += stride
  var shortcuts: array[MaxN, int]
  var shortcutCount = 0
  for vertex in 0 ..< n:
    if isMarked(bitmap, vertex):
      shortcuts[shortcutCount] = backPointer[vertex]
      inc shortcutCount

  var answers: array[MaxQueries, int64]
  for query in 0 ..< queryCount:
    let op = input[queryAt + 1 + 2 * query]
    let target = int(input[queryAt + 2 + 2 * query]) - 1
    let answer = if op == 0: successor[target]
      else: shortcutInverse(target, n, successor, bitmap, shortcuts)
    if answer < 0: return -1
    answers[query] = int64(answer + 1)
  let bytes = queryCount * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  for query in 0 ..< queryCount: storeI64Le(output, query * 8, answers[query])
  int64(bytes)
