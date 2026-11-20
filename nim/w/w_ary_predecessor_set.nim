## 64-ary hierarchical bitmap predecessor set.
proc waryLowBit(bits: uint64): int =
  var low = 0
  var high = 64
  while high - low > 1:
    let middle = (low + high) div 2
    let mask = (1'u64 shl middle) - 1
    if (bits and mask) != 0: high = middle
    else: low = middle
  low

proc waryHighBit(bits: uint64): int =
  var low = 0
  var high = 64
  while high - low > 1:
    let middle = (low + high) div 2
    if (bits shr middle) != 0: low = middle
    else: high = middle
  low

proc waryInsert(leaf: var array[4096, uint64], group: var array[64, uint64],
                top: var uint64, key: int): int64 =
  let word = key shr 6
  let bitIndex = key and 63
  let bit = 1'u64 shl bitIndex
  let old = leaf[word]
  if (old and bit) != 0: return 0
  if old == 0:
    let groupIndex = word shr 6
    let slot = word and 63
    if group[groupIndex] == 0: top = top or (1'u64 shl groupIndex)
    group[groupIndex] = group[groupIndex] or (1'u64 shl slot)
  leaf[word] = old or bit
  1

proc waryErase(leaf: var array[4096, uint64], group: var array[64, uint64],
               top: var uint64, key: int): int64 =
  let word = key shr 6
  let bitIndex = key and 63
  let bit = 1'u64 shl bitIndex
  let old = leaf[word]
  if (old and bit) == 0: return 0
  leaf[word] = old and not bit
  if leaf[word] == 0:
    let groupIndex = word shr 6
    let slot = word and 63
    group[groupIndex] = group[groupIndex] and not (1'u64 shl slot)
    if group[groupIndex] == 0: top = top and not (1'u64 shl groupIndex)
  1

proc warySuccessor(leaf: var array[4096, uint64], group: var array[64, uint64],
                   top: uint64, key: int): int64 =
  let word = key shr 6
  let bitIndex = key and 63
  let candidates = leaf[word] shr bitIndex
  if candidates != 0: return int64(word * 64 + bitIndex + waryLowBit(candidates) + 1)
  let groupIndex = word shr 6
  let slot = word and 63
  var later = 0'u64
  if slot < 63: later = group[groupIndex] shr (slot + 1)
  var nextWord: int
  if later != 0:
    nextWord = groupIndex * 64 + slot + 1 + waryLowBit(later)
  else:
    if groupIndex < 63: later = top shr (groupIndex + 1)
    else: later = 0
    if later == 0: return 0
    let nextGroup = groupIndex + 1 + waryLowBit(later)
    nextWord = nextGroup * 64 + waryLowBit(group[nextGroup])
  int64(nextWord * 64 + waryLowBit(leaf[nextWord]) + 1)

proc waryPredecessor(leaf: var array[4096, uint64], group: var array[64, uint64],
                     top: uint64, key: int): int64 =
  let word = key shr 6
  let bitIndex = key and 63
  let candidates = leaf[word] and ((1'u64 shl bitIndex) - 1)
  if candidates != 0: return int64(word * 64 + waryHighBit(candidates) + 1)
  let groupIndex = word shr 6
  let slot = word and 63
  var earlier = group[groupIndex] and ((1'u64 shl slot) - 1)
  var previousWord: int
  if earlier != 0:
    previousWord = groupIndex * 64 + waryHighBit(earlier)
  else:
    earlier = top and ((1'u64 shl groupIndex) - 1)
    if earlier == 0: return 0
    let previousGroup = waryHighBit(earlier)
    previousWord = previousGroup * 64 + waryHighBit(group[previousGroup])
  int64(previousWord * 64 + waryHighBit(leaf[previousWord]) + 1)

proc w_ary_predecessor_set*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "w_ary_predecessor_set".} =
  if input.isNil or length < 1 or length > 66: return -1
  let qr = input[0]
  if qr < 0 or qr > 32: return -1
  let q = int(qr)
  if length != csize_t(1 + 2 * q): return -1
  var leaf: array[4096, uint64]
  var group: array[64, uint64]
  var top = 0'u64
  var result = 0'i64
  var cursor = 1
  for i in 0 ..< q:
    let opcode = input[cursor]
    let rawKey = input[cursor + 1]
    cursor += 2
    if opcode < 0 or opcode > 4 or rawKey < 0 or rawKey >= 262144: return -1
    let key = int(rawKey)
    var answer = 0'i64
    if opcode == 0: answer = waryInsert(leaf, group, top, key)
    elif opcode == 1: answer = waryErase(leaf, group, top, key)
    elif opcode == 2:
      if (leaf[key shr 6] and (1'u64 shl (key and 63))) != 0: answer = 1
    elif opcode == 3: answer = warySuccessor(leaf, group, top, key)
    else: answer = waryPredecessor(leaf, group, top, key)
    result += int64(i + 1) * answer
  result
