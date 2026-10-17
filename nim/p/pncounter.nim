const MaxNodes = 16
const MaxOperations = 64
const MaxInputLength = 5 + MaxOperations
const MaxOutputWords = 2 * MaxOperations
const PairLeft: array[6, int] = [0, 0, 1, 1, 2, 2]
const PairRight: array[6, int] = [1, 2, 0, 2, 0, 1]

proc append(words: var array[MaxOutputWords, int64], count: var int, value: int64) =
  words[count] = value
  inc count

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc pncounter*(input: ptr UncheckedArray[int64], length: csize_t,
                output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "pncounter".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxNodes or
      input[4] < 0 or input[4] > MaxOperations: return -1

  let nodeCount = int(input[0])
  var ids: array[3, int]
  for counter in 0 ..< 3:
    if input[1 + counter] < 0 or input[1 + counter] >= input[0]: return -1
    ids[counter] = int(input[1 + counter])
  let operationCount = int(input[4])
  if length != csize_t(5 + operationCount): return -1

  var positive: array[3, array[MaxNodes, int64]]
  var negative: array[3, array[MaxNodes, int64]]
  var words: array[MaxOutputWords, int64]
  var wordCount = 0
  var position = 5

  for _ in 0 ..< operationCount:
    let opcode = input[position]
    inc position
    if opcode < 0 or opcode > 20: return -1
    if opcode < 6:
      let counter = int(opcode div 2)
      if opcode mod 2 == 0: inc positive[counter][ids[counter]]
      else: inc negative[counter][ids[counter]]
      append(words, wordCount, opcode)
    elif opcode < 9:
      let counter = int(opcode - 6)
      var value = 0'i64
      for node in 0 ..< nodeCount:
        value += positive[counter][node] - negative[counter][node]
      append(words, wordCount, opcode)
      append(words, wordCount, value)
    elif opcode < 15:
      let pair = int(opcode - 9)
      let target = PairLeft[pair]
      let source = PairRight[pair]
      for node in 0 ..< nodeCount:
        positive[target][node] = max(positive[target][node], positive[source][node])
        negative[target][node] = max(negative[target][node], negative[source][node])
      append(words, wordCount, opcode)
    else:
      let pair = int(opcode - 15)
      let left = PairLeft[pair]
      let right = PairRight[pair]
      var result = 1'i64
      for node in 0 ..< nodeCount:
        if positive[left][node] > positive[right][node] and
            negative[left][node] > negative[right][node]:
          result = 0
          break
      append(words, wordCount, opcode)
      append(words, wordCount, result)

  let outputLength = wordCount * 8
  if output.isNil or outputCapacity < csize_t(outputLength): return -2
  for i in 0 ..< wordCount:
    putI64Le(output, i * 8, words[i])
  int64(outputLength)
