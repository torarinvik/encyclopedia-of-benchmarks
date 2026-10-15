## Generate the nth count-and-say term as ASCII bytes.
const MaxTermLength = 256

proc count_and_say*(termIndex: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "count_and_say".} =
  if termIndex < 1 or termIndex > 19: return -1
  var current: array[MaxTermLength, uint8]
  var next: array[MaxTermLength, uint8]
  var currentLength = 1
  current[0] = uint8('1')
  for term in 1 ..< int(termIndex):
    var nextLength = 0
    var index = 0
    while index < currentLength:
      var ending = index + 1
      while ending < currentLength and current[ending] == current[index]: inc ending
      let runLength = ending - index
      if nextLength + 2 > MaxTermLength: return -1
      next[nextLength] = uint8(ord('0') + runLength)
      next[nextLength + 1] = current[index]
      nextLength += 2
      index = ending
    for position in 0 ..< nextLength: current[position] = next[position]
    currentLength = nextLength
  if outputCapacity < csize_t(currentLength) or output == nil: return -2
  for index in 0 ..< currentLength: output[index] = current[index]
  int64(currentLength)
