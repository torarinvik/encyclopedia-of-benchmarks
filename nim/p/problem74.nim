## Count starts with the source's memoized digit-factorial chain length.
const
  MaxStart = 1_000_000'i64
  CacheSize = 2_540_161
  MaxPathLength = 128
  DigitFactorials: array[10, int64] = [1'i64, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

proc sumDigitFactorials(value: int64): int64 =
  var remaining = value
  while remaining > 0:
    result += DigitFactorials[int(remaining mod 10)]
    remaining = remaining div 10
  if value == 0: 1 else: result

proc chainLength(start: int64, cache: var array[CacheSize, uint8]): int64 =
  var path: array[MaxPathLength, int64]
  var pathLength = 0
  var current = start
  var chainResult = 0'i64
  while true:
    let encoded = cache[int(current)]
    if encoded != 0:
      chainResult = int64(encoded) - 1
      break
    let nextValue = sumDigitFactorials(current)
    var repeats = false
    for index in 0 ..< pathLength:
      if path[index] == nextValue:
        repeats = true
        break
    if repeats:
      cache[int(current)] = 1
      chainResult = 0
      break
    path[pathLength] = current
    inc pathLength
    current = nextValue
  while pathLength > 0:
    dec pathLength
    current = path[pathLength]
    inc chainResult
    cache[int(current)] = uint8(chainResult + 1)
  int64(cache[int(start)]) - 1

proc problem74*(numTerms, maxStart: int64): int64 {.cdecl, exportc: "problem74".} =
  if maxStart > MaxStart: return -1
  if maxStart <= 1: return 0
  var cache: array[CacheSize, uint8]
  cache[145] = 1
  cache[169] = 4
  cache[36301] = 4
  cache[1454] = 4
  cache[871] = 3
  cache[45361] = 3
  cache[872] = 3
  for start in 1'i64 ..< maxStart:
    if chainLength(start, cache) == numTerms: inc result
