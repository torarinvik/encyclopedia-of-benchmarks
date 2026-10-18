import std/math

const MaxParseableInputLength = 22
const MaxDegree = 8
const MaxOutputElements = 17

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc single_indeterminate_operations*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "single_indeterminate_operations".} =
  if input == nil or inputLength < 3 or inputLength > MaxParseableInputLength.csize_t: return -1
  let inputCount = int(inputLength)
  for index in 0 ..< inputCount:
    if classify(input[index]) in {fcNan, fcInf, fcNegInf}: return -1
  if not exactInteger(input[0], 0, 5): return -1
  let operation = int(input[0])

  var cursor = 1
  if not exactInteger(input[cursor], 0, MaxDegree): return -1
  let degreeA = int(input[cursor])
  cursor += 1
  var coefficientsA: array[MaxDegree + 1, float64]
  if cursor + degreeA + 1 > inputCount: return -1
  for index in 0 .. degreeA:
    let value = input[cursor + index]
    if value < -10.0 or value > 10.0: return -1
    coefficientsA[index] = value
  cursor += degreeA + 1

  var degreeB = 0
  var coefficientsB: array[MaxDegree + 1, float64]
  var parameter = 0.0
  if operation <= 2:
    if cursor >= inputCount or not exactInteger(input[cursor], 0, MaxDegree): return -1
    degreeB = int(input[cursor])
    cursor += 1
    if cursor + degreeB + 1 > inputCount: return -1
    for index in 0 .. degreeB:
      let value = input[cursor + index]
      if value < -10.0 or value > 10.0: return -1
      coefficientsB[index] = value
    cursor += degreeB + 1
    if cursor != inputCount: return -1
  elif operation == 3 or operation == 5:
    if cursor + 1 != inputCount: return -1
    parameter = input[cursor]
    if operation == 3:
      if parameter < -2.0 or parameter > 2.0: return -1
    elif parameter < -10.0 or parameter > 10.0: return -1
    cursor += 1
  elif cursor != inputCount: return -1

  var staged: array[MaxOutputElements, float64]
  var resultLength = 0
  case operation
  of 0:
    resultLength = max(degreeA, degreeB) + 1
    if degreeA > degreeB:
      for index in 0 .. degreeA: staged[index] = coefficientsA[index]
      for index in 0 .. degreeB: staged[index] += coefficientsB[index]
    else:
      for index in 0 .. degreeB: staged[index] = coefficientsB[index]
      for index in 0 .. degreeA: staged[index] += coefficientsA[index]
  of 1:
    var negatedB: array[MaxDegree + 1, float64]
    for index in 0 .. degreeB: negatedB[index] = coefficientsB[index] * -1.0
    resultLength = max(degreeA, degreeB) + 1
    if degreeA > degreeB:
      for index in 0 .. degreeA: staged[index] = coefficientsA[index]
      for index in 0 .. degreeB: staged[index] += negatedB[index]
    else:
      for index in 0 .. degreeB: staged[index] = negatedB[index]
      for index in 0 .. degreeA: staged[index] += coefficientsA[index]
  of 2:
    resultLength = degreeA + degreeB + 1
    for left in 0 .. degreeA:
      for right in 0 .. degreeB:
        staged[left + right] += coefficientsA[left] * coefficientsB[right]
  of 3:
    resultLength = 1
    for index in 0 .. degreeA:
      staged[0] += coefficientsA[index] * pow(parameter, float64(index))
  of 4:
    resultLength = degreeA
    for index in 0 ..< degreeA:
      staged[index] = coefficientsA[index + 1] * float64(index + 1)
  else:
    resultLength = degreeA + 2
    staged[0] = parameter
    for index in 0 .. degreeA:
      staged[index + 1] = coefficientsA[index] / float64(index + 1)

  for index in 0 ..< resultLength:
    if classify(staged[index]) in {fcNan, fcInf, fcNegInf}: return -1
  if output == nil or capacity < csize_t(resultLength): return -2
  for index in 0 ..< resultLength: output[index] = staged[index]
  int64(resultLength)
