## Apply bounded byte-pair merges with first-seen tie-breaking.
proc bpe_tokenizer*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bpe_tokenizer".} =
  if values == nil or length < 2 or length > 515: return -2
  let mergeCountValue = values[0]
  let byteCountValue = values[1]
  if mergeCountValue < 0 or mergeCountValue > 32 or byteCountValue < 0 or byteCountValue > 512:
    return -2
  let byteCount = int(byteCountValue)
  if int(length) != byteCount + 2: return -2
  var tokens: array[512, int64]
  var nextTokens: array[512, int64]
  for index in 0 ..< byteCount:
    if values[index + 2] < 0 or values[index + 2] > 255: return -2
    tokens[index] = values[index + 2]
  var tokenCount = byteCount
  for step in 0 ..< int(mergeCountValue):
    if tokenCount <= 1: break
    var pairLeft: array[511, int64]
    var pairRight: array[511, int64]
    var pairFrequency: array[511, int64]
    var uniquePairs = 0
    for index in 0 ..< tokenCount - 1:
      var pairIndex = 0
      while pairIndex < uniquePairs and
          (pairLeft[pairIndex] != tokens[index] or pairRight[pairIndex] != tokens[index + 1]):
        inc pairIndex
      if pairIndex == uniquePairs:
        pairLeft[pairIndex] = tokens[index]
        pairRight[pairIndex] = tokens[index + 1]
        pairFrequency[pairIndex] = 1
        inc uniquePairs
      else:
        inc pairFrequency[pairIndex]
    if uniquePairs == 0: break
    var best = 0
    for index in 1 ..< uniquePairs:
      if pairFrequency[index] > pairFrequency[best]: best = index
    if pairFrequency[best] == 1: break
    var nextCount = 0
    var index = 0
    while index < tokenCount:
      if index + 1 < tokenCount and tokens[index] == pairLeft[best] and tokens[index + 1] == pairRight[best]:
        nextTokens[nextCount] = 256 + int64(step)
        inc nextCount
        index += 2
      else:
        nextTokens[nextCount] = tokens[index]
        inc nextCount
        inc index
    for item in 0 ..< nextCount: tokens[item] = nextTokens[item]
    tokenCount = nextCount
  if csize_t(tokenCount * 2) > outputCapacity: return -2
  if tokenCount != 0 and output == nil: return -2
  for index in 0 ..< tokenCount:
    let token = uint16(tokens[index])
    output[index * 2] = uint8(token and 0xff)
    output[index * 2 + 1] = uint8(token shr 8)
  int64(tokenCount)
