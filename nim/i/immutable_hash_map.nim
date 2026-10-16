const MaxOps = 256
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc hashI64(hashValue: var uint64, value: int64) =
  let bits = cast[uint64](value)
  for shift in countup(0, 56, 8):
    hashValue = (hashValue xor uint64(uint8(bits shr shift))) *% FnvPrime

proc immutable_hash_map*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "immutable_hash_map".} =
  if input.isNil or length < 1 or length > csize_t(1 + 3 * MaxOps): return -1
  let count64 = input[0]
  if count64 < 0 or count64 > MaxOps or length != csize_t(1 + 3 * count64): return -1
  let count = int(count64)
  var keys: array[MaxOps, int32]
  var values: array[MaxOps, int32]
  var trace: array[MaxOps, int64]
  var mapSize = 0

  for i in 0 ..< count:
    let operation = input[1 + 3 * i]
    let key64 = input[2 + 3 * i]
    let value64 = input[3 + 3 * i]
    if operation < 0 or operation > 3 or key64 < int64(low(int32)) or key64 > int64(high(int32)) or value64 < int64(low(int32)) or value64 > int64(high(int32)): return -1
    let key = int32(key64)
    let value = int32(value64)
    case operation
    of 0:
      if value == 0: return -1
      keys[mapSize] = key
      values[mapSize] = value
      inc mapSize
      trace[i] = int64(mapSize)
    of 1, 2:
      var foundValue = 0'i32
      var j = mapSize
      while j > 0:
        dec j
        if keys[j] == key:
          foundValue = values[j]
          break
      if operation == 1: trace[i] = int64(foundValue)
      elif foundValue != 0: trace[i] = 1
      else: trace[i] = 0
    of 3:
      trace[i] = int64(mapSize)
    else:
      return -1

  var hashValue = FnvOffset
  hashI64(hashValue, count64)
  for i in 0 ..< count: hashI64(hashValue, trace[i])
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
