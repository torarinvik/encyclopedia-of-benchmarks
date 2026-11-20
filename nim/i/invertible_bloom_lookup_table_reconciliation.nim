const SetLimit = 8
const KeyLimit = 63
const CellCount = 48
const MaxPeels = 16
const MaxInput = 18

proc checksum(key: int64): int64 = key * key + 3 * key + 7

proc location(key: int64, part: int): int =
  let x = int(key)
  case part
  of 0: x mod 16
  of 1: 16 + ((3 * x + 5) mod 16)
  else: 32 + ((5 * x + 9) mod 16)

proc writeI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc invertible_bloom_lookup_table_reconciliation*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 2 or length > csize_t(MaxInput + 1): return -1
  let aRaw = input[0]
  let bRaw = input[1]
  if aRaw < 0 or aRaw > SetLimit or bRaw < 0 or bRaw > SetLimit: return -1
  let aCount = int(aRaw)
  let bCount = int(bRaw)
  if int(length) != 2 + aCount + bCount: return -1
  for side in 0 ..< 2:
    let count = if side == 0: aCount else: bCount
    let start = if side == 0: 2 else: 2 + aCount
    var previous = -1'i64
    for i in 0 ..< count:
      let key = input[start + i]
      if key < 0 or key > KeyLimit or key <= previous: return -1
      previous = key

  var counts: array[CellCount, int64]
  var sums: array[CellCount, int64]
  var checks: array[CellCount, int64]
  for side in 0 ..< 2:
    let count = if side == 0: aCount else: bCount
    let start = if side == 0: 2 else: 2 + aCount
    let sign = if side == 0: 1'i64 else: -1'i64
    for i in 0 ..< count:
      let key = input[start + i]
      let tag = checksum(key)
      for part in 0 ..< 3:
        let slot = location(key, part)
        counts[slot] += sign
        sums[slot] += sign * key
        checks[slot] += sign * tag

  var positive: array[MaxPeels, int64]
  var negative: array[MaxPeels, int64]
  var positiveCount = 0
  var negativeCount = 0
  var repeated = false
  for _ in 0 ..< MaxPeels:
    var zero = true
    for i in 0 ..< CellCount:
      if counts[i] != 0 or sums[i] != 0 or checks[i] != 0:
        zero = false
        break
    if zero: break
    var found = false
    var selectedSign = 0'i64
    var selectedKey = 0'i64
    for i in 0 ..< CellCount:
      if counts[i] != 1 and counts[i] != -1: continue
      let sign = counts[i]
      let key = sign * sums[i]
      if key < 0 or key > KeyLimit: continue
      if checks[i] != sign * checksum(key): continue
      selectedSign = sign
      selectedKey = key
      found = true
      break
    if not found: break
    for i in 0 ..< positiveCount:
      if positive[i] == selectedKey: repeated = true
    for i in 0 ..< negativeCount:
      if negative[i] == selectedKey: repeated = true
    if repeated: break
    if selectedSign > 0:
      positive[positiveCount] = selectedKey
      inc positiveCount
    else:
      negative[negativeCount] = selectedKey
      inc negativeCount
    for part in 0 ..< 3:
      let slot = location(selectedKey, part)
      counts[slot] -= selectedSign
      sums[slot] -= selectedSign * selectedKey
      checks[slot] -= selectedSign * checksum(selectedKey)

  var zero = true
  for i in 0 ..< CellCount:
    if counts[i] != 0 or sums[i] != 0 or checks[i] != 0:
      zero = false
      break
  for i in 1 ..< positiveCount:
    let value = positive[i]
    var j = i
    while j > 0 and positive[j - 1] > value:
      positive[j] = positive[j - 1]
      dec j
    positive[j] = value
  for i in 1 ..< negativeCount:
    let value = negative[i]
    var j = i
    while j > 0 and negative[j - 1] > value:
      negative[j] = negative[j - 1]
      dec j
    negative[j] = value

  var staged: array[3 + 2 * MaxPeels, int64]
  var words = 0
  staged[words] = if not repeated and zero: 1 else: 0
  inc words
  staged[words] = int64(positiveCount)
  inc words
  staged[words] = int64(negativeCount)
  inc words
  for i in 0 ..< positiveCount:
    staged[words] = positive[i]
    inc words
  for i in 0 ..< negativeCount:
    staged[words] = negative[i]
    inc words
  let required = words * 8
  if output.isNil or int(capacity) < required: return -2
  for i in 0 ..< words: writeI64Le(output, i, staged[i])
  int64(required)
