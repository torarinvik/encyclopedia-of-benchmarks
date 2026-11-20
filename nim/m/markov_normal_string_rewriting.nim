const MaxRules = 8
const MaxSteps = 32
const MaxWord = 64
const MaxInput = 204

proc markov_normal_string_rewriting*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "markov_normal_string_rewriting".} =
  if input.isNil or length < 3 or length > MaxInput: return -1
  if input[0] < 0 or input[0] > MaxRules or input[1] < 0 or input[1] > MaxSteps or input[2] < 0 or input[2] > 48: return -1
  let ruleCount = int(input[0])
  let budget = int(input[1])
  var wordLen = int(input[2])
  if int(length) < 3 + wordLen: return -1
  var word: array[MaxWord, int64]
  var cursor = 3
  for i in 0 ..< wordLen:
    if input[cursor] < 0 or input[cursor] > 25: return -1
    word[i] = input[cursor]
    inc cursor
  var kinds: array[MaxRules, int64]
  var leftLens, rightLens: array[MaxRules, int]
  var leftSide, rightSide: array[MaxRules * 8, int64]
  for r in 0 ..< ruleCount:
    if cursor + 3 > int(length): return -1
    let kind = input[cursor]
    let lhsLen = input[cursor + 1]
    let rhsLen = input[cursor + 2]
    cursor += 3
    if (kind != 0 and kind != 1) or lhsLen < 1 or lhsLen > 8 or rhsLen < 0 or rhsLen > 8: return -1
    let leftCount = int(lhsLen)
    let rightCount = int(rhsLen)
    if cursor + leftCount + rightCount > int(length): return -1
    kinds[r] = kind
    leftLens[r] = leftCount
    rightLens[r] = rightCount
    for j in 0 ..< leftCount:
      if input[cursor] < 0 or input[cursor] > 25: return -1
      leftSide[r * 8 + j] = input[cursor]
      inc cursor
    for j in 0 ..< rightCount:
      if input[cursor] < 0 or input[cursor] > 25: return -1
      rightSide[r * 8 + j] = input[cursor]
      inc cursor
  if cursor != int(length): return -1

  var rewrites = 0
  var halt = 0
  while true:
    var selected = ruleCount
    var offset = 0
    for r in 0 ..< ruleCount:
      if selected != ruleCount: break
      let lhsLen = leftLens[r]
      if lhsLen > wordLen: continue
      for at in 0 .. wordLen - lhsLen:
        var matches = true
        for j in 0 ..< lhsLen:
          if word[at + j] != leftSide[r * 8 + j]:
            matches = false
            break
        if matches:
          selected = r
          offset = at
          break
    if selected == ruleCount:
      halt = 0
      break
    if rewrites == budget:
      halt = 2
      break
    let lhsLen = leftLens[selected]
    let rhsLen = rightLens[selected]
    let newLen = wordLen - lhsLen + rhsLen
    if newLen > MaxWord: return -3
    var next: array[MaxWord, int64]
    var out = 0
    for i in 0 ..< offset:
      next[out] = word[i]
      inc out
    for i in 0 ..< rhsLen:
      next[out] = rightSide[selected * 8 + i]
      inc out
    for i in offset + lhsLen ..< wordLen:
      next[out] = word[i]
      inc out
    word = next
    wordLen = newLen
    inc rewrites
    if kinds[selected] == 1:
      halt = 1
      break

  let required = 3 + wordLen
  if output.isNil or int(capacity) < required: return -2
  output[0] = uint8(halt)
  output[1] = uint8(rewrites)
  output[2] = uint8(wordLen)
  for i in 0 ..< wordLen: output[3 + i] = uint8(word[i])
  int64(required)
