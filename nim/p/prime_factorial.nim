const MaxInput = 4096'i64
const MaxDistinctFactors = 5

proc isPrimeBySourceTrialDivision(candidate: int64): bool =
  if candidate == 2: return true
  let halfCandidate = candidate div 2 + 1
  var divisor = 2'i64
  while divisor <= halfCandidate:
    if candidate mod divisor == 0: return false
    if divisor == halfCandidate: return true
    inc divisor
  false

proc prime_factorial*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "prime_factorial".} =
  if value < 2 or value > MaxInput: return -1
  var factors: array[MaxDistinctFactors, uint32]
  var count = 0
  var candidate = 2'i64
  while candidate <= value:
    if isPrimeBySourceTrialDivision(candidate) and value mod candidate == 0:
      factors[count] = uint32(candidate)
      inc count
    inc candidate
  let required = csize_t(count * 4)
  if output == nil or outputCapacity < required: return -2
  var position = csize_t(0)
  for index in 0 ..< count:
    let factor = factors[index]
    for byteIndex in 0 ..< 4:
      output[position] = uint8((factor shr (byteIndex * 8)) and 0xFF'u32)
      inc position
  int64(position)
