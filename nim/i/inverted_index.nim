const MaxDocs = 256
const MaxWordsPerDoc = 256
const MaxTotalWords = 4096
const MaxQueryTerms = 16
const MaxInput = 4627
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc hashI64(hashValue: var uint64, value: int64) =
  let bits = cast[uint64](value)
  for shift in countup(0, 56, 8):
    hashValue = (hashValue xor uint64(uint8(bits shr shift))) *% FnvPrime

proc inverted_index*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "inverted_index".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let docCount64 = input[0]
  if docCount64 < 0 or docCount64 > MaxDocs: return -1
  let docCount = int(docCount64)
  var seenDocs: array[MaxDocs, bool]
  var postingHeads: array[65536, int32]
  var postingNext: array[MaxTotalWords, int32]
  var postingDoc: array[MaxTotalWords, uint8]
  for i in 0 ..< 65536: postingHeads[i] = -1
  var postingCount = 0
  var totalWords = 0
  var cursor = 1

  for _ in 0 ..< docCount:
    if cursor > int(length) or int(length) - cursor < 2: return -1
    let docId64 = input[cursor]
    let wordCount64 = input[cursor + 1]
    cursor += 2
    if docId64 < 0 or docId64 >= MaxDocs or wordCount64 < 1 or wordCount64 > MaxWordsPerDoc: return -1
    let docId = int(docId64)
    let wordCount = int(wordCount64)
    if seenDocs[docId] or wordCount > int(length) - cursor or totalWords > MaxTotalWords - wordCount: return -1
    seenDocs[docId] = true
    totalWords += wordCount
    for _ in 0 ..< wordCount:
      let word64 = input[cursor]
      inc cursor
      if word64 < 0 or word64 > 65535: return -1
      let wordId = int(word64)
      var duplicate = false
      var edge = postingHeads[wordId]
      while edge >= 0:
        let edgeIndex = int(edge)
        if int(postingDoc[edgeIndex]) == docId:
          duplicate = true
          break
        edge = postingNext[edgeIndex]
      if not duplicate:
        if postingCount >= MaxTotalWords: return -1
        postingDoc[postingCount] = uint8(docId)
        postingNext[postingCount] = postingHeads[wordId]
        postingHeads[wordId] = int32(postingCount)
        inc postingCount

  if cursor > int(length) or int(length) - cursor < 2: return -1
  let operation = input[cursor]
  let termCount64 = input[cursor + 1]
  cursor += 2
  if (operation != 0 and operation != 1) or termCount64 < 1 or termCount64 > MaxQueryTerms or int(termCount64) != int(length) - cursor: return -1
  let termCount = int(termCount64)
  var terms: array[MaxQueryTerms, int]
  for i in 0 ..< termCount:
    let term64 = input[cursor + i]
    if term64 < 0 or term64 > 65535: return -1
    terms[i] = int(term64)

  var resultFlags: array[MaxDocs, bool]
  var termFlags: array[MaxDocs, bool]
  for docId in 0 ..< MaxDocs: resultFlags[docId] = operation == 0 and seenDocs[docId]
  for t in 0 ..< termCount:
    for docId in 0 ..< MaxDocs: termFlags[docId] = false
    var edge = postingHeads[terms[t]]
    while edge >= 0:
      let edgeIndex = int(edge)
      termFlags[int(postingDoc[edgeIndex])] = true
      edge = postingNext[edgeIndex]
    for docId in 0 ..< MaxDocs:
      if operation == 0: resultFlags[docId] = resultFlags[docId] and termFlags[docId]
      else: resultFlags[docId] = resultFlags[docId] or termFlags[docId]
  var resultIds: array[MaxDocs, int64]
  var resultCount = 0
  for docId in 0 ..< MaxDocs:
    if resultFlags[docId]:
      resultIds[resultCount] = int64(docId)
      inc resultCount
  var hashValue = FnvOffset
  hashI64(hashValue, int64(resultCount))
  for i in 0 ..< resultCount: hashI64(hashValue, resultIds[i])
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
