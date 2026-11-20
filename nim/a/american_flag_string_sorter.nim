proc american_flag_string_sorter*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "american_flag_string_sorter".} =
  if input == nil or length < 1 or length > 8450: return -1
  let itemCountValue = input[0]
  if itemCountValue < 0 or itemCountValue > 256: return -1
  let itemCount = int(itemCountValue)

  var stringLengths: array[256, int]
  var stringBytes: array[8192, int]
  var indices: array[256, int]
  var inputPosition = 1
  for stringIndex in 0..<itemCount:
    if inputPosition >= int(length): return -1
    let stringLengthValue = input[inputPosition]
    if stringLengthValue < 0 or stringLengthValue > 32: return -1
    let stringLength = int(stringLengthValue)
    inc inputPosition
    if inputPosition + stringLength > int(length): return -1
    stringLengths[stringIndex] = stringLength
    indices[stringIndex] = stringIndex
    for byteIndex in 0..<stringLength:
      let byteValue = input[inputPosition + byteIndex]
      if byteValue < 0 or byteValue > 255: return -1
      stringBytes[stringIndex * 32 + byteIndex] = int(byteValue)
    inputPosition += stringLength
  if inputPosition != int(length): return -1

  var stackLow: array[512, int]
  var stackHigh: array[512, int]
  var stackDepth: array[512, int]
  var stackSize = 1
  stackLow[0] = 0
  stackHigh[0] = itemCount
  stackDepth[0] = 0

  while stackSize > 0:
    dec stackSize
    let low = stackLow[stackSize]
    let high = stackHigh[stackSize]
    let depth = stackDepth[stackSize]
    if high - low <= 1 or depth >= 32: continue

    var counts: array[257, int]
    for bucket in 0..256: counts[bucket] = 0
    var starts: array[258, int]
    var next: array[257, int]
    for position in low..<high:
      let stringIndex = indices[position]
      var key = 0
      if depth < stringLengths[stringIndex]:
        key = stringBytes[stringIndex * 32 + depth] + 1
      inc counts[key]

    starts[0] = low
    for bucket in 0..256:
      starts[bucket + 1] = starts[bucket] + counts[bucket]
      next[bucket] = starts[bucket]

    for bucket in 0..256:
      while next[bucket] < starts[bucket + 1]:
        let position = next[bucket]
        let stringIndex = indices[position]
        var key = 0
        if depth < stringLengths[stringIndex]:
          key = stringBytes[stringIndex * 32 + depth] + 1
        if key == bucket:
          inc next[bucket]
        else:
          let destination = next[key]
          let displaced = indices[destination]
          indices[destination] = stringIndex
          indices[position] = displaced
          inc next[key]

    var bucket = 256
    while bucket > 0:
      if counts[bucket] > 1:
        stackLow[stackSize] = starts[bucket]
        stackHigh[stackSize] = starts[bucket + 1]
        stackDepth[stackSize] = depth + 1
        inc stackSize
      dec bucket

  var checksum = 0'i64
  for rank in 0..<itemCount:
    let stringIndex = indices[rank]
    let stringLength = stringLengths[stringIndex]
    var contribution = int64(stringLength + 1)
    for byteIndex in 0..<stringLength:
      contribution += int64(stringBytes[stringIndex * 32 + byteIndex] + 1)
    checksum += int64(rank + 1) * contribution
  return checksum
