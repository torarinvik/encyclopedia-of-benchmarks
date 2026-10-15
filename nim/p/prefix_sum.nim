const MaxLength = 256
const HashCapacity = 1024

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (b * 8)) and 255)

proc hashKey(key: int64): int =
  let bucket = key mod HashCapacity.int64
  int(if bucket < 0: bucket + HashCapacity.int64 else: bucket)

proc containsSum(prefix: openArray[int64], count: int, target: int64): bool =
  var keys: array[HashCapacity, int64]
  var used: array[HashCapacity, bool]
  var slot = hashKey(0)
  keys[slot] = 0; used[slot] = true
  for ending in 1 .. count:
    let wanted = prefix[ending] - target
    slot = hashKey(wanted)
    while used[slot] and keys[slot] != wanted: slot = (slot + 1) mod HashCapacity
    if used[slot]: return true
    slot = hashKey(prefix[ending])
    while used[slot] and keys[slot] != prefix[ending]: slot = (slot + 1) mod HashCapacity
    if not used[slot]: used[slot] = true; keys[slot] = prefix[ending]
  false

proc prefix_sum*(input: ptr UncheckedArray[int64], length: csize_t,
                 output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                 {.cdecl, exportc: "prefix_sum".} =
  if input == nil or length < 2 or input[0] < 0 or input[0] > 2 or input[1] < 0 or input[1] > MaxLength: return -1
  let operation = input[0]
  let count = int(input[1])
  let extra = if operation == 1: 2 elif operation == 2: 1 else: 0
  if length != csize_t(2 + count + extra) or (operation == 1 and count == 0): return -1
  for i in 0 ..< count:
    if input[2 + i] < int64(low(int32)) or input[2 + i] > int64(high(int32)): return -1
  if operation == 1:
    let left = input[2 + count]; let right = input[3 + count]
    if left < 0 or right < left or right >= int64(count): return -1
  elif operation == 2 and (input[2 + count] < -1_000_000_000_000'i64 or input[2 + count] > 1_000_000_000_000'i64): return -1
  var prefix: array[MaxLength + 1, int64]
  for i in 0 ..< count: prefix[i + 1] = prefix[i] + input[2 + i]
  let words = if operation == 0: count else: 1
  if capacity < csize_t(words * 8) or (words > 0 and output == nil): return -2
  if operation == 0:
    for i in 0 ..< count: storeI64Le(output, i * 8, prefix[i + 1])
    return int64(count)
  let result = if operation == 1: prefix[int(input[3 + count]) + 1] - prefix[int(input[2 + count])]
               else: (if containsSum(prefix, count, input[2 + count]): 1'i64 else: 0'i64)
  storeI64Le(output, 0, result)
  1
