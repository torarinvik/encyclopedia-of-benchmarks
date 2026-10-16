proc commonCharactersFrequencyQuotient*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "common_characters_frequency_quotient".} =
  if input == nil or length == 0 or length > 1041: return -1
  let stringCount = input[0]
  if stringCount < 0 or stringCount > 16: return -1
  var counts: array[26, int64]
  var offset = 1.csize_t
  var total = 0.csize_t
  for stringIndex in 0'i64 ..< stringCount:
    if offset >= length: return -1
    let stringLength = input[offset]
    inc offset
    if stringLength < 0 or stringLength > 64 or csize_t(stringLength) > length - offset: return -1
    for index in 0'i64 ..< stringLength:
      let value = input[offset]
      inc offset
      if value < 97 or value > 122: return -1
      inc counts[int(value - 97)]
    total += csize_t(stringLength)
    if total > 512: return -1
  if offset != length: return -1
  var used = 0.csize_t
  if stringCount > 0:
    for count in counts: used += csize_t(count div stringCount)
  if used > capacity or (used > 0 and output == nil): return -2
  var outputOffset = 0.csize_t
  if stringCount > 0:
    for letter, count in counts:
      for copy in 0'i64 ..< count div stringCount:
        output[outputOffset] = uint8(97 + letter)
        inc outputOffset
  int64(used)
