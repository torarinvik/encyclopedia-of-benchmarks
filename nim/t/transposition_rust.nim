const MaxKeys = 4
const MaxKeyLength = 32
const MaxMessageLength = 256
const MaxInputLength = 3 + MaxKeys + MaxKeys * MaxKeyLength + MaxMessageLength
const MaxOutputLength = 2 * MaxMessageLength - 1
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64
const Low63Mask = 0x7fff_ffff_ffff_ffff'u64

proc isAsciiLetter(value: int64): bool =
  (value >= ord('A').int64 and value <= ord('Z').int64) or
    (value >= ord('a').int64 and value <= ord('z').int64)

proc normalize(input: openArray[uint8], length: int,
               output: var openArray[uint8]): int =
  result = 0
  for index in 0 ..< length:
    var ch = input[index]
    if ch >= uint8(ord('a')) and ch <= uint8(ord('z')):
      ch = ch - uint8(ord('a') - ord('A'))
    if ch >= uint8(ord('A')) and ch <= uint8(ord('Z')):
      output[result] = ch
      inc result

proc columnOrder(key: openArray[uint8], keyLength: int,
                 order: var array[MaxKeyLength, int]) =
  for index in 0 ..< keyLength: order[index] = index
  for index in 1 ..< keyLength:
    let column = order[index]
    var position = index
    while position > 0 and key[order[position - 1]] > key[column]:
      order[position] = order[position - 1]
      dec position
    order[position] = column

proc encryptRound(text: openArray[uint8], textLength: int,
                  key: openArray[uint8], keyLength: int,
                  output: var openArray[uint8]): int =
  var order: array[MaxKeyLength, int]
  var columns: array[MaxMessageLength, uint8]
  columnOrder(key, keyLength, order)
  var orderedLength = 0
  for rank in 0 ..< keyLength:
    var position = order[rank]
    while position < textLength:
      columns[orderedLength] = text[position]
      inc orderedLength
      position += keyLength
  let groupSize = (textLength + keyLength - 1) div keyLength
  result = 0
  for index in 0 ..< orderedLength:
    output[result] = columns[index]
    inc result
    if (index + 1) mod groupSize == 0 and index + 1 < orderedLength:
      output[result] = uint8(ord(' '))
      inc result

proc decryptRound(text: openArray[uint8], textLength: int,
                  key: openArray[uint8], keyLength: int,
                  output: var openArray[uint8]): int =
  var order: array[MaxKeyLength, int]
  var columns: array[MaxKeyLength, array[MaxMessageLength, uint8]]
  var columnLengths: array[MaxKeyLength, int]
  columnOrder(key, keyLength, order)
  let shortLength = textLength div keyLength
  let longerColumns = textLength mod keyLength
  var cursor = 0
  for rank in 0 ..< keyLength:
    let column = order[rank]
    let columnLength = shortLength + (if column < longerColumns: 1 else: 0)
    columnLengths[column] = columnLength
    for row in 0 ..< columnLength:
      columns[column][row] = text[cursor]
      inc cursor
  let rowCount = shortLength + (if longerColumns > 0: 1 else: 0)
  result = 0
  for row in 0 ..< rowCount:
    for column in 0 ..< keyLength:
      if row < columnLengths[column]:
        output[result] = columns[column][row]
        inc result

proc feedValue(hash: uint64, value: uint64, width: int): uint64 =
  result = hash
  var bits = value
  for _ in 0 ..< width:
    result = (result xor (bits and 255'u64)) * FnvPrime
    bits = bits shr 8

proc transposition_rust*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "transposition_rust".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let mode = input[0]
  let keyCountValue = input[1]
  if (mode != 0 and mode != 1) or keyCountValue < 1 or keyCountValue > MaxKeys: return -1
  let keyCount = int(keyCountValue)

  var keys: array[MaxKeys, array[MaxKeyLength, uint8]]
  var keyLengths: array[MaxKeys, int]
  var longestKey = 0
  var cursor = 2
  for keyIndex in 0 ..< keyCount:
    if cursor >= int(length): return -1
    let keyLengthValue = input[cursor]
    inc cursor
    if keyLengthValue < 1 or keyLengthValue > MaxKeyLength: return -1
    let keyLength = int(keyLengthValue)
    if keyLength > int(length) - cursor: return -1
    for index in 0 ..< keyLength:
      let value = input[cursor + index]
      if not isAsciiLetter(value): return -1
      var ch = uint8(value)
      if ch >= uint8(ord('a')) and ch <= uint8(ord('z')):
        ch = ch - uint8(ord('a') - ord('A'))
      keys[keyIndex][index] = ch
    cursor += keyLength
    keyLengths[keyIndex] = keyLength
    longestKey = max(longestKey, keyLength)

  if cursor >= int(length): return -1
  let messageLengthValue = input[cursor]
  inc cursor
  if messageLengthValue < 1 or messageLengthValue > MaxMessageLength: return -1
  let messageLength = int(messageLengthValue)
  if messageLength != int(length) - cursor: return -1
  var message: array[MaxMessageLength, uint8]
  for index in 0 ..< messageLength:
    let value = input[cursor + index]
    if value < 0 or value > 127: return -1
    message[index] = uint8(value)

  var current: array[MaxOutputLength, uint8]
  var filtered: array[MaxMessageLength, uint8]
  var next: array[MaxOutputLength, uint8]
  var currentLength = normalize(message, messageLength, current)
  if currentLength < longestKey: return -1
  for pass in 0 ..< keyCount:
    let keyIndex = if mode == 0: pass else: keyCount - 1 - pass
    let filteredLength = normalize(current, currentLength, filtered)
    let nextLength = if mode == 0:
      encryptRound(filtered, filteredLength, keys[keyIndex], keyLengths[keyIndex], next)
    else:
      decryptRound(filtered, filteredLength, keys[keyIndex], keyLengths[keyIndex], next)
    for index in 0 ..< nextLength: current[index] = next[index]
    currentLength = nextLength

  var hash = feedValue(FnvOffset, uint64(currentLength), 8)
  for index in 0 ..< currentLength:
    hash = feedValue(hash, uint64(current[index]), 4)
  int64(hash and Low63Mask)
