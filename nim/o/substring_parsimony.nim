const
  MaxStates = 4
  MaxInput = 26
  MaxAssignments = 1024
  MaxOutputWords = 2 + 5 * MaxAssignments
  Inf = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc substring_parsimony*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "substring_parsimony".} =
  if input.isNil or length < csize_t(10) or length > csize_t(MaxInput): return -1
  let qRaw = input[0]
  let threshold = input[1]
  if qRaw < 1 or qRaw > MaxStates or threshold < 0 or threshold > 36: return -1
  let q = int(qRaw)
  if int(length) != 9 + q * q: return -1
  var child: array[2, array[2, int64]]
  child[0] = [input[2], input[3]]
  child[1] = [input[4], input[5]]
  for node in 0 ..< 2:
    if child[node][0] < 1 or child[node][0] > 4 or child[node][1] < 1 or child[node][1] > 4
        or child[node][0] == child[node][1]: return -1
  var rootLeaf = -1'i64
  if child[0][0] == 1: rootLeaf = child[0][1]
  elif child[0][1] == 1: rootLeaf = child[0][0]
  if rootLeaf < 2 or rootLeaf > 4: return -1
  if child[1][0] < 2 or child[1][0] > 4 or child[1][1] < 2 or child[1][1] > 4
      or child[1][0] == child[1][1] or child[1][0] == rootLeaf or child[1][1] == rootLeaf: return -1
  for leaf in 2 .. 4:
    if int64(leaf) != rootLeaf and child[1][0] != int64(leaf) and child[1][1] != int64(leaf): return -1
  var masks: array[3, int64]
  let universe = (1'u64 shl q) - 1
  for leaf in 0 ..< 3:
    masks[leaf] = input[6 + leaf]
    if masks[leaf] <= 0 or uint64(masks[leaf]) > universe: return -1
  var distance: array[MaxStates, array[MaxStates, int64]]
  for i in 0 ..< q:
    for j in 0 ..< q:
      let value = input[9 + i * q + j]
      if value < 0 or value > 9 or (i == j and value != 0) or (i != j and value == 0): return -1
      distance[i][j] = value
      if value != input[9 + j * q + i]: return -1
  for i in 0 ..< q:
    for j in 0 ..< q:
      for k in 0 ..< q:
        if distance[i][k] > distance[i][j] + distance[j][k]: return -1
  var dp: array[5, array[MaxStates, int64]]
  for node in 0 ..< 5:
    for state in 0 ..< q: dp[node][state] = Inf
  for leaf in 2 .. 4:
    for state in 0 ..< q:
      if (uint64(masks[leaf - 2]) and (1'u64 shl state)) != 0: dp[leaf][state] = 0
  for node in countdown(1, 0):
    for state in 0 ..< q:
      var total = 0'i64
      for slot in 0 ..< 2:
        let descendant = int(child[node][slot])
        var best = Inf
        for other in 0 ..< q:
          let candidate = dp[descendant][other] + distance[state][other]
          if candidate < best: best = candidate
        total += best
      dp[node][state] = total
  var optimum = Inf
  for state in 0 ..< q:
    if dp[0][state] < optimum: optimum = dp[0][state]
  if optimum >= Inf: return -1
  var staged: array[MaxOutputWords, int64]
  staged[0] = optimum
  var words = 2
  if optimum <= threshold:
    for x0 in 0 ..< q:
      for x1 in 0 ..< q:
        for x2 in 0 ..< q:
          if (uint64(masks[0]) and (1'u64 shl x2)) == 0: continue
          for x3 in 0 ..< q:
            if (uint64(masks[1]) and (1'u64 shl x3)) == 0: continue
            for x4 in 0 ..< q:
              if (uint64(masks[2]) and (1'u64 shl x4)) == 0: continue
              let labels = [x0, x1, x2, x3, x4]
              var score = 0'i64
              for node in 0 ..< 2:
                for slot in 0 ..< 2:
                  score += distance[labels[node]][int(child[node][slot])]
              if score == optimum:
                for node in 0 ..< 5:
                  staged[words] = int64(labels[node])
                  inc words
  staged[1] = int64((words - 2) div 5)
  let bytes = words * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  for word in 0 ..< words: storeI64Le(output, word * 8, staged[word])
  int64(bytes)
