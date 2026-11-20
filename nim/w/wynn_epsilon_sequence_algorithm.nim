import math

const MaxN = 10
const MaxInputLength = 13
const MaxOrder = 6

proc wynn_epsilon_sequence_algorithm*(input: ptr UncheckedArray[float64],
    inputLength: csize_t, output: ptr UncheckedArray[float64],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "wynn_epsilon_sequence_algorithm".} =
  if input == nil or inputLength < 3 or inputLength > MaxInputLength: return -1
  for i in 0 ..< int(inputLength):
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1
  let nValue = input[0]
  let kValue = input[1]
  if floor(nValue) != nValue or floor(kValue) != kValue or
      nValue < 5.0 or nValue > float64(MaxN) or kValue < 2.0 or kValue > 3.0: return -1
  let n = int(nValue)
  let k = int(kValue)
  if n < 2 * k + 1 or inputLength != csize_t(n + 2): return -1
  for i in 0 ..< n:
    let sample = input[i + 2]
    let scaled = sample * 256.0
    if sample < -2.0 or sample > 2.0 or floor(scaled) != scaled: return -1

  var rows: array[MaxOrder + 1, array[MaxN, float64]]
  var valid: array[MaxOrder + 1, array[MaxN, bool]]
  for i in 0 ..< n:
    rows[0][i] = input[i + 2]
    valid[0][i] = true
  for order in 0 ..< 2 * k:
    for i in 0 ..< n - order - 1:
      var auxiliaryValid = true
      if order != 0: auxiliaryValid = valid[order - 1][i + 1]
      if not valid[order][i] or not valid[order][i + 1] or not auxiliaryValid: continue
      let denominator = rows[order][i + 1] - rows[order][i]
      if denominator == 0.0 or classify(denominator) in {fcNan, fcInf, fcNegInf}: continue
      let reciprocal = 1.0 / denominator
      var auxiliary = 0.0
      if order != 0: auxiliary = rows[order - 1][i + 1]
      let value = auxiliary + reciprocal
      if classify(reciprocal) in {fcNan, fcInf, fcNegInf} or
          classify(value) in {fcNan, fcInf, fcNegInf}: continue
      rows[order + 1][i] = value
      valid[order + 1][i] = true

  var needed = 0
  for order in countup(2, 2 * k, 2): needed += 2 * (n - order)
  if output == nil or outputCapacity < csize_t(needed): return -2
  var cursor = 0
  for order in countup(2, 2 * k, 2):
    for i in 0 ..< n - order:
      output[cursor] = if valid[order][i]: 0.0 else: 1.0
      output[cursor + 1] = if valid[order][i]: rows[order][i] else: 0.0
      cursor += 2
  int64(needed)
