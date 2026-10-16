const MaxQ = 256
const MaxInput = 513
const ValueLimit = 1_000_000'i64
const ValueOffset = 1_000_001'i64
const HashMultiplier = 1_000_003'i64
const HashModulus = 1_000_000_007'i64

proc queue_using_array2*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "queue_using_array2".} =
  if packed.isNil or length < 1 or length > MaxInput: return -1
  let qv = packed[0]
  if qv < 0 or qv > MaxQ or length != csize_t(1 + qv * 2): return -1
  let q = int(qv)
  for i in 0 ..< q:
    let op = packed[1 + i * 2]
    let value = packed[2 + i * 2]
    if op == 1:
      if value < -ValueLimit or value > ValueLimit: return -1
    elif op == 2 or op == 3:
      if value != 0: return -1
    else:
      return -1

  var values: array[10, int64]
  var count = 0
  var hash = 0'i64
  for i in 0 ..< q:
    let op = packed[1 + i * 2]
    let value = packed[2 + i * 2]
    if op == 1:
      if count < 10:
        values[count] = value
        inc count
    elif op == 2 and count > 0:
      for j in 1 ..< count:
        values[j - 1] = values[j]
      dec count

    hash = (hash * HashMultiplier + op) mod HashModulus
    hash = (hash * HashMultiplier + count.int64) mod HashModulus
    for j in 0 ..< count:
      hash = (hash * HashMultiplier + values[j] + ValueOffset) mod HashModulus
  hash
