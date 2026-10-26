const MaxN = 16
const MaxM = 120
const MaxInput = 243

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc lex_bfs*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lex_bfs".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  let start64 = input[2]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      start64 < 0 or start64 >= n64 or int64(length) != 3 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  let start = int(start64)
  var adjacency: array[MaxN, array[MaxN, bool]]
  for edge in 0..<m:
    let u64 = input[3 + 2 * edge]
    let v64 = input[4 + 2 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacency[u][v]: return -1
    adjacency[u][v] = true
    adjacency[v][u] = true
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var labels: array[MaxN, array[MaxN, int64]]
  var labelLen: array[MaxN, int]
  var order: array[MaxN, int64]
  var selected: array[MaxN, bool]
  var current = start
  for step in 0..<n:
    if step > 0:
      var haveBest = false
      for vertex in 0..<n:
        if selected[vertex]: continue
        if not haveBest:
          current = vertex
          haveBest = true
          continue
        let shared = min(labelLen[vertex], labelLen[current])
        var position = 0
        var decided = false
        while position < shared:
          if labels[vertex][position] != labels[current][position]:
            if labels[vertex][position] > labels[current][position]: current = vertex
            decided = true
            break
          inc position
        if not decided and (labelLen[vertex] > labelLen[current] or
            (labelLen[vertex] == labelLen[current] and vertex < current)):
          current = vertex
    selected[current] = true
    order[step] = int64(current)
    for neighbor in 0..<n:
      if adjacency[current][neighbor] and not selected[neighbor]:
        var position = labelLen[neighbor]
        while position > 0:
          labels[neighbor][position] = labels[neighbor][position - 1]
          dec position
        labels[neighbor][0] = int64(step)
        inc labelLen[neighbor]
  for index in 0..<n:
    storeI64LE(output, 8 * index, order[index])
  int64(outputBytes)
