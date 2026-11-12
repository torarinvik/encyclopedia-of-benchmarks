type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Run = object
    direction: int64
    count: int64
  Decoded = object
    numerator, denominator: int64
    lowerNum, lowerDen, upperNum, upperDen: int64

const
  MaxQueries = 128
  MaxRuns = 64
  MaxInputLength = 16_384
  MaxOutputWords = 32_768
  MaxComponent = 1_000_000_000'i64

proc gcd(aValue, bValue: int64): int64 =
  var a = aValue
  var b = bValue
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc validFraction(numerator, denominator: int64): bool =
  numerator >= 1 and numerator <= MaxComponent and
    denominator >= 1 and denominator <= MaxComponent and gcd(numerator, denominator) == 1

proc encodePath(numeratorValue, denominatorValue: int64,
    runs: var array[MaxRuns, Run], runCount: var int): bool =
  var numerator = numeratorValue
  var denominator = denominatorValue
  runCount = 0
  while numerator != denominator:
    if runCount >= MaxRuns: return false
    if numerator < denominator:
      let count = (denominator - 1) div numerator
      runs[runCount] = Run(direction: 0, count: count)
      denominator -= count * numerator
    else:
      let count = (numerator - 1) div denominator
      runs[runCount] = Run(direction: 1, count: count)
      numerator -= count * denominator
    inc runCount
  true

proc decodePath(runs: array[MaxRuns, Run], runCount: int, decoded: var Decoded): bool =
  var lowerNum = 0'i64
  var lowerDen = 1'i64
  var upperNum = 1'i64
  var upperDen = 0'i64
  var previous = -1'i64
  for i in 0..<runCount:
    let direction = runs[i].direction
    let count = runs[i].count
    if direction < 0 or direction > 1 or count < 1 or count > MaxComponent or direction == previous:
      return false
    if direction == 0:
      upperNum += count * lowerNum
      upperDen += count * lowerDen
      if upperNum > MaxComponent or upperDen > MaxComponent: return false
    else:
      lowerNum += count * upperNum
      lowerDen += count * upperDen
      if lowerNum > MaxComponent or lowerDen > MaxComponent: return false
    previous = direction
  let numerator = lowerNum + upperNum
  let denominator = lowerDen + upperDen
  if not validFraction(numerator, denominator): return false
  decoded = Decoded(numerator: numerator, denominator: denominator,
    lowerNum: lowerNum, lowerDen: lowerDen, upperNum: upperNum, upperDen: upperDen)
  true

proc commonPrefix(left: array[MaxRuns, Run], leftCount: int,
    right: array[MaxRuns, Run], rightCount: int,
    prefix: var array[MaxRuns, Run]): int =
  var i = 0
  var j = 0
  var leftUsed = 0'i64
  var rightUsed = 0'i64
  result = 0
  while i < leftCount and j < rightCount and left[i].direction == right[j].direction:
    let shared = min(left[i].count - leftUsed, right[j].count - rightUsed)
    prefix[result] = Run(direction: left[i].direction, count: shared)
    inc result
    leftUsed += shared
    rightUsed += shared
    if leftUsed == left[i].count:
      inc i
      leftUsed = 0
    if rightUsed == right[j].count:
      inc j
      rightUsed = 0

proc appendWord(words: var array[MaxOutputWords, int64], wordCount: var int, value: int64): bool =
  if wordCount >= MaxOutputWords: return false
  words[wordCount] = value
  inc wordCount
  true

proc stern_brocot_tree*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "stern_brocot_tree".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let inputLength = int(length)
  let queryCount = input[0]
  if queryCount < 1 or queryCount > int64(MaxQueries): return -1
  var words: array[MaxOutputWords, int64]
  var wordCount = 0
  var position = 1
  for _ in 0..<int(queryCount):
    if position >= inputLength: return -1
    let operation = input[csize_t(position)]
    inc position
    if operation == 0:
      if position + 2 > inputLength: return -1
      let numerator = input[csize_t(position)]
      let denominator = input[csize_t(position + 1)]
      position += 2
      if not validFraction(numerator, denominator): return -1
      var runs: array[MaxRuns, Run]
      var runCount = 0
      if not encodePath(numerator, denominator, runs, runCount) or
          not appendWord(words, wordCount, operation) or
          not appendWord(words, wordCount, int64(runCount)): return -1
      for i in 0..<runCount:
        if not appendWord(words, wordCount, runs[i].direction) or
            not appendWord(words, wordCount, runs[i].count): return -1
    elif operation == 1:
      if position >= inputLength: return -1
      let rawCount = input[csize_t(position)]
      inc position
      if rawCount < 0 or rawCount > int64(MaxRuns) or position + int(rawCount) * 2 > inputLength: return -1
      let runCount = int(rawCount)
      var runs: array[MaxRuns, Run]
      for i in 0..<runCount:
        runs[i] = Run(direction: input[csize_t(position)], count: input[csize_t(position + 1)])
        position += 2
      var decoded: Decoded
      if not decodePath(runs, runCount, decoded) or
          not appendWord(words, wordCount, operation) or
          not appendWord(words, wordCount, decoded.numerator) or
          not appendWord(words, wordCount, decoded.denominator): return -1
    elif operation == 2:
      if position + 4 > inputLength: return -1
      let a = input[csize_t(position)]
      let b = input[csize_t(position + 1)]
      let c = input[csize_t(position + 2)]
      let d = input[csize_t(position + 3)]
      position += 4
      if not validFraction(a, b) or not validFraction(c, d): return -1
      var left, right, prefix: array[MaxRuns, Run]
      var leftCount, rightCount: int
      if not encodePath(a, b, left, leftCount) or not encodePath(c, d, right, rightCount): return -1
      let prefixCount = commonPrefix(left, leftCount, right, rightCount, prefix)
      var decoded: Decoded
      if not decodePath(prefix, prefixCount, decoded) or
          not appendWord(words, wordCount, operation) or
          not appendWord(words, wordCount, decoded.numerator) or
          not appendWord(words, wordCount, decoded.denominator): return -1
    elif operation == 3:
      if position + 3 > inputLength: return -1
      let depth = input[csize_t(position)]
      let numerator = input[csize_t(position + 1)]
      let denominator = input[csize_t(position + 2)]
      position += 3
      if depth < 1 or depth > MaxComponent or not validFraction(numerator, denominator): return -1
      var path, prefix: array[MaxRuns, Run]
      var pathCount = 0
      if not encodePath(numerator, denominator, path, pathCount) or not appendWord(words, wordCount, operation): return -1
      var totalDepth = 0'i64
      for i in 0..<pathCount: totalDepth += path[i].count
      if depth > totalDepth:
        if not appendWord(words, wordCount, -1): return -1
      else:
        var remaining = depth
        var prefixCount = 0
        for i in 0..<pathCount:
          if remaining == 0: break
          let take = min(remaining, path[i].count)
          prefix[prefixCount] = Run(direction: path[i].direction, count: take)
          inc prefixCount
          remaining -= take
        var decoded: Decoded
        if not decodePath(prefix, prefixCount, decoded) or
            not appendWord(words, wordCount, decoded.numerator) or
            not appendWord(words, wordCount, decoded.denominator): return -1
    elif operation == 4:
      if position + 2 > inputLength: return -1
      let numerator = input[csize_t(position)]
      let denominator = input[csize_t(position + 1)]
      position += 2
      if not validFraction(numerator, denominator): return -1
      var path: array[MaxRuns, Run]
      var pathCount = 0
      if not encodePath(numerator, denominator, path, pathCount): return -1
      var decoded: Decoded
      if not decodePath(path, pathCount, decoded) or
          not appendWord(words, wordCount, operation) or
          not appendWord(words, wordCount, decoded.lowerNum) or
          not appendWord(words, wordCount, decoded.lowerDen) or
          not appendWord(words, wordCount, decoded.upperNum) or
          not appendWord(words, wordCount, decoded.upperDen): return -1
    else:
      return -1
  if position != inputLength: return -1
  let byteCount = wordCount * 8
  if outputCapacity < csize_t(byteCount) or output == nil: return -2
  for i in 0..<wordCount:
    let bits = cast[uint64](words[i])
    for byte in 0..<8:
      output[csize_t(i * 8 + byte)] = uint8((bits shr (byte * 8)) and 255'u64)
  queryCount
