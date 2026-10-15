## Lyndon factorization using Duval's linear-time algorithm.
const MaxLength = csize_t(4096)

proc validInput(values: ptr UncheckedArray[int64], length: csize_t): bool =
  if length > MaxLength or (length != 0 and values.isNil): return false
  for index in 0 ..< length:
    if values[index] < 0 or values[index] > 127: return false
  true

proc factorCount(values: ptr UncheckedArray[int64], length: csize_t): csize_t =
  var start: csize_t = 0
  var count: csize_t = 0
  while start < length:
    var endIndex = start + 1
    var repeat = start
    while endIndex < length and values[repeat] <= values[endIndex]:
      if values[repeat] < values[endIndex]: repeat = start
      else: repeat += 1
      endIndex += 1
    let factorLength = endIndex - repeat
    while start <= repeat:
      count += 1
      start += factorLength
  count

proc storeU32LE(output: ptr UncheckedArray[uint8], offset: csize_t, value: csize_t) =
  for byteIndex in 0 ..< 4:
    output[offset + csize_t(byteIndex)] = uint8((value shr (8 * byteIndex)) and 255)

proc writeFactors(values: ptr UncheckedArray[int64], length: csize_t,
                  output: ptr UncheckedArray[uint8]) =
  var start: csize_t = 0
  var factorIndex: csize_t = 0
  while start < length:
    var endIndex = start + 1
    var repeat = start
    while endIndex < length and values[repeat] <= values[endIndex]:
      if values[repeat] < values[endIndex]: repeat = start
      else: repeat += 1
      endIndex += 1
    let factorLength = endIndex - repeat
    while start <= repeat:
      storeU32LE(output, 4 * factorIndex, factorLength)
      factorIndex += 1
      start += factorLength

proc duvalAlgorithm*(values: ptr UncheckedArray[int64], length: csize_t,
                     output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "duval_algorithm".} =
  if not validInput(values, length): return -1
  let count = factorCount(values, length)
  let required = 4 * count
  if required == 0: return 0
  if output.isNil or outputCapacity < required: return -2
  writeFactors(values, length, output)
  int64(count)
