const
  MaxN = 16
  MaxStates = 1 shl MaxN
  MaxOutputWords = 2 + MaxN
  MaxInputValues = 2 + 3 * (MaxN * (MaxN - 1) div 2) + 1
  MaxWeight = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc general_weighted_matching*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "general_weighted_matching".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nv = input[0]
  let mv = input[1]
  if nv < 1 or nv > MaxN or mv < 0 or mv > nv * (nv - 1) div 2: return -1
  let n = int(nv)
  let m = int(mv)
  if length != csize_t(2 + 3 * m): return -1

  var weights: array[MaxN, array[MaxN, int64]]
  var present: array[MaxN, array[MaxN, bool]]
  var cursor = 2
  for _ in 0 ..< m:
    let uValue = input[cursor]
    let vValue = input[cursor + 1]
    let edgeWeight = input[cursor + 2]
    cursor += 3
    if uValue < 0 or uValue >= nv or vValue < 0 or vValue >= nv or
        uValue == vValue or edgeWeight < 1 or edgeWeight > MaxWeight: return -1
    let u = int(uValue)
    let v = int(vValue)
    if present[u][v]: return -1
    present[u][v] = true
    present[v][u] = true
    weights[u][v] = edgeWeight
    weights[v][u] = edgeWeight

  var dp: array[MaxStates, int64]
  let stateCount = 1 shl n
  for mask in 1 ..< stateCount:
    let bit = mask and -mask
    var vertex = 0
    while (bit shr vertex) != 1: inc vertex
    let remainder = mask xor bit
    dp[mask] = dp[remainder]
    for partner in vertex + 1 ..< n:
      let partnerBit = 1 shl partner
      if (remainder and partnerBit) == 0 or not present[vertex][partner]: continue
      let candidate = weights[vertex][partner] + dp[remainder xor partnerBit]
      if candidate > dp[mask]: dp[mask] = candidate

  var words: array[MaxOutputWords, int64]
  var pairCount = 0
  var mask = stateCount - 1
  while mask != 0:
    let bit = mask and -mask
    var vertex = 0
    while (bit shr vertex) != 1: inc vertex
    let remainder = mask xor bit
    if dp[mask] == dp[remainder]:
      mask = remainder
      continue
    var selected = -1
    for partner in vertex + 1 ..< n:
      let partnerBit = 1 shl partner
      if (remainder and partnerBit) != 0 and present[vertex][partner] and
          weights[vertex][partner] + dp[remainder xor partnerBit] == dp[mask]:
        selected = partner
        break
    if selected < 0: return -1
    words[2 + 2 * pairCount] = int64(vertex)
    words[3 + 2 * pairCount] = int64(selected)
    inc pairCount
    mask = remainder xor (1 shl selected)

  words[0] = int64(pairCount)
  words[1] = dp[stateCount - 1]
  let outputWords = 2 + 2 * pairCount
  let outputBytes = 8 * outputWords
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for word in 0 ..< outputWords:
    storeI64Le(output, 8 * word, words[word])
  int64(outputBytes)
