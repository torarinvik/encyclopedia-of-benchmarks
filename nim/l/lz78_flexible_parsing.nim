const MaxText = 32
const MaxDict = MaxText + 1
const MaxInput = 34
const MaxOutput = 16 * MaxText
type Words = array[MaxDict, array[MaxText, uint8]]
type Lengths = array[MaxDict, int]

proc putU64(output: var array[MaxOutput, uint8], offset: int, value: uint64) =
  for i in 0 ..< 8: output[offset + i] = uint8((value shr (8 * i)) and 0xff'u64)

proc wordMatches(words: Words, lengths: Lengths, id: int, text: array[MaxText, uint8], n, pos: int): bool =
  if pos + lengths[id] > n: return false
  for i in 0 ..< lengths[id]:
    if words[id][i] != text[pos + i]: return false
  true

proc findWord(words: Words, lengths: Lengths, count: int, phrase: array[MaxText, uint8], len: int): int =
  for id in 1 ..< count:
    if lengths[id] != len: continue
    var same = true
    for i in 0 ..< len:
      if words[id][i] != phrase[i]: same = false
    if same: return id
  count

proc longestMatch(words: Words, lengths: Lengths, count: int, extra: array[MaxText, uint8],
                  extraLen: int, hasExtra: bool, text: array[MaxText, uint8], n, pos: int): int =
  var best = 0
  for id in 1 ..< count:
    if lengths[id] > best and wordMatches(words, lengths, id, text, n, pos): best = lengths[id]
  if hasExtra and extraLen > best and pos + extraLen <= n:
    var same = true
    for i in 0 ..< extraLen:
      if extra[i] != text[pos + i]: same = false
    if same: best = extraLen
  best

proc lz78_flexible_parsing*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "lz78_flexible_parsing".} =
  if input.isNil or inputLength < 1 or inputLength > MaxInput.csize_t: return -1
  if input[0] < 0 or input[0] > MaxText: return -1
  let n = int(input[0])
  if int(inputLength) != n + 1: return -1
  var text: array[MaxText, uint8]
  for i in 0 ..< n:
    if input[i + 1] < 32 or input[i + 1] > 126: return -1
    text[i] = uint8(input[i + 1])
  var words: Words
  var lengths: Lengths
  var parents: array[MaxText, int64]
  var symbols: array[MaxText, int64]
  var count = 1
  var tokenCount = 0
  var pos = 0
  while pos < n:
    var finalId = count
    for id in 1 ..< count:
      if lengths[id] == n - pos:
        var same = true
        for i in 0 ..< n - pos:
          if words[id][i] != text[pos + i]: same = false
        if same: finalId = id; break
    if finalId != count:
      parents[tokenCount] = int64(finalId); symbols[tokenCount] = 0; inc tokenCount; pos = n; break
    var have = false
    var bestParent = 0
    var bestLen = 0
    var bestNext = 0
    var bestSymbol = 0'u8
    var bestNew = false
    var bestWord: array[MaxText, uint8]
    for parent in 0 ..< count:
      if not wordMatches(words, lengths, parent, text, n, pos): continue
      let prefixLen = lengths[parent]
      let symbolPos = pos + prefixLen
      if symbolPos >= n: continue
      let phraseLen = prefixLen + 1
      var phrase: array[MaxText, uint8]
      for i in 0 ..< prefixLen: phrase[i] = words[parent][i]
      phrase[prefixLen] = text[symbolPos]
      let isNew = findWord(words, lengths, count, phrase, phraseLen) == count
      let nextPos = pos + phraseLen
      let nextMatch = longestMatch(words, lengths, count, phrase, phraseLen, isNew, text, n, nextPos)
      let advancement = phraseLen + nextMatch
      if not have or advancement > bestNext or
        (advancement == bestNext and phraseLen > bestLen) or
        (advancement == bestNext and phraseLen == bestLen and parent < bestParent):
        have = true; bestParent = parent; bestLen = phraseLen; bestNext = advancement
        bestSymbol = text[symbolPos]; bestNew = isNew; bestWord = phrase
    if not have: return -1
    parents[tokenCount] = int64(bestParent); symbols[tokenCount] = int64(bestSymbol); inc tokenCount
    if bestNew: words[count] = bestWord; lengths[count] = bestLen; inc count
    pos += bestLen
  let outputBytes = tokenCount * 16
  var staged: array[MaxOutput, uint8]
  for i in 0 ..< tokenCount:
    putU64(staged, 16 * i, uint64(parents[i]))
    putU64(staged, 16 * i + 8, uint64(symbols[i]))
  if output.isNil or int(capacity) < outputBytes: return -2
  for i in 0 ..< outputBytes: output[i] = staged[i]
  int64(outputBytes)
