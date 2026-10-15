const MaxWords = 16
const MaxWordLength = 16

proc isAnagram(input: ptr UncheckedArray[int64], queryLength: int,
               wordOffset: int, wordLength: int): bool =
  if queryLength != wordLength: return false
  var counts: array[26, int]
  for i in 0 ..< queryLength:
    inc counts[int(input[2 + i] - 97)]
    dec counts[int(input[wordOffset + i] - 97)]
  for count in counts:
    if count != 0: return false
  true

proc anagram_dictionary_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "anagram_dictionary_search".} =
  if input.isNil or length < 2 or input[0] < 0 or input[0] > MaxWords or
     input[1] < 0 or input[1] > MaxWordLength: return -1
  let wordCount = int(input[0])
  let queryLength = int(input[1])
  if 2 + queryLength > int(length): return -1
  for i in 0 ..< queryLength:
    if input[2 + i] < 97 or input[2 + i] > 122: return -1
  if output.isNil: return -2
  var offset = 2 + queryLength
  var outLength = 0
  for item in 0 ..< wordCount:
    if offset >= int(length) or input[offset] < 1 or input[offset] > MaxWordLength: return -1
    let wordLength = int(input[offset])
    inc offset
    if offset + wordLength > int(length): return -1
    for i in 0 ..< wordLength:
      if input[offset + i] < 97 or input[offset + i] > 122: return -1
    if isAnagram(input, queryLength, offset, wordLength):
      for i in 0 ..< wordLength:
        if csize_t(outLength) >= capacity: return -2
        output[outLength] = uint8(input[offset + i]); inc outLength
      if csize_t(outLength) >= capacity: return -2
      output[outLength] = uint8(ord('\n')); inc outLength
    offset += wordLength
  if offset != int(length): return -1
  if csize_t(outLength) >= capacity: return -2
  output[outLength] = 0
  int64(outLength + 1)
