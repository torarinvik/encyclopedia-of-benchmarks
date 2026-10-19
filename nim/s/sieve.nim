const SieveLimit = 8192
const MaxIterations = 64

proc sieve*(iterations: int64, output: ptr UncheckedArray[uint8],
            outputCapacity: csize_t): int64 {.cdecl, exportc: "sieve".} =
  if iterations < 0 or iterations > MaxIterations: return -1

  var flags: array[SieveLimit + 1, uint8]
  var count = 0'i64
  for _ in 0 ..< int(iterations):
    count = 0
    for value in 2 .. SieveLimit: flags[value] = 1
    for value in 2 .. SieveLimit:
      if flags[value] != 0:
        inc count
        var multiple = value + value
        while multiple <= SieveLimit:
          flags[multiple] = 0
          multiple += value

  var reversedDigits: array[10, uint8]
  var digitCount = 0
  var remaining = count
  while true:
    reversedDigits[digitCount] = uint8(48'i64 + remaining mod 10)
    inc digitCount
    remaining = remaining div 10
    if remaining == 0: break
  let required = 8 + digitCount
  if output.isNil or outputCapacity < csize_t(required): return -2
  output[0] = 67'u8; output[1] = 111'u8; output[2] = 117'u8
  output[3] = 110'u8; output[4] = 116'u8; output[5] = 58'u8
  output[6] = 32'u8
  for index in 0 ..< digitCount:
    output[7 + index] = reversedDigits[digitCount - index - 1]
  output[required - 1] = 10'u8
  int64(required)
