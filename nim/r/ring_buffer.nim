const MaxQ = 256
const MaxInput = 513
const ValueLimit = 1_000_000'i64
const ValueOffset = 1_000_001'i64
const HashMultiplier = 1_000_003'i64
const HashModulus = 1_000_000_007'i64

proc ring_buffer*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ring_buffer".} =
  if packed.isNil or length < 1 or length > MaxInput: return -1
  let qv = packed[0]
  if qv < 0 or qv > MaxQ or length != csize_t(1 + qv * 2): return -1
  let q = int(qv)
  for i in 0 ..< q:
    let op = packed[1 + i * 2]
    let payload = packed[2 + i * 2]
    if op == 0:
      if payload < -ValueLimit or payload > ValueLimit: return -1
    elif op == 4:
      if payload < 0 or payload > ValueLimit: return -1
    elif op >= 1 and op <= 3:
      if payload != 0: return -1
    elif op >= 5 and op <= 9:
      if payload != 0: return -1
    else:
      return -1

  var values: array[8, int64]
  var head = 0
  var tail = 0
  var count = 0
  var hash = 0'i64
  for i in 0 ..< q:
    let op = packed[1 + i * 2]
    let payload = packed[2 + i * 2]
    var status = 0'i64
    var result = 0'i64
    if op == 0:
      if count == 8:
        status = 1
      else:
        values[tail] = payload
        tail = (tail + 1) mod 8
        inc count
    elif op == 1:
      if count == 0:
        status = 2
      else:
        result = values[head]
        head = (head + 1) mod 8
        dec count
    elif op == 2:
      if count == 0: status = 2
      else: result = values[head]
    elif op == 3:
      if count == 0: status = 2
      else: result = values[(tail + 7) mod 8]
    elif op == 4:
      if payload >= count.int64(): status = 3
      else: result = values[(head + int(payload)) mod 8]
    elif op == 5:
      head = 0
      tail = 0
      count = 0
    elif op == 6:
      result = count.int64
    elif op == 7:
      result = 8 - count.int64
    elif op == 8:
      if count == 0: result = 1
    else:
      if count == 8: result = 1

    hash = (hash * HashMultiplier + op) mod HashModulus
    hash = (hash * HashMultiplier + status) mod HashModulus
    hash = (hash * HashMultiplier + result + ValueOffset) mod HashModulus
    hash = (hash * HashMultiplier + count.int64) mod HashModulus
    for j in 0 ..< count:
      let position = (head + j) mod 8
      hash = (hash * HashMultiplier + values[position] + ValueOffset) mod HashModulus
  hash
