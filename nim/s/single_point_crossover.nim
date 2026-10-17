const MaxParentLength = 31
const MaxInputLength = 2 + 2 * MaxParentLength

proc single_point_crossover*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "single_point_crossover".} =
  if input.isNil or inputLength < 6 or inputLength > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let cutValue = input[1]
  if classify(nValue) in {fcNan, fcInf, fcNegInf} or classify(cutValue) in {fcNan, fcInf, fcNegInf}: return -1
  if nValue < 2.0 or nValue > float64(MaxParentLength) or nValue != float64(int(nValue)) or
     cutValue < 1.0 or cutValue > nValue - 1.0 or cutValue != float64(int(cutValue)): return -1
  let n = int(nValue)
  let cut = int(cutValue)
  if inputLength != csize_t(2 + 2 * n): return -1
  var first, second: array[MaxParentLength, float64]
  for index in 0 ..< n:
    first[index] = input[2 + index]
    second[index] = input[2 + n + index]
    if classify(first[index]) in {fcNan, fcInf, fcNegInf} or classify(second[index]) in {fcNan, fcInf, fcNegInf}: return -1
  let required = 2 * n
  if output.isNil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< n:
    output[index] = if index < cut: first[index] else: second[index]
    output[n + index] = if index < cut: second[index] else: first[index]
  int64(required)
