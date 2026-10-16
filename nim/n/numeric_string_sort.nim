const
  MaxItems = 64
  MaxTokenLength = 32
  MaxInputLength = 2113
  MaxOutputLength = 2111

proc tokenLess(values: ptr UncheckedArray[int64], leftStart, leftLength: int,
               rightStart, rightLength: int): bool =
  if leftLength != rightLength:
    return leftLength < rightLength
  for i in 0 ..< leftLength:
    if values[leftStart + i] != values[rightStart + i]:
      return values[leftStart + i] < values[rightStart + i]
  false

proc numeric_string_sort*(values: ptr UncheckedArray[int64], length: csize_t,
                           output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "numeric_string_sort".} =
  if values.isNil or length == 0 or length > MaxInputLength + 1: return -1
  if values[0] < 0 or values[0] > MaxItems: return -1
  let count = int(values[0])
  var starts, tokenLengths, normalizedStarts, normalizedLengths, order: array[MaxItems, int]
  var cursor = 1
  var outputLength = if count == 0: 0 else: count - 1

  for item in 0 ..< count:
    if cursor >= int(length): return -1
    let rawLength = values[cursor]
    inc cursor
    if rawLength < 1 or rawLength > MaxTokenLength: return -1
    let tokenLength = int(rawLength)
    if tokenLength > int(length) - cursor: return -1
    let start = cursor
    for offset in 0 ..< tokenLength:
      if values[start + offset] < ord('0') or values[start + offset] > ord('9'): return -1
    var zeros = 0
    while zeros < tokenLength and values[start + zeros] == ord('0'):
      inc zeros
    starts[item] = start
    tokenLengths[item] = tokenLength
    normalizedStarts[item] = start + zeros
    normalizedLengths[item] = tokenLength - zeros

    for previous in 0 ..< item:
      if normalizedLengths[previous] != normalizedLengths[item]: continue
      var equal = true
      for offset in 0 ..< normalizedLengths[item]:
        if values[normalizedStarts[previous] + offset] != values[normalizedStarts[item] + offset]:
          equal = false
          break
      if equal:
        if tokenLengths[previous] != tokenLength: return -1
        for offset in 0 ..< tokenLength:
          if values[starts[previous] + offset] != values[start + offset]: return -1
    outputLength += tokenLength
    cursor += tokenLength
    order[item] = item

  if cursor != int(length) or outputLength > MaxOutputLength: return -1
  for i in 1 ..< count:
    let key = order[i]
    var position = i
    while position > 0 and tokenLess(values, normalizedStarts[key], normalizedLengths[key],
                                     normalizedStarts[order[position - 1]], normalizedLengths[order[position - 1]]):
      order[position] = order[position - 1]
      dec position
    order[position] = key

  if (output.isNil and outputLength != 0) or outputCapacity < csize_t(outputLength): return -2
  var written = 0
  for i in 0 ..< count:
    if i > 0:
      output[written] = uint8(ord(' '))
      inc written
    let item = order[i]
    for offset in 0 ..< tokenLengths[item]:
      output[written] = uint8(values[starts[item] + offset])
      inc written
  int64(outputLength)
