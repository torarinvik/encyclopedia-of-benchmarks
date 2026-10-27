const MaxRequests = 32
const MaxPages = 16
const MaxInput = 67
const MaxOutputBytes = 536

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc randomized_marking_page_caching*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "randomized_marking_page_caching".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let cacheRaw = input[0]
  let requestsRaw = input[1]
  if cacheRaw < 1 or cacheRaw > 8 or requestsRaw < 0 or requestsRaw > MaxRequests: return -1
  let cacheSize = int(cacheRaw)
  let requests = int(requestsRaw)
  if length < csize_t(3 + requests): return -1
  let choicesRaw = input[2 + requests]
  if choicesRaw < 0 or choicesRaw > requestsRaw or length != csize_t(3 + requests + int(choicesRaw)): return -1
  let choiceCount = int(choicesRaw)
  var pages: array[MaxRequests, int]
  var choices: array[MaxRequests, int]
  for i in 0 ..< requests:
    let page = input[2 + i]
    if page < 0 or page >= MaxPages: return -1
    pages[i] = int(page)
  for i in 0 ..< choiceCount:
    let choice = input[3 + requests + i]
    if choice < 0 or choice > MaxPages: return -1
    choices[i] = int(choice)

  var resident: array[MaxPages, bool]
  var marked: array[MaxPages, bool]
  var hits: array[MaxRequests, int64]
  var victims: array[MaxRequests, int64]
  for i in 0 ..< MaxRequests: victims[i] = -1
  var residentCount = 0
  var choiceAt = 0
  var misses = 0'i64
  for request in 0 ..< requests:
    let page = pages[request]
    if resident[page]:
      hits[request] = 1
      marked[page] = true
      continue
    inc misses
    if residentCount == cacheSize:
      var eligible: array[MaxPages, int]
      var eligibleCount = 0
      for candidate in 0 ..< MaxPages:
        if resident[candidate] and not marked[candidate]:
          eligible[eligibleCount] = candidate
          inc eligibleCount
      if eligibleCount == 0:
        for candidate in 0 ..< MaxPages:
          if resident[candidate]:
            marked[candidate] = false
            eligible[eligibleCount] = candidate
            inc eligibleCount
      if choiceAt >= choiceCount or choices[choiceAt] >= eligibleCount: return -1
      let victim = eligible[choices[choiceAt]]
      inc choiceAt
      resident[victim] = false
      marked[victim] = false
      dec residentCount
      victims[request] = int64(victim)
    resident[page] = true
    marked[page] = true
    inc residentCount
  if choiceAt != choiceCount: return -1
  var residentMask = 0'i64
  var markedMask = 0'i64
  for page in 0 ..< MaxPages:
    if resident[page]: residentMask = residentMask or (1'i64 shl page)
    if resident[page] and marked[page]: markedMask = markedMask or (1'i64 shl page)
  var words: array[3 + 2 * MaxRequests, int64]
  words[0] = misses
  words[1] = residentMask
  words[2] = markedMask
  for i in 0 ..< requests:
    words[3 + i] = hits[i]
    words[3 + requests + i] = victims[i]
  let outputBytes = csize_t(8 * (3 + 2 * requests))
  if output.isNil or capacity < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  for word in 0 ..< 3 + 2 * requests: storeI64Le(addr staged[0], 8 * word, words[word])
  for byte in 0 ..< int(outputBytes): output[byte] = staged[byte]
  int64(outputBytes)
