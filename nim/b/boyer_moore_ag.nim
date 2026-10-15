type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

const MaxInputValues = 512

proc collectMatches(values: I64Input, textLength, patternLength, patternStart: int,
                    positions: var array[255, uint8]): int =
  var badShift: array[128, int]
  var present: array[128, bool]
  var suffixSkip: array[256, int]
  for index in 0 ..< patternLength - 1:
    let byte = int(values[patternStart + index])
    badShift[byte] = patternLength - index - 1
    present[byte] = true
  for byte in 0 ..< 128:
    if present[byte]:
      let shift = badShift[byte]
      var matched = 0
      while matched < patternLength - shift and
          values[patternStart + patternLength - 1 - matched] == values[patternStart + patternLength - 1 - shift - matched]:
        inc matched
      suffixSkip[shift] = matched

  var count = 0
  var start = 0
  var jump = patternLength
  while start <= textLength - patternLength:
    let skip = suffixSkip[jump]
    var index = patternLength - 1
    while index >= 0:
      let textIndex = 2 + start + index
      if values[textIndex] != values[patternStart + index]:
        let mismatch = int(values[textIndex])
        jump = if present[mismatch]: badShift[mismatch] else: patternLength
        start += jump
        break
      if index == patternLength - jump: index -= skip
      if index == 0:
        positions[count] = uint8(start)
        inc count
        jump = 1
        inc start
        break
      dec index
  count

proc boyer_moore_ag*(values: I64Input, length: csize_t, output: ByteOutput,
                     outputCapacity: csize_t): int64 {.cdecl, exportc: "boyer_moore_ag".} =
  if values == nil or length < 2 or length > MaxInputValues: return -1
  if values[0] < 0 or values[0] > 255 or values[1] < 1 or values[1] > 255: return -1
  let textLength = int(values[0])
  let patternLength = int(values[1])
  if length != csize_t(2 + textLength + patternLength): return -1
  for index in 0 ..< textLength + patternLength:
    if values[2 + index] < 0 or values[2 + index] > 127: return -1

  var positions: array[255, uint8]
  var count = 0
  if patternLength <= textLength:
    count = collectMatches(values, textLength, patternLength, 2 + textLength, positions)
  if outputCapacity < csize_t(count) or (count != 0 and output == nil): return -2
  for index in 0 ..< count: output[index] = positions[index]
  int64(count)
