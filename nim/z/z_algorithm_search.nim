## Case-insensitive ASCII pattern search using the Z algorithm.
proc z_algorithm_search*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "z_algorithm_search".} =
  const MaxSequenceLength = 2047
  const MaxConcatLength = 4095
  if values == nil or length < 2: return -1
  if values[0] < 0 or values[0] > MaxSequenceLength or values[1] < 0 or values[1] > MaxSequenceLength: return -1
  let textLength = int(values[0])
  let patternLength = int(values[1])
  if length != csize_t(2 + textLength + patternLength): return -1
  for i in 2 ..< int(length):
    if values[i] < 0 or values[i] > 127: return -1
  if patternLength == 0:
    let count = textLength + 1
    if outputCapacity < csize_t(4 * count) or output == nil: return -2
    for i in 0 ..< count:
      let position = uint32(i + 1)
      for b in 0 ..< 4: output[4 * i + b] = uint8((position shr (8 * b)) and 0xff'u32)
    return int64(count)
  var sequence: array[MaxConcatLength, uint32]
  var z: array[MaxConcatLength, int]
  let total = patternLength + 1 + textLength
  for i in 0 ..< patternLength:
    let value = uint32(values[2 + textLength + i])
    sequence[i] = if value >= uint32('A') and value <= uint32('Z'): value + 32 else: value
  sequence[patternLength] = 256
  for i in 0 ..< textLength:
    let value = uint32(values[2 + i])
    sequence[patternLength + 1 + i] = if value >= uint32('A') and value <= uint32('Z'): value + 32 else: value
  var left = 0
  var right = 0
  for i in 1 ..< total:
    if i < right: z[i] = min(z[i - left], right - i)
    while i + z[i] < total and sequence[z[i]] == sequence[i + z[i]]: inc z[i]
    if i + z[i] > right:
      left = i
      right = i + z[i]
  var count = 0
  for i in (patternLength + 1) ..< total:
    if z[i] >= patternLength: inc count
  if outputCapacity < csize_t(4 * count) or (count > 0 and output == nil): return -2
  var write = 0
  for i in (patternLength + 1) ..< total:
    if z[i] >= patternLength:
      let position = uint32(i - patternLength)
      for b in 0 ..< 4: output[4 * write + b] = uint8((position shr (8 * b)) and 0xff'u32)
      inc write
  int64(count)
