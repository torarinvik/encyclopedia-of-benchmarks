const MaxBits = 63
const MaxBlocks = 8
const MaxQueries = 16
const MaxInput = 35
const MaxOutputBytes = 128

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc rank_select_bitstring*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rank_select_bitstring".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nValue, packedValue, queryValue = input[0], input[1], input[2]
  if nValue < 1 or nValue > MaxBits or packedValue < 0 or queryValue < 0 or queryValue > MaxQueries: return -1
  let n, queries = int(nValue), int(queryValue)
  let bits = uint64(packedValue)
  if (bits shr n) != 0 or int(length) != 3 + 2 * queries: return -1
  let blockCount = (n + 7) div 8
  var prefix: array[MaxBlocks + 1, int64]
  for block in 0 ..< blockCount:
    prefix[block + 1] = prefix[block]
    let endPos = min(n, 8 * block + 8)
    for pos in 8 * block ..< endPos: prefix[block + 1] += int64((bits shr pos) and 1)
  var answers: array[MaxQueries, int64]
  for query in 0 ..< queries:
    let op = input[3 + 2 * query]
    let indexValue = input[4 + 2 * query]
    if (op != 0 and op != 1) or indexValue < 1 or
        (if op == 0: indexValue > nValue else: indexValue > MaxBits + 1): return -1
    let index = int(indexValue)
    if op == 0:
      let fullBlocks = index div 8
      let remainder = index mod 8
      var answer = prefix[fullBlocks]
      for pos in 8 * fullBlocks ..< 8 * fullBlocks + remainder: answer += int64((bits shr pos) and 1)
      answers[query] = answer
    else:
      var block = 0
      while block < blockCount and prefix[block + 1] < int64(index): inc block
      answers[query] = -1
      if block < blockCount:
        var remaining = index - int(prefix[block])
        let endPos = min(n, 8 * block + 8)
        for pos in 8 * block ..< endPos:
          if ((bits shr pos) and 1) != 0:
            dec remaining
            if remaining == 0:
              answers[query] = int64(pos + 1)
              break
  let outputBytes = 8 * queries
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  for query in 0 ..< queries: storeI64Le(addr staged[0], 8 * query, answers[query])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
