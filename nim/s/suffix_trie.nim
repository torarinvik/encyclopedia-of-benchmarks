const MaxTextLength = 64
const MaxPatternLength = 16
const MaxInputLength = 83
const MaxNodes = 1 + MaxTextLength * (MaxTextLength + 1) div 2

proc suffix_trie_search*(input: ptr UncheckedArray[int64], inputLength: csize_t): int64
    {.cdecl, exportc: "suffix_trie_search".} =
  if input == nil or inputLength < 2 or inputLength > MaxInputLength.csize_t: return -1
  let textLengthValue = input[0]
  let patternLengthValue = input[1]
  if textLengthValue < 0 or textLengthValue > MaxTextLength or
      patternLengthValue < 0 or patternLengthValue > MaxPatternLength: return -1
  let textLength = int(textLengthValue)
  let patternLength = int(patternLengthValue)
  if inputLength != csize_t(2 + textLength + patternLength): return -1
  var text: array[MaxTextLength, uint8]
  var pattern: array[MaxPatternLength, uint8]
  for i in 0 ..< textLength:
    let code = input[2 + i]
    if code < 0 or code > 127: return -1
    text[i] = uint8(code)
  for i in 0 ..< patternLength:
    let code = input[2 + textLength + i]
    if code < 0 or code > 127: return -1
    pattern[i] = uint8(code)

  var firstChild: array[MaxNodes, int32]
  var nextSibling: array[MaxNodes, int32]
  var edgeCode: array[MaxNodes, uint8]
  for i in 0 ..< MaxNodes:
    firstChild[i] = -1
    nextSibling[i] = -1
  var nodeCount = 1
  for start in 0 ..< textLength:
    var parent = 0
    for position in start ..< textLength:
      let code = text[position]
      var child = firstChild[parent]
      while child >= 0 and edgeCode[int(child)] != code:
        child = nextSibling[int(child)]
      if child < 0:
        let created = nodeCount
        inc nodeCount
        edgeCode[created] = code
        nextSibling[created] = firstChild[parent]
        firstChild[parent] = int32(created)
        child = int32(created)
      parent = int(child)

  var node = 0
  for i in 0 ..< patternLength:
    var child = firstChild[node]
    while child >= 0 and edgeCode[int(child)] != pattern[i]:
      child = nextSibling[int(child)]
    if child < 0: return 0
    node = int(child)
  1
