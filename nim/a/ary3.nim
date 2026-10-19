const MaxLength = 4096

proc ary3*(length: int64, output: ptr UncheckedArray[uint8],
           outputCapacity: csize_t): int64 {.cdecl, exportc: "ary3".} =
  if length < 1 or length > MaxLength: return -1
  let n = int(length)
  var x: array[MaxLength, int32]
  var y: array[MaxLength, int32]
  for index in 0 ..< n:
    x[index] = int32(index + 1)
    y[index] = 0
  for _ in 0 ..< 1000:
    for index in countdown(n - 1, 0):
      y[index] += x[index]

  var first = uint32(y[0])
  var last = uint32(y[n - 1])
  var firstReversed: array[10, uint8]
  var firstDigitCount = 0
  while first > 0:
    firstReversed[firstDigitCount] = uint8(48'u32 + (first mod 10'u32))
    inc firstDigitCount
    first = first div 10'u32
  var reversed: array[10, uint8]
  var digitCount = 0
  while last > 0:
    reversed[digitCount] = uint8(48'u32 + last mod 10'u32)
    inc digitCount
    last = last div 10'u32
  let required = firstDigitCount + 2 + digitCount
  if output.isNil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< firstDigitCount:
    output[index] = firstReversed[firstDigitCount - index - 1]
  output[firstDigitCount] = uint8(ord(' '))
  for index in 0 ..< digitCount:
    output[firstDigitCount + 1 + index] = reversed[digitCount - index - 1]
  output[required - 1] = uint8(ord('\n'))
  int64(required)
