const MaxN = 8

proc gapbs_pagerank_pull_gs*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "gapbs_pagerank_pull_gs".} =
  if input.isNil or length < csize_t(6) or length > csize_t(2 + MaxN * MaxN): return -1
  let n64 = input[0]
  let iterations64 = input[1]
  if n64 < 2 or n64 > int64(MaxN) or iterations64 < 0 or iterations64 > 20: return -1
  let n = int(n64)
  let iterations = int(iterations64)
  if int64(length) != 2 + n64 * n64: return -1
  var matrix: array[MaxN * MaxN, uint8]
  var outdegree: array[MaxN, int]
  for row in 0..<n:
    for column in 0..<n:
      let value = input[2 + row * n + column]
      if (value != 0 and value != 1) or (row == column and value != 0): return -1
      matrix[row * n + column] = uint8(value)
      outdegree[row] += int(value)
    if outdegree[row] == 0: return -1
  let damping = 0.85'f32
  let initScore = 1.0'f32 / float32(n)
  let baseScore = (1.0'f32 - damping) / float32(n)
  var scores: array[MaxN, float32]
  var outgoing: array[MaxN, float32]
  for node in 0..<n:
    scores[node] = initScore
    outgoing[node] = initScore / float32(outdegree[node])
  for iteration in 0..<iterations:
    for target in 0..<n:
      var incoming = 0.0'f32
      for source in 0..<n:
        if matrix[source * n + target] != 0: incoming += outgoing[source]
      scores[target] = baseScore + damping * incoming
      outgoing[target] = scores[target] / float32(outdegree[target])
  var weighted = 0.0'f64
  for node in 0..<n: weighted += float64(node + 1) * float64(scores[node])
  int64(weighted * 100.0 + 0.5)
