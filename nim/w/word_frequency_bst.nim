const MaxInputBytes = 256
const MaxTokenBytes = 45
const MaxUniqueWords = 128
const MaxOutputBytes = 896

type WordNode = object
  word: array[MaxTokenBytes + 1, uint8]
  wordLength: int
  frequency: uint64
  left: int
  right: int

proc asciiAlpha(value: int): bool =
  (value >= ord('A') and value <= ord('Z')) or (value >= ord('a') and value <= ord('z'))

proc word_frequency_bst*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "word_frequency_bst".} =
  if input == nil or length < 1 or length > csize_t(MaxInputBytes + 2): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxInputBytes: return -1
  let textLength = int(nValue)
  if length != csize_t(textLength + 1): return -1
  for i in 0 ..< textLength:
    if input[i + 1] < 0 or input[i + 1] > 127: return -1

  var nodes: array[MaxUniqueWords, WordNode]
  for i in 0 ..< MaxUniqueWords:
    nodes[i].left = -1
    nodes[i].right = -1
  var used = 0
  var root = -1
  var token: array[MaxTokenBytes + 1, uint8]
  var tokenLength = 0
  for position in 0 .. textLength:
    let byte = if position < textLength: int(input[position + 1]) else: -1
    if asciiAlpha(byte):
      if tokenLength >= MaxTokenBytes: return -1
      token[tokenLength] = uint8(if byte >= ord('A') and byte <= ord('Z'): byte + 32 else: byte)
      inc tokenLength
    elif (byte == ord('\'') or byte == ord('-')) and tokenLength > 0 and asciiAlpha(int(token[tokenLength - 1])):
      if tokenLength >= MaxTokenBytes: return -1
      token[tokenLength] = uint8(byte)
      inc tokenLength
    else:
      if tokenLength > 0:
        if token[tokenLength - 1] == uint8(ord('-')): dec tokenLength
        if tokenLength > 0:
          if root < 0:
            if used >= MaxUniqueWords: return -1
            root = used
            for j in 0 ..< tokenLength: nodes[used].word[j] = token[j]
            nodes[used].word[tokenLength] = 0
            nodes[used].wordLength = tokenLength
            nodes[used].frequency = 1
            inc used
          else:
            var current = root
            while true:
              let common = min(tokenLength, nodes[current].wordLength)
              var order = 0
              for j in 0 ..< common:
                if token[j] < nodes[current].word[j]:
                  order = -1
                  break
                if token[j] > nodes[current].word[j]:
                  order = 1
                  break
              if order == 0:
                if tokenLength < nodes[current].wordLength: order = -1
                elif tokenLength > nodes[current].wordLength: order = 1
              if order == 0:
                inc nodes[current].frequency
                break
              let child = if order < 0: nodes[current].left else: nodes[current].right
              if child < 0:
                if used >= MaxUniqueWords: return -1
                let newNode = used
                for j in 0 ..< tokenLength: nodes[newNode].word[j] = token[j]
                nodes[newNode].word[tokenLength] = 0
                nodes[newNode].wordLength = tokenLength
                nodes[newNode].frequency = 1
                nodes[newNode].left = -1
                nodes[newNode].right = -1
                if order < 0: nodes[current].left = newNode
                else: nodes[current].right = newNode
                inc used
                break
              current = child
        tokenLength = 0

  var outputBytes: array[MaxOutputBytes, uint8]
  var stack: array[MaxUniqueWords, int]
  var top = 0
  var written = 0
  var current = root
  while current >= 0 or top > 0:
    while current >= 0:
      if top >= MaxUniqueWords: return -1
      stack[top] = current
      inc top
      current = nodes[current].left
    dec top
    current = stack[top]
    for i in 0 ..< nodes[current].wordLength:
      if written >= MaxOutputBytes: return -1
      outputBytes[written] = nodes[current].word[i]
      inc written
    if written + 1 >= MaxOutputBytes: return -1
    outputBytes[written] = uint8(ord('\t'))
    inc written
    var reversed: array[20, uint8]
    var digits = 0
    var frequency = nodes[current].frequency
    while true:
      reversed[digits] = uint8(ord('0') + int(frequency mod 10))
      inc digits
      frequency = frequency div 10
      if frequency == 0: break
    while digits > 0:
      dec digits
      if written >= MaxOutputBytes: return -1
      outputBytes[written] = reversed[digits]
      inc written
    if written >= MaxOutputBytes: return -1
    outputBytes[written] = uint8(ord('\n'))
    inc written
    current = nodes[current].right

  if output == nil or capacity < csize_t(written): return -2
  for i in 0 ..< written: output[i] = outputBytes[i]
  int64(written)
