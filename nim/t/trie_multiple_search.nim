const MaxOperations = 64
const MaxWordLength = 32
const MaxDistinctWords = 32
const MaxNodeIndex = 1 + MaxWordLength * MaxDistinctWords
const NodeArrayLength = MaxNodeIndex + 1
const MaxValidInputLength = 1 + MaxOperations * (2 + MaxWordLength)
const MaxParseableInputLength = MaxValidInputLength + 1
const RootIndex = 1
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

type
  TrieNode = object
    children: array[26, uint16]
    frequency: uint32
    terminal: bool
  Suggestion = object
    frequency: uint32
    length: uint8
    word: array[MaxWordLength, uint8]

proc letterIndex(code: int64, lowercase: var uint8): int =
  if code >= 65 and code <= 90:
    lowercase = uint8(code + 32)
    return int(code - 65)
  if code >= 97 and code <= 122:
    lowercase = uint8(code)
    return int(code - 97)
  -1

proc hashByte(hash: var uint64, byte: uint8) =
  hash = (hash xor uint64(byte)) *% FnvPrime

proc hashU16(hash: var uint64, value: uint16) =
  for byte in 0 ..< 2: hashByte(hash, uint8((value shr (8 * byte)) and 255'u16))

proc hashU32(hash: var uint64, value: uint32) =
  for byte in 0 ..< 4: hashByte(hash, uint8((value shr (8 * byte)) and 255'u32))

proc hashString(hash: var uint64, word: openArray[uint8], length: int) =
  hashByte(hash, uint8(length))
  for index in 0 ..< length: hashByte(hash, word[index])

proc countDescendants(nodes: var array[NodeArrayLength, TrieNode], node: int): int =
  for letter in 0 ..< 26:
    let child = int(nodes[node].children[letter])
    if child != 0:
      if nodes[child].terminal: inc result
      result += countDescendants(nodes, child)

proc hashDescendants(nodes: var array[NodeArrayLength, TrieNode], node: int,
                     path: var array[MaxWordLength, uint8], pathLength: int,
                     hash: var uint64) =
  for letter in 0 ..< 26:
    let child = int(nodes[node].children[letter])
    if child != 0:
      path[pathLength] = uint8(ord('a') + letter)
      if nodes[child].terminal: hashString(hash, path, pathLength + 1)
      hashDescendants(nodes, child, path, pathLength + 1, hash)

proc compareSuggestions(left, right: Suggestion): int =
  if left.frequency > right.frequency: return 1
  if left.frequency < right.frequency: return -1
  let common = min(int(left.length), int(right.length))
  for index in 0 ..< common:
    if left.word[index] > right.word[index]: return 1
    if left.word[index] < right.word[index]: return -1
  if left.length > right.length: return 1
  if left.length < right.length: return -1
  0

proc offerSuggestion(top: var array[3, Suggestion], count: var int,
                     frequency: uint32, word: openArray[uint8], length: int) =
  var candidate = Suggestion(frequency: frequency, length: uint8(length))
  for index in 0 ..< length: candidate.word[index] = word[index]
  var position = 0
  while position < count and compareSuggestions(candidate, top[position]) <= 0: inc position
  if position >= 3: return
  if count < 3: inc count
  for index in countdown(count - 1, position + 1): top[index] = top[index - 1]
  top[position] = candidate

proc collectTopDescendants(nodes: var array[NodeArrayLength, TrieNode], node: int,
                           path: var array[MaxWordLength, uint8], pathLength: int,
                           top: var array[3, Suggestion], count: var int) =
  for letter in 0 ..< 26:
    let child = int(nodes[node].children[letter])
    if child != 0:
      path[pathLength] = uint8(ord('a') + letter)
      let wordLength = pathLength + 1
      if nodes[child].terminal:
        offerSuggestion(top, count, nodes[child].frequency, path, wordLength)
      collectTopDescendants(nodes, child, path, wordLength, top, count)

proc hashFinalWords(nodes: var array[NodeArrayLength, TrieNode], node: int,
                    path: var array[MaxWordLength, uint8], pathLength: int,
                    hash: var uint64) =
  for letter in 0 ..< 26:
    let child = int(nodes[node].children[letter])
    if child != 0:
      path[pathLength] = uint8(ord('a') + letter)
      let wordLength = pathLength + 1
      if nodes[child].terminal:
        hashString(hash, path, wordLength)
        hashU32(hash, nodes[child].frequency)
      hashFinalWords(nodes, child, path, wordLength, hash)

proc trie_multiple_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "trie_multiple_search".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 0'i64 or input[0] > int64(MaxOperations): return -1
  let operationCount = int(input[0])

  var nodes: array[NodeArrayLength, TrieNode]
  var nextNode = RootIndex + 1
  var wordCount = 0
  var offset = 1
  var hash = FnvOffset
  hashU16(hash, uint16(operationCount))

  for _ in 0 ..< operationCount:
    if offset + 2 > int(length): return -1
    let opcodeValue = input[offset]
    let wordLengthValue = input[offset + 1]
    offset += 2
    if opcodeValue < 0 or opcodeValue > 3 or wordLengthValue < 0 or
        wordLengthValue > int64(MaxWordLength): return -1
    let opcode = int(opcodeValue)
    let wordLength = int(wordLengthValue)
    if opcode == 0 and wordLength == 0: return -1
    if offset + wordLength > int(length): return -1

    var rawWord: array[MaxWordLength, uint8]
    var foldedWord: array[MaxWordLength, uint8]
    for index in 0 ..< wordLength:
      if letterIndex(input[offset + index], foldedWord[index]) < 0: return -1
      rawWord[index] = uint8(input[offset + index])
    offset += wordLength
    hashByte(hash, uint8(opcode))

    var node = RootIndex
    var matchedLength = 0
    while matchedLength < wordLength:
      let letter = int(foldedWord[matchedLength] - uint8(ord('a')))
      let child = int(nodes[node].children[letter])
      if child == 0: break
      node = child
      inc matchedLength
    let fullPath = matchedLength == wordLength
    let exactMatch = fullPath and nodes[node].terminal

    if opcode == 0:
      if not exactMatch:
        if wordCount >= MaxDistinctWords: return -1
        while matchedLength < wordLength:
          let letter = int(foldedWord[matchedLength] - uint8(ord('a')))
          if nextNode > MaxNodeIndex: return -1
          let child = nextNode
          inc nextNode
          nodes[node].children[letter] = uint16(child)
          node = child
          inc matchedLength
        nodes[node].terminal = true
        inc wordCount
    elif opcode == 1:
      let present = if exactMatch: 1'u8 else: 0'u8
      if exactMatch: inc nodes[node].frequency
      hashByte(hash, present)
    else:
      if exactMatch: inc nodes[node].frequency
      var descendantCount = 0
      var top: array[3, Suggestion]
      var topCount = 0
      var path: array[MaxWordLength, uint8]
      for index in 0 ..< matchedLength: path[index] = foldedWord[index]
      if opcode == 2: descendantCount = countDescendants(nodes, node)
      else:
        collectTopDescendants(nodes, node, path, matchedLength, top, topCount)
        descendantCount = topCount
      hashU16(hash, uint16(descendantCount + (if exactMatch: 1 else: 0)))
      if exactMatch: hashString(hash, rawWord, wordLength)
      if opcode == 2: hashDescendants(nodes, node, path, matchedLength, hash)
      else:
        for index in 0 ..< topCount: hashString(hash, top[index].word, int(top[index].length))

  if offset != int(length): return -1
  hashU16(hash, uint16(wordCount))
  var path: array[MaxWordLength, uint8]
  hashFinalWords(nodes, RootIndex, path, 0, hash)
  int64(hash and 0x7fff_ffff_ffff_ffff'u64)
