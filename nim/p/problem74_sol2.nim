## Count sol2's bounded, source-ordered digit-factorial chains.
const
  MaxChainLength = 60
  MaxNumberLimit = 1_000_000
  PathCapacity = MaxChainLength + 1
  DigitFactorials: array[10, int64] = [1'i64, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

proc digitFactorialSum(value: int64): int64 =
  var remaining = value
  while remaining > 0:
    result += DigitFactorials[int(remaining mod 10)]
    remaining = remaining div 10
  if value == 0: result = 1

proc cacheContains(value, numberLimit: int64,
                    cache: seq[uint32]): bool =
  value >= 1 and value < numberLimit and cache[int(value)] != 0

proc pathContains(path: var array[PathCapacity, int64], pathLength: int,
                  value: int64): bool =
  for index in 0 ..< pathLength:
    if path[index] == value: return true
  false

proc problem74_sol2*(chainLength, numberLimit: int64): int64 {.cdecl, exportc: "problem74_sol2".} =
  if chainLength < 1 or chainLength > MaxChainLength or
      numberLimit < 1 or numberLimit > MaxNumberLimit: return -1
  if numberLimit == 1: return 0

  var cache = newSeq[uint32](int(numberLimit))
  for start in 1'i64 ..< numberLimit:
    var path: array[PathCapacity, int64]
    var pathLength = 0
    var chainSetLength = 0'i64
    var chainElement = start
    while not cacheContains(chainElement, numberLimit, cache) and
        not pathContains(path, pathLength, chainElement) and chainSetLength <= chainLength:
      path[pathLength] = chainElement
      inc pathLength
      inc chainSetLength
      chainElement = digitFactorialSum(chainElement)
    if cacheContains(chainElement, numberLimit, cache):
      chainSetLength += int64(cache[int(chainElement)])

    cache[int(start)] = uint32(chainSetLength)
    if chainSetLength == chainLength: inc result
