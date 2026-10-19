const
  MaxWords = 64
  MaxWordLength = 32
  MaxInputValues = 1 + MaxWords * (1 + MaxWordLength)
  MaxNodes = MaxWords * MaxWordLength
  MaxOutputBytes = MaxWords * (MaxWordLength + 1)

type TrieNode = object
  value: uint8
  terminal: bool
  postfix: int
  otherChar: int

proc newNode(nodes: var array[MaxNodes + 1, TrieNode], used: var int, value: uint8): int =
  inc used
  nodes[used].value = value
  used

proc newSuffix(nodes: var array[MaxNodes + 1, TrieNode], used: var int,
               values: ptr UncheckedArray[int64], start, wordLength: int): int =
  result = newNode(nodes, used, uint8(values[start]))
  var current = result
  for offset in 1 ..< wordLength:
    let child = newNode(nodes, used, uint8(values[start + offset]))
    nodes[current].postfix = child
    current = child
  nodes[current].terminal = true

proc insertWord(nodes: var array[MaxNodes + 1, TrieNode], used: var int, current: int,
                values: ptr UncheckedArray[int64], start, wordLength, offset: int) =
  if nodes[current].value == uint8(values[start + offset]):
    if offset + 1 == wordLength:
      nodes[current].terminal = true
    else:
      let next = nodes[current].postfix
      if next == 0:
        nodes[current].postfix = newSuffix(nodes, used, values, start + offset + 1, wordLength - offset - 1)
      else:
        insertWord(nodes, used, next, values, start, wordLength, offset + 1)
  else:
    let next = nodes[current].otherChar
    if next == 0:
      nodes[current].otherChar = newSuffix(nodes, used, values, start + offset, wordLength - offset)
    else:
      insertWord(nodes, used, next, values, start, wordLength, offset)

proc measureOutput(nodes: var array[MaxNodes + 1, TrieNode], current, depth: int, outputLength: var int) =
  if current == 0: return
  if nodes[current].terminal: outputLength += depth + 2
  measureOutput(nodes, nodes[current].postfix, depth + 1, outputLength)
  measureOutput(nodes, nodes[current].otherChar, depth, outputLength)

proc emitOutput(nodes: var array[MaxNodes + 1, TrieNode], current, depth: int,
                prefix: var array[MaxWordLength, uint8], output: ptr UncheckedArray[uint8], position: var int) =
  if current == 0: return
  prefix[depth] = nodes[current].value
  if nodes[current].terminal:
    for i in 0 .. depth:
      output[position] = prefix[i]
      inc position
    output[position] = 10'u8
    inc position
  emitOutput(nodes, nodes[current].postfix, depth + 1, prefix, output, position)
  emitOutput(nodes, nodes[current].otherChar, depth, prefix, output, position)

proc mccat_trie*(input: ptr UncheckedArray[int64], length: csize_t,
                 output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "mccat_trie".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputValues): return -1
  if input[0] < 0 or input[0] > MaxWords.int64: return -1
  let wordCount = int(input[0])
  var starts: array[MaxWords, int]
  var lengths: array[MaxWords, int]
  var position = 1
  for index in 0 ..< wordCount:
    if position >= int(length): return -1
    let wordLengthValue = input[position]
    inc position
    if wordLengthValue < 1 or wordLengthValue > MaxWordLength.int64: return -1
    let wordLength = int(wordLengthValue)
    if wordLength > int(length) - position: return -1
    starts[index] = position
    lengths[index] = wordLength
    for j in 0 ..< wordLength:
      if input[position + j] < 33 or input[position + j] > 126: return -1
    position += wordLength
  if position != int(length): return -1

  var nodes: array[MaxNodes + 1, TrieNode]
  var used = 0
  var root = 0
  for index in 0 ..< wordCount:
    if root == 0: root = newSuffix(nodes, used, input, starts[index], lengths[index])
    else: insertWord(nodes, used, root, input, starts[index], lengths[index], 0)
  var outputLength = 0
  measureOutput(nodes, root, 0, outputLength)
  if outputLength > MaxOutputBytes: return -1
  if outputLength > 0 and (output.isNil or capacity < csize_t(outputLength)): return -2
  if outputLength == 0: return 0
  var prefix: array[MaxWordLength, uint8]
  position = 0
  emitOutput(nodes, root, 0, prefix, output, position)
  int64(position)
