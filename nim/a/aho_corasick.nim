const MaxPatterns = 16
const MaxPatternLength = 32
const MaxTextLength = 256
const MaxNodes = 1 + MaxPatterns * MaxPatternLength
const Alphabet = 128

proc aho_corasick*(input: ptr UncheckedArray[int64], length: csize_t,
                   output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "aho_corasick".} =
  if input == nil or length < 3 or input[0] < 1 or input[0] > MaxPatterns or input[1] < 0 or input[1] > MaxTextLength: return -1
  let patternCount = int(input[0])
  if int(length) < 2 + patternCount: return -1
  var starts: array[MaxPatterns, int]
  var textStart = 2 + patternCount
  for p in 0 ..< patternCount:
    if input[2 + p] < 1 or input[2 + p] > MaxPatternLength: return -1
    let size = int(input[2 + p])
    if textStart + size > int(length): return -1
    starts[p] = textStart
    for i in 0 ..< size:
      if input[starts[p] + i] < 1 or input[starts[p] + i] > 127: return -1
    for q in 0 ..< p:
      if int(input[2 + q]) != size: continue
      var i = 0
      while i < size and input[starts[q] + i] == input[starts[p] + i]: inc i
      if i == size: return -1
    textStart += size
  let textLength = int(input[1])
  if textStart + textLength != int(length): return -1
  for i in 0 ..< textLength:
    if input[textStart + i] < 1 or input[textStart + i] > 127: return -1
  let outputSize = patternCount * 8
  if int(outputCapacity) < outputSize or output == nil: return -2

  var next: array[MaxNodes, array[Alphabet, int32]]
  for n in 0 ..< MaxNodes:
    for ch in 0 ..< Alphabet: next[n][ch] = -1
  var failure: array[MaxNodes, int]
  var terminal: array[MaxNodes, int]
  var queue: array[MaxNodes, int]
  for n in 0 ..< MaxNodes: terminal[n] = -1
  var nodes = 1
  for p in 0 ..< patternCount:
    var state = 0
    for i in 0 ..< int(input[2 + p]):
      let ch = int(input[starts[p] + i])
      if next[state][ch] == -1:
        next[state][ch] = int32(nodes)
        inc nodes
      state = int(next[state][ch])
    terminal[state] = p
  var head = 0
  var tail = 0
  for ch in 1 ..< Alphabet:
    if next[0][ch] != -1:
      queue[tail] = int(next[0][ch]); inc tail
  while head < tail:
    let state = queue[head]; inc head
    for ch in 1 ..< Alphabet:
      let child = int(next[state][ch])
      if child < 0: continue
      var suffix = failure[state]
      while suffix != 0 and next[suffix][ch] == -1: suffix = failure[suffix]
      if next[suffix][ch] != -1: suffix = int(next[suffix][ch])
      failure[child] = suffix
      queue[tail] = child; inc tail
  var counts: array[MaxPatterns, int64]
  var state = 0
  for i in 0 ..< textLength:
    let ch = int(input[textStart + i])
    while state != 0 and next[state][ch] == -1: state = failure[state]
    if next[state][ch] != -1: state = int(next[state][ch])
    var matched = state
    while matched != 0:
      if terminal[matched] >= 0: inc counts[terminal[matched]]
      matched = failure[matched]
  for p in 0 ..< patternCount:
    for b in 0 ..< 8: output[p * 8 + b] = uint8((counts[p] shr (8 * b)) and 255)
  int64(outputSize)
