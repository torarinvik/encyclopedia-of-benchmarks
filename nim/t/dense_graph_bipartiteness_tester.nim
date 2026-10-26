const MaxN = 64
const MaxQ = 16
const MaxInput = 82

proc hasEdge(row: int64, vertex: int): bool = ((cast[uint64](row) shr vertex) and 1) != 0
proc put(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc dense_graph_bipartiteness_tester*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "dense_graph_bipartiteness_tester".} =
  if input.isNil or length < 4 or length > csize_t(MaxInput): return -1
  let n64, q64 = input[0], input[1]
  if n64 < 1 or n64 > MaxN or q64 < 1 or q64 > MaxQ: return -1
  let n, q = int(n64), int(q64)
  if q > n or int(length) != 2 + n + q: return -1
  for i in 0..<n:
    let row = input[2 + i]
    if (n < 64 and (row < 0 or (cast[uint64](row) shr n) != 0)) or hasEdge(row, i): return -1
    for j in i + 1..<n:
      if hasEdge(row, j) != hasEdge(input[2 + j], i): return -1
  var remaining: array[MaxN, int]
  var sample: array[MaxQ, int]
  for i in 0..<n: remaining[i] = i
  for i in 0..<q:
    let draw = input[2 + n + i]
    if draw < 0 or draw >= n64 - int64(i): return -1
    let selected = i + int(draw)
    swap(remaining[i], remaining[selected]); sample[i] = remaining[i]
  var adjacent: array[MaxQ, array[MaxQ, bool]]
  for i in 0..<q:
    for j in i + 1..<q:
      adjacent[i][j] = hasEdge(input[2 + sample[i]], sample[j])
      adjacent[j][i] = adjacent[i][j]
  var color: array[MaxQ, int]
  for i in 0..<q: color[i] = -1
  var accepted = 1'i64
  for start in 0..<q:
    if color[start] != -1: continue
    var queue: array[MaxQ, int]
    var head = 0; var tail = 0
    queue[tail] = start; inc tail; color[start] = 0
    while head < tail:
      let vertex = queue[head]; inc head
      for neighbor in 0..<q:
        if not adjacent[vertex][neighbor]: continue
        if color[neighbor] == -1:
          color[neighbor] = color[vertex] xor 1; queue[tail] = neighbor; inc tail
        elif color[neighbor] == color[vertex]: accepted = 0
  if output.isNil or capacity < 16: return -2
  var staged: array[16, uint8]
  put(addr staged[0], 0, accepted)
  put(addr staged[0], 8, int64(q * (q - 1) div 2))
  for i in 0..<16: output[i] = staged[i]
  16
