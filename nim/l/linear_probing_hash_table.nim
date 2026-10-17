const MaxTableCapacity = 128
const MaxOperations = 32
const MaxInputLength = 66
const MaxOutputWords = 1088
const MaxKey = int64(high(int32)) - 127

proc findSlot(table: openArray[int32], capacity: int, key: int32): int =
  var index = int(key) mod capacity
  for _ in 0 ..< capacity:
    if table[index] == 0: return -1
    if table[index] == key: return index
    index = (index + 1) mod capacity
  -1

proc insertionSlot(table: openArray[int32], capacity: int, key: int32): int =
  var index = int(key) mod capacity
  for _ in 0 ..< capacity:
    if table[index] == 0 or table[index] == -1: return index
    index = (index + 1) mod capacity
  -1

proc rehash(table: var array[MaxTableCapacity, int32], capacity: var int) =
  var oldTable: array[MaxTableCapacity, int32]
  let oldCapacity = capacity
  for i in 0 ..< oldCapacity: oldTable[i] = table[i]
  capacity *= 2
  for i in 0 ..< capacity: table[i] = 0
  for i in 0 ..< oldCapacity:
    let key = oldTable[i]
    if key <= 0: continue
    let slot = insertionSlot(table, capacity, key)
    if slot >= 0: table[slot] = key

proc linearProbingHashTable*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "linear_probing_hash_table".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  if input[0] < 2 or input[0] > 16 or input[1] < 0 or input[1] > MaxOperations: return -1
  var table: array[MaxTableCapacity, int32]
  var tableCapacity = int(input[0])
  let operationCount = int(input[1])
  var size = 0
  var words: array[MaxOutputWords, int64]
  var wordCount = 0
  var position = 2
  for _ in 0 ..< operationCount:
    if position >= int(length): return -1
    let opcode = input[position]; inc position
    if opcode >= 0 and opcode <= 3:
      if position >= int(length): return -1
      let keyArg = input[position]; inc position
      if keyArg < 1 or keyArg > MaxKey: return -1
      let key = int32(keyArg)
      if opcode == 0:
        let slot = insertionSlot(table, tableCapacity, key)
        if slot < 0: return -1
        table[slot] = key; inc size
        words[wordCount] = 0; words[wordCount + 1] = 1; wordCount += 2
        if size * 2 >= tableCapacity: rehash(table, tableCapacity)
      elif opcode == 1:
        let slot = findSlot(table, tableCapacity, key)
        if slot < 0: return -1
        table[slot] = -1; dec size
        words[wordCount] = 1; words[wordCount + 1] = 1; wordCount += 2
      elif opcode == 2:
        words[wordCount] = 2
        words[wordCount + 1] = (if findSlot(table, tableCapacity, key) >= 0: 1 else: 0)
        wordCount += 2
      else:
        words[wordCount] = 3; words[wordCount + 1] = keyArg; wordCount += 2
    elif opcode == 4:
      words[wordCount] = 4; words[wordCount + 1] = int64(tableCapacity); wordCount += 2
      for i in 0 ..< tableCapacity:
        words[wordCount] = if table[i] == 0: -2 else: int64(table[i])
        inc wordCount
    else:
      return -1
  if position != int(length) or wordCount > MaxOutputWords: return -1
  let outputLength = wordCount * 8
  if output == nil or outputCapacity < csize_t(outputLength): return -2
  for i in 0 ..< wordCount:
    let bits = cast[uint64](words[i])
    for byte in 0 ..< 8:
      output[8 * i + byte] = uint8((bits shr (8 * byte)) and 255'u64)
  int64(outputLength)
