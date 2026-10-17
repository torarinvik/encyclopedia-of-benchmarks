const MaxOps = 32
const MaxCapacity = 128
const MaxWords = 320

type HashMap = object
  keys: array[MaxCapacity, int32]
  values: array[MaxCapacity, int32]
  occupied: array[MaxCapacity, bool]
  capacity: int
  size: int

proc hashIndex(key: int32, capacity: int): int =
  int((cast[uint32](key) and 0x7fff_ffff'u32) mod uint32(capacity))

proc resize(map: var HashMap, newCapacity: int) =
  let oldKeys = map.keys
  let oldValues = map.values
  let oldOccupied = map.occupied
  let oldCapacity = map.capacity
  map.capacity = newCapacity
  for i in 0 ..< newCapacity: map.occupied[i] = false
  for i in 0 ..< oldCapacity:
    if oldOccupied[i]:
      var index = hashIndex(oldKeys[i], newCapacity)
      while map.occupied[index]: index = (index + 1) mod newCapacity
      map.keys[index] = oldKeys[i]
      map.values[index] = oldValues[i]
      map.occupied[index] = true

proc findSlot(map: HashMap, key: int32): int =
  var index = hashIndex(key, map.capacity)
  for _ in 0 ..< map.capacity:
    if not map.occupied[index]: return map.capacity
    if map.keys[index] == key: return index
    index = (index + 1) mod map.capacity
  map.capacity

proc put(map: var HashMap, key, value: int32) =
  if map.size > map.capacity div 2: resize(map, map.capacity * 2)
  var index = hashIndex(key, map.capacity)
  while map.occupied[index]:
    if map.keys[index] == key:
      map.values[index] = value
      return
    index = (index + 1) mod map.capacity
  map.keys[index] = key
  map.values[index] = value
  map.occupied[index] = true
  inc map.size

proc deleteKey(map: var HashMap, key: int32): bool =
  var index = findSlot(map, key)
  if index == map.capacity: return false
  map.occupied[index] = false
  map.values[index] = 0
  index = (index + 1) mod map.capacity
  while map.occupied[index]:
    let rehashKey = map.keys[index]
    let rehashValue = map.values[index]
    map.occupied[index] = false
    map.values[index] = 0
    dec map.size
    put(map, rehashKey, rehashValue)
    index = (index + 1) mod map.capacity
  dec map.size
  if map.size > 0 and map.size <= map.capacity div 8: resize(map, map.capacity div 2)
  true

proc append(words: var array[MaxWords, int64], count: var int, value: int64) =
  words[count] = value
  inc count

proc linearProbingHashMap*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "linear_probing_hash_map".} =
  if input == nil or length < 2 or length > 98: return -1
  if input[0] < 4 or input[0] > 16 or input[1] < 0 or input[1] > MaxOps: return -1
  let opCount = int(input[1])
  if int(length) > 2 + 3 * opCount: return -1
  var map = HashMap(capacity: int(input[0]))
  var words: array[MaxWords, int64]
  var wordCount = 0
  var pos = 2
  for _ in 0 ..< opCount:
    if pos >= int(length): return -1
    let op = input[pos]
    inc pos
    if op == 0:
      if pos + 1 >= int(length): return -1
      let key = input[pos]
      let value = input[pos + 1]
      pos += 2
      if key < int64(low(int32)) or key > int64(high(int32)) or value < int64(low(int32)) or value > int64(high(int32)): return -1
      put(map, int32(key), int32(value))
      append(words, wordCount, 0)
      append(words, wordCount, 1)
    elif op >= 1 and op <= 3:
      if pos >= int(length): return -1
      let key = input[pos]
      inc pos
      if key < int64(low(int32)) or key > int64(high(int32)): return -1
      let k = int32(key)
      let index = findSlot(map, k)
      if op == 1:
        append(words, wordCount, 1)
        if index == map.capacity:
          append(words, wordCount, 1)
          append(words, wordCount, 0)
        else:
          append(words, wordCount, 0)
          append(words, wordCount, int64(map.values[index]))
      elif op == 2:
        append(words, wordCount, 2)
        append(words, wordCount, if deleteKey(map, k): 1'i64 else: 0'i64)
      else:
        append(words, wordCount, 3)
        append(words, wordCount, if index != map.capacity: 1'i64 else: 0'i64)
    elif op == 4:
      append(words, wordCount, 4)
      append(words, wordCount, int64(map.size))
    elif op == 5:
      var sorted: array[MaxOps, int32]
      var count = 0
      for i in 0 ..< map.capacity:
        if map.occupied[i]:
          sorted[count] = map.keys[i]
          inc count
      for i in 1 ..< count:
        let value = sorted[i]
        var j = i
        while j > 0 and sorted[j - 1] > value:
          sorted[j] = sorted[j - 1]
          dec j
        sorted[j] = value
      append(words, wordCount, 5)
      append(words, wordCount, int64(count))
      for i in 0 ..< count: append(words, wordCount, int64(sorted[i]))
    else: return -1
  if pos != int(length) or wordCount > MaxWords: return -1
  let bytes = wordCount * 8
  if output == nil or int(outputCapacity) < bytes: return -2
  for i in 0 ..< wordCount:
    let bits = cast[uint64](words[i])
    for b in 0 ..< 8: output[8 * i + b] = uint8((bits shr (8 * b)) and 255)
  int64(bytes)
