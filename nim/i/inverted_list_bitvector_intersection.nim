type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc writeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc inverted_list_bitvector_intersection*(input: I64Input, length: csize_t,
    output: U8Output, outputCapacity: csize_t): int64 {.cdecl, exportc: "inverted_list_bitvector_intersection".} =
  const MaxDomain = 1024
  const MaxLists = 16
  const MaxWords = 16
  if input == nil or length < 2 or length > 258: return -1
  let domainValue = input[0]
  let listCountValue = input[1]
  if domainValue < 1 or domainValue > MaxDomain or listCountValue < 1 or listCountValue > MaxLists:
    return -1

  let domain = int(domainValue)
  let listCount = int(listCountValue)
  let wordsPerList = (domain + 63) div 64
  if length != csize_t(2 + listCount * wordsPerList): return -1

  let remainder = domain mod 64
  if remainder != 0:
    let validMask = (1'u64 shl remainder) - 1'u64
    for list in 0 ..< listCount:
      let finalIndex = 2 + list * wordsPerList + wordsPerList - 1
      let finalWord = cast[uint64](input[finalIndex])
      if (finalWord and not validMask) != 0: return -1

  var intersection: array[MaxWords, uint64]
  for word in 0 ..< wordsPerList:
    var combined = high(uint64)
    for list in 0 ..< listCount:
      let inputIndex = 2 + list * wordsPerList + word
      combined = combined and cast[uint64](input[inputIndex])
    intersection[word] = combined

  var results: array[MaxDomain, int64]
  var resultCount = 0
  for documentId in 0 ..< domain:
    let bit = 1'u64 shl (documentId mod 64)
    if (intersection[documentId div 64] and bit) != 0:
      results[resultCount] = int64(documentId)
      inc resultCount

  let outputBytes = (resultCount + 1) * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  writeI64Le(output, 0, int64(resultCount))
  for index in 0 ..< resultCount:
    writeI64Le(output, (index + 1) * 8, results[index])
  int64(outputBytes)
