import std/math

const MaxStringLength = 128
const AlphabetSize = 95
const InvalidResult = -1.0e300

proc dice_coefficient*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "dice_coefficient".} =
  if values.isNil or length < 2: return InvalidResult
  let lenARaw = values[0]
  let lenBRaw = values[1]
  if lenARaw < 0 or lenARaw > MaxStringLength or lenBRaw < 0 or lenBRaw > MaxStringLength: return InvalidResult
  let lenA = int(lenARaw)
  let lenB = int(lenBRaw)
  if length != csize_t(2 + lenA + lenB): return InvalidResult
  for i in 0..<lenA+lenB:
    if values[2+i] < 32 or values[2+i] > 126: return InvalidResult
  var equal = lenA == lenB
  var i = 0
  while equal and i < lenA:
    if values[2+i] != values[2+lenA+i]: equal = false
    inc i
  if equal: return 1.0
  if lenA < 2 or lenB < 2: return 0.0
  var present: array[9025, bool]
  for i in 0..<lenA-1:
    let first = int(values[2+i] - 32)
    let second = int(values[2+i+1] - 32)
    present[first*AlphabetSize+second] = true
  var common = 0
  for j in 0..<lenB-1:
    let first = int(values[2+lenA+j] - 32)
    let second = int(values[2+lenA+j+1] - 32)
    if present[first*AlphabetSize+second]: inc common
  let denominator = float64(lenA + lenB - 2)
  let score = (2.0 * float64(common)) / denominator
  floor(score * 100.0) / 100.0
