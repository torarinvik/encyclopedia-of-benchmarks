## Build a bounded term-to-document table and rank one query by BM25.
proc bm25_inverted_index*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bm25_inverted_index".} =
  if values == nil or length < 2 or length > 2114 or values[0] < 0 or values[0] > 32:
    return -2
  let documentCount = int(values[0])
  if values[int(length) - 1] < 1 or values[int(length) - 1] > 255: return -2
  let query = values[int(length) - 1]
  var frequency: array[32, int64]
  var documentLength: array[32, int64]
  var documentId: array[32, int64]
  var seenIds: array[256, bool]
  var offset = 1
  var totalTerms = 0'i64
  for document in 0 ..< documentCount:
    if offset + 2 > int(length) - 1: return -2
    let id = values[offset]
    let termCountValue = values[offset + 1]
    offset += 2
    if id < 0 or id > 255 or termCountValue < 0 or termCountValue > 64: return -2
    let idIndex = int(id)
    let termCount = int(termCountValue)
    if seenIds[idIndex] or termCount > int(length) - 1 - offset: return -2
    seenIds[idIndex] = true
    documentId[document] = id
    documentLength[document] = termCountValue
    totalTerms += termCountValue
    for _ in 0 ..< termCount:
      let termValue = values[offset]
      inc offset
      if termValue < 1 or termValue > 255: return -2
      if termValue == query: inc frequency[document]
  if offset != int(length) - 1:
    return -2

  var resultId: array[32, int64]
  var resultTf: array[32, int64]
  var resultDenominator: array[32, int64]
  var resultCount = 0
  for document in 0 ..< documentCount:
    let tf = frequency[document]
    if tf == 0: continue
    let denominator = 8 * totalTerms * tf + 3 * totalTerms + 9 * int64(documentCount) * documentLength[document]
    var position = resultCount
    while position > 0:
      let previous = position - 1
      let left = tf * resultDenominator[previous]
      let right = resultTf[previous] * denominator
      if left < right or (left == right and documentId[document] > resultId[previous]): break
      resultId[position] = resultId[previous]
      resultTf[position] = resultTf[previous]
      resultDenominator[position] = resultDenominator[previous]
      dec position
    resultId[position] = documentId[document]
    resultTf[position] = tf
    resultDenominator[position] = denominator
    inc resultCount
  if csize_t(resultCount) > outputCapacity or (resultCount != 0 and output == nil): return -2
  for index in 0 ..< resultCount:
    output[index] = uint8(resultId[index])
  int64(resultCount)
