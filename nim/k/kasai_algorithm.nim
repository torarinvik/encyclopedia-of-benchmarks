const MaxLength = 512
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc fnvWord(hash: uint64, value: int64): uint64 =
  let bits = cast[uint64](value)
  var resultHash = hash
  for byte in 0 ..< 8:
    resultHash = (resultHash xor ((bits shr (8 * byte)) and 255'u64)) * FnvPrime
  resultHash

proc kasai_algorithm*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kasai_algorithm".} =
  if values.isNil or length < 1: return -1
  if values[0] < 0 or values[0] > MaxLength: return -1
  let n = int(values[0])
  if int(length) != 1 + 2 * n: return -1
  for i in 0 ..< n:
    if values[1 + i] < 0 or values[1 + i] > 127: return -1

  var suffixes: array[MaxLength, int]
  var rank: array[MaxLength, int]
  var seen: array[MaxLength, bool]
  var lcp: array[MaxLength, int64]
  for position in 0 ..< n:
    let suffixValue = values[1 + n + position]
    if suffixValue < 0 or suffixValue >= int64(n): return -1
    let suffix = int(suffixValue)
    if seen[suffix]: return -1
    seen[suffix] = true
    suffixes[position] = suffix
    rank[suffix] = position

  if n > 1:
    for position in 1 ..< n:
      let left = suffixes[position - 1]
      let right = suffixes[position]
      let leftTailRank = if left + 1 < n: rank[left + 1] else: -1
      let rightTailRank = if right + 1 < n: rank[right + 1] else: -1
      let leftByte = values[1 + left]
      let rightByte = values[1 + right]
      if leftByte > rightByte or (leftByte == rightByte and leftTailRank >= rightTailRank): return -1

  var common = 0
  for start in 0 ..< n:
    let currentRank = rank[start]
    if currentRank == n - 1:
      common = 0
      continue
    let nextStart = suffixes[currentRank + 1]
    while start + common < n and nextStart + common < n and
        values[1 + start + common] == values[1 + nextStart + common]:
      inc common
    lcp[currentRank] = int64(common)
    if common > 0: dec common

  var hash = fnvWord(FnvOffset, int64(n))
  for i in 0 ..< n: hash = fnvWord(hash, lcp[i])
  int64(hash and 0x7fff_ffff_ffff_ffff'u64)
