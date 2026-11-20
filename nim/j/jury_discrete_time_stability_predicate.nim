type I64Input = ptr UncheckedArray[int64]

const MaxDegree = 4'i64
const MaxParseableLength = 7

proc jury_discrete_time_stability_predicate*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "jury_discrete_time_stability_predicate".} =
  if input == nil or length < 1 or length > MaxParseableLength: return -1
  let degree = input[0]
  if degree < 1 or degree > MaxDegree or length != csize_t(degree + 2): return -1

  var coefficients: array[5, int64]
  for index in 0 .. int(degree):
    let value = input[index + 1]
    if value < -9 or value > 9 or (index == 0 and value == 0): return -1
    coefficients[index] = value
  if coefficients[0] < 0:
    for index in 0 .. int(degree): coefficients[index] = -coefficients[index]

  var atOne = 0'i64
  var atMinusOne = 0'i64
  for index in 0 .. int(degree):
    atOne += coefficients[index]
    if (int(degree) - index) mod 2 == 0: atMinusOne += coefficients[index]
    else: atMinusOne -= coefficients[index]
  if atOne <= 0 or ((degree mod 2 == 0 and atMinusOne <= 0) or
                     (degree mod 2 != 0 and atMinusOne >= 0)): return 0

  var row: array[5, int64]
  var reduced: array[5, int64]
  for index in 0 .. int(degree): row[index] = coefficients[index]
  for currentDegree in countdown(int(degree), 1):
    let trailing = row[currentDegree]
    let trailingMagnitude = if trailing < 0: -trailing else: trailing
    if row[0] <= trailingMagnitude: return 0
    if currentDegree == 1: break
    for index in 0 ..< currentDegree:
      reduced[index] = row[0] * row[index] - trailing * row[currentDegree - index]
    for index in 0 ..< currentDegree: row[index] = reduced[index]
  1
