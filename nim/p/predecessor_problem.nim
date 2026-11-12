type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

const
  MaxN = 4096
  MaxWords = 64
  MaxQueries = 512
  MaxInputLength = 1090
  MaxOutputBytes = 4096

proc findNext(words: openArray[uint64], n, key: int): int64 =
  let firstWord = key div 64
  for word in firstWord..<words.len:
    let firstBit = if word == firstWord: key mod 64 else: 0
    var candidates = words[word]
    if firstBit != 0: candidates = candidates and (high(uint64) shl firstBit)
    if candidates == 0: continue
    let endBit = if (word + 1) * 64 < n: 64 else: n - word * 64
    for bit in firstBit..<endBit:
      if ((candidates shr bit) and 1'u64) != 0: return int64(word * 64 + bit)
  -1

proc findPrevious(words: openArray[uint64], n, key: int): int64 =
  let firstWord = key div 64
  var word = firstWord + 1
  while word > 0:
    dec word
    let validBits = if (word + 1) * 64 > n: n - word * 64 else: 64
    let requestedEnd = if word == firstWord: key mod 64 + 1 else: validBits
    let endBit = min(requestedEnd, validBits)
    let mask = if endBit == 64: high(uint64) else: (1'u64 shl endBit) - 1
    let candidates = words[word] and mask
    if candidates == 0: continue
    var bit = endBit
    while bit > 0:
      dec bit
      if ((candidates shr bit) and 1'u64) != 0: return int64(word * 64 + bit)
  -1

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0..<8:
    output[csize_t(offset + byte)] = uint8(bits and 255'u64)
    bits = bits shr 8

proc predecessor_problem*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64 {.cdecl, exportc: "predecessor_problem".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let queryValue = input[1]
  if nValue < 1 or nValue > MaxN or queryValue < 0 or queryValue > MaxQueries: return -1
  let n = int(nValue)
  let queries = int(queryValue)
  let wordCount = (n + 63) div 64
  let operationOffset = 2 + wordCount
  if int(length) != operationOffset + 2 * queries: return -1
  var words: array[MaxWords, uint64]
  for word in 0..<wordCount: words[word] = cast[uint64](input[csize_t(2 + word)])
  let tailBits = n mod 64
  if tailBits != 0 and (words[wordCount - 1] shr tailBits) != 0: return -1
  for query in 0..<queries:
    let operation = input[csize_t(operationOffset + 2 * query)]
    let key = input[csize_t(operationOffset + 2 * query + 1)]
    if operation < 0 or operation > 4 or key < 0 or key >= nValue: return -1
  var answers: array[MaxQueries, int64]
  var answerCount = 0
  for query in 0..<queries:
    let operation = input[csize_t(operationOffset + 2 * query)]
    let key = int(input[csize_t(operationOffset + 2 * query + 1)])
    let word = key div 64
    let mask = 1'u64 shl (key mod 64)
    if operation == 0: words[word] = words[word] or mask
    elif operation == 1: words[word] = words[word] and not mask
    elif operation == 2:
      answers[answerCount] = if (words[word] and mask) != 0: 1 else: 0
      inc answerCount
    elif operation == 3:
      answers[answerCount] = findNext(words.toOpenArray(0, wordCount - 1), n, key)
      inc answerCount
    else:
      answers[answerCount] = findPrevious(words.toOpenArray(0, wordCount - 1), n, key)
      inc answerCount
  let outputBytes = answerCount * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  for index in 0..<answerCount: storeI64Le(cast[U8Output](addr staged[0]), index * 8, answers[index])
  for byte in 0..<outputBytes: output[csize_t(byte)] = staged[byte]
  int64(outputBytes)
