## Emit the sorted unique pairwise sums of two bounded integer sets.
const MinSum = -2000'i64
const MaxSum = 2000'i64
const SumCount = 4001
const MaxSetSize = 64

proc decimalWidth(valueInput: int64): int =
  var value = valueInput
  result = 1
  if value < 0:
    value = -value
    inc result
  while value >= 10:
    value = value div 10
    inc result

proc appendSignedDecimal(output: ptr UncheckedArray[uint8], positionInput: int,
                         valueInput: int64): int =
  var value = valueInput
  result = positionInput
  if value < 0:
    output[result] = uint8('-')
    inc result
    value = -value
  var digits: array[20, uint8]
  var count = 0
  while true:
    digits[count] = uint8(value mod 10)
    inc count
    value = value div 10
    if value == 0: break
  while count > 0:
    dec count
    output[result] = uint8('0') + digits[count]
    inc result

proc sumset*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sumset".} =
  if values == nil or length < 2: return -1
  let countA = values[0]
  let countB = values[1]
  if countA < 0 or countA > MaxSetSize or countB < 0 or countB > MaxSetSize or
      length != csize_t(2 + countA + countB): return -1
  var present: array[SumCount, bool]
  for indexA in 0 ..< int(countA):
    let left = values[indexA + 2]
    if left < -1000 or left > 1000: return -1
  for indexB in 0 ..< int(countB):
    let right = values[int(countA) + indexB + 2]
    if right < -1000 or right > 1000: return -1
  for indexA in 0 ..< int(countA):
    let left = values[indexA + 2]
    for indexB in 0 ..< int(countB):
      let right = values[int(countA) + indexB + 2]
      present[int(left + right - MinSum)] = true
  var needed = 0
  for index in 0 ..< SumCount:
    if present[index]: needed += decimalWidth(int64(index) + MinSum) + 1
  if needed == 0: return 0
  if output == nil or outputCapacity < csize_t(needed): return -2
  var position = 0
  for index in 0 ..< SumCount:
    if present[index]:
      position = appendSignedDecimal(output, position, int64(index) + MinSum)
      output[position] = uint8('\n')
      inc position
  int64(position)
