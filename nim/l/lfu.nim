const MinCapacity = 2
const MaxCapacity = 16
const MaxOperations = 32
const MaxInputLength = 2 + 3 * MaxOperations
const MaxOutputWords = 3 * MaxOperations

proc moveToFront(keys: var array[MaxCapacity, int32],
                 values: var array[MaxCapacity, int32], index: int) =
  let key = keys[index]
  let value = values[index]
  var i = index
  while i > 0:
    keys[i] = keys[i - 1]
    values[i] = values[i - 1]
    dec i
  keys[0] = key
  values[0] = value

proc append(words: var array[MaxOutputWords, int64], count: var int, value: int64) =
  words[count] = value
  inc count

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc lfu*(input: ptr UncheckedArray[int64], length: csize_t,
          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lfu".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  if input[0] < MinCapacity or input[0] > MaxCapacity or
      input[1] < 0 or input[1] > MaxOperations: return -1

  let cacheCapacity = int(input[0])
  let operationCount = int(input[1])
  var keys: array[MaxCapacity, int32]
  var values: array[MaxCapacity, int32]
  var size = 0
  var words: array[MaxOutputWords, int64]
  var wordCount = 0
  var position = 2

  for _ in 0 ..< operationCount:
    if position >= int(length): return -1
    let opcode = input[position]
    inc position
    if opcode == 0:
      if position + 1 >= int(length): return -1
      let keyArg = input[position]
      let valueArg = input[position + 1]
      position += 2
      if keyArg < int64(low(int32)) or keyArg > int64(high(int32)) or
          valueArg < int64(low(int32)) or valueArg > int64(high(int32)): return -1
      let key = int32(keyArg)
      var index = 0
      while index < size and keys[index] != key: inc index
      if index < size:
        # The pinned Put mutates a copied item; the old value remains.
        moveToFront(keys, values, index)
      else:
        if size == cacheCapacity: dec size
        var i = size
        while i > 0:
          keys[i] = keys[i - 1]
          values[i] = values[i - 1]
          dec i
        keys[0] = key
        values[0] = int32(valueArg)
        inc size
      append(words, wordCount, 0)
    elif opcode == 1:
      if position >= int(length): return -1
      let keyArg = input[position]
      inc position
      if keyArg < int64(low(int32)) or keyArg > int64(high(int32)): return -1
      let key = int32(keyArg)
      var index = 0
      while index < size and keys[index] != key: inc index
      append(words, wordCount, 1)
      if index == size:
        append(words, wordCount, 1)
        append(words, wordCount, 0)
      else:
        let value = values[index]
        moveToFront(keys, values, index)
        append(words, wordCount, 0)
        append(words, wordCount, int64(value))
    else:
      return -1

  if position != int(length) or wordCount > MaxOutputWords: return -1
  let outputLength = wordCount * 8
  if output.isNil or outputCapacity < csize_t(outputLength): return -2
  for i in 0 ..< wordCount:
    putI64Le(output, i * 8, words[i])
  int64(outputLength)
