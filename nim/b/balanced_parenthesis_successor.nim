# Clean-room bounded lexicographic successor for a one-type Dyck word.
import std/posix

const MaxPairs = 10
const MaxInputLength = 21
const MaxOutputBytes = 20

proc balanced_parenthesis_successor*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "balanced_parenthesis_successor".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxInputLength): return -1
  let pairValue = input[0]
  if pairValue < 1 or pairValue > MaxPairs.int64: return -1
  let pairs = int(pairValue)
  let sequenceLength = 2 * pairs
  if int64(length) != 1 + 2 * pairValue: return -1
  var symbols: array[MaxOutputBytes, uint8]
  var balance = 0
  for i in 0..<sequenceLength:
    let symbol = input[1 + i]
    if symbol != 0 and symbol != 1: return -1
    symbols[i] = uint8(symbol)
    if symbol == 0: inc balance
    else: dec balance
    if balance < 0: return -1
  if balance != 0: return -1
  if output.isNil or capacity < csize_t(sequenceLength): return -2

  var staged: array[MaxOutputBytes, uint8]
  var reverseDepth = 0
  var cursor = sequenceLength
  while cursor > 0:
    dec cursor
    if symbols[cursor] == 0: dec reverseDepth
    else: inc reverseDepth
    if symbols[cursor] == 0 and reverseDepth > 0:
      dec reverseDepth
      let suffixLength = sequenceLength - cursor - 1
      let openingCount = (suffixLength - reverseDepth) div 2
      let closingCount = suffixLength - openingCount
      for j in 0..<cursor: staged[j] = if symbols[j] == 0: 40'u8 else: 41'u8
      staged[cursor] = 41
      var position = cursor + 1
      for _ in 0..<openingCount:
        staged[position] = 40
        inc position
      for _ in 0..<closingCount:
        staged[position] = 41
        inc position
      for j in 0..<sequenceLength: output[j] = staged[j]
      return int64(sequenceLength)
  -3
