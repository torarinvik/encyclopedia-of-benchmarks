const MaxTerms = 4097
const MaxInput = 3
const MaxSeed = 100_000'i64
const MaxValue = 100_000'i64
const MaxTransitions = 4_096'i64

proc aliquotSum(value: int64): int64 =
  if value == 1: return 0
  var total = 1'i64
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0:
      total += divisor
      let partner = value div divisor
      if partner != divisor: total += partner
    inc divisor
  total

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc aliquot_orbit_decomposition*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "aliquot_orbit_decomposition".} =
  if input == nil or length < 1 or length > csize_t(MaxInput): return -1
  if length != 2 or input[0] < 1 or input[0] > MaxSeed or
      input[1] < 1 or input[1] > MaxTransitions: return -1

  var keys: array[MaxTerms, int64]
  var firstIndices: array[MaxTerms, int64]
  var keyCount = 0
  var words: array[3, int64]
  var current = input[0]
  var transitions = 0'i64
  var positiveCount = 0'i64
  while true:
    if current == 0:
      words = [0'i64, positiveCount, 0'i64]
      break
    var low = 0
    var high = keyCount
    while low < high:
      let middle = low + (high - low) div 2
      if keys[middle] < current: low = middle + 1
      else: high = middle
    if low < keyCount and keys[low] == current:
      words = [1'i64, firstIndices[low], transitions - firstIndices[low]]
      break
    var cursor = keyCount
    while cursor > low:
      keys[cursor] = keys[cursor - 1]
      firstIndices[cursor] = firstIndices[cursor - 1]
      dec cursor
    keys[low] = current
    firstIndices[low] = transitions
    inc keyCount
    inc positiveCount
    if transitions >= input[1]:
      words = [-3'i64, transitions, current]
      break
    let nextValue = aliquotSum(current)
    inc transitions
    if nextValue > MaxValue:
      words = [-2'i64, transitions, nextValue]
      break
    current = nextValue

  if output == nil or capacity < 24: return -2
  for word in 0 ..< 3: storeI64(output, word * 8, words[word])
  24
