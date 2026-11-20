const
  MaxN = 32
  MaxDocs = 8
  MaxQueries = 16
  MaxInput = 68
  MaxOutput = 144

type
  ListingState = object
    documents: array[MaxN, int64]
    previous: array[MaxN, int64]
    logs: array[MaxN + 1, int]
    table: array[6, array[MaxN, int]]
    foundRanks: array[MaxDocs, int]
    foundDocs: array[MaxDocs, uint8]
    foundCount: int
    staged: array[MaxOutput, uint8]
    written: int

proc rangeMin(state: var ListingState, lo, hi: int): int =
  let level = state.logs[hi - lo + 1]
  let width = 1 shl level
  let left = state.table[level][lo]
  let right = state.table[level][hi - width + 1]
  if state.previous[left] < state.previous[right] or
      (state.previous[left] == state.previous[right] and left < right):
    left
  else:
    right

proc report(state: var ListingState, lo, hi, queryLo: int, count: var int) =
  if lo > hi: return
  let index = rangeMin(state, lo, hi)
  if state.previous[index] >= int64(queryLo): return
  state.foundRanks[state.foundCount] = index
  state.foundDocs[state.foundCount] = uint8(state.documents[index])
  inc state.foundCount
  inc count
  if index > lo: report(state, lo, index - 1, queryLo, count)
  if index < hi: report(state, index + 1, hi, queryLo, count)

proc muthukrishnan_document_listing*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "muthukrishnan_document_listing".} =
  if values == nil or length < 3 or length > csize_t(MaxInput): return -1
  let nValue = values[0]
  let docsValue = values[1]
  let qValue = values[2]
  if nValue < 1 or nValue > MaxN or docsValue < 1 or docsValue > MaxDocs or
      qValue < 1 or qValue > MaxQueries: return -1
  let n = int(nValue)
  let docs = int(docsValue)
  let q = int(qValue)
  if int(length) != 3 + n + 2 * q: return -1

  var state: ListingState
  var last: array[MaxDocs, int64]
  for doc in 0 ..< docs: last[doc] = -1
  for i in 0 ..< n:
    let document = values[3 + i]
    if document < 0 or document >= docsValue: return -1
    state.documents[i] = document
    state.previous[i] = last[int(document)]
    last[int(document)] = int64(i)
  for query in 0 ..< q:
    let lo = values[3 + n + 2 * query]
    let hi = values[4 + n + 2 * query]
    if lo < 0 or hi < lo or hi >= nValue: return -1

  for size in 2 .. n: state.logs[size] = state.logs[size div 2] + 1
  for i in 0 ..< n: state.table[0][i] = i
  let levelCount = state.logs[n] + 1
  for level in 1 ..< levelCount:
    let width = 1 shl level
    let half = width div 2
    for start in 0 .. n - width:
      let left = state.table[level - 1][start]
      let right = state.table[level - 1][start + half]
      if state.previous[left] < state.previous[right] or
          (state.previous[left] == state.previous[right] and left < right):
        state.table[level][start] = left
      else:
        state.table[level][start] = right

  for query in 0 ..< q:
    let lo = int(values[3 + n + 2 * query])
    let hi = int(values[4 + n + 2 * query])
    let countAt = state.written
    inc state.written
    state.foundCount = 0
    var count = 0
    report(state, lo, hi, lo, count)
    for i in 1 ..< state.foundCount:
      let rank = state.foundRanks[i]
      let document = state.foundDocs[i]
      var j = i
      while j > 0 and state.foundRanks[j - 1] > rank:
        state.foundRanks[j] = state.foundRanks[j - 1]
        state.foundDocs[j] = state.foundDocs[j - 1]
        dec j
      state.foundRanks[j] = rank
      state.foundDocs[j] = document
    state.staged[countAt] = uint8(count)
    for i in 0 ..< state.foundCount:
      state.staged[state.written] = state.foundDocs[i]
      inc state.written
  if state.written > MaxOutput: return -1
  if output == nil or outputCapacity < csize_t(state.written): return -2
  for i in 0 ..< state.written: output[i] = state.staged[i]
  int64(state.written)
