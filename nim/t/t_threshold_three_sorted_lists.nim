const TtLists = 3
const TtMaxList = 32
const TtMaxValues = 48
const TtMaxInput = 3 + TtLists * TtMaxList
const TtWhite = 0
const TtGreen = 1
const TtRed = 2

proc ttPutI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc t_threshold_three_sorted_lists*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "t_threshold_three_sorted_lists".} =
  if input.isNil or length < 6 or length > csize_t(TtMaxInput + 1): return -1
  var base, sizes: array[TtLists, int]
  var at = 0
  for id in 0 ..< TtLists:
    if at >= int(length) or input[at] < 1 or input[at] > TtMaxList: return -1
    sizes[id] = int(input[at])
    inc at
    if sizes[id] > int(length) - at: return -1
    base[id] = at
    for j in 0 ..< sizes[id]:
      let value = input[at + j]
      if value < int64(low(int32)) or value > int64(high(int32)) or
          (j > 0 and input[at + j - 1] >= value): return -1
    at += sizes[id]
  if at != int(length): return -1

  var tails, firsts: array[TtLists, int64]
  for i in 0 ..< TtLists:
    tails[i] = input[base[i] + sizes[i] - 1]
    firsts[i] = input[base[i]]
  for i in 0 ..< TtLists:
    for j in i + 1 ..< TtLists:
      if tails[i] > tails[j]: swap(tails[i], tails[j])
      if firsts[i] > firsts[j]: swap(firsts[i], firsts[j])
  let maximumCandidate = tails[1]
  var candidate = firsts[1]

  var color: array[TtLists, int]
  var cursor, searchBase, searchLow, searchStep, searchProbe: array[TtLists, int]
  var representative: array[TtLists, int]
  var representativePresent: array[TtLists, bool]
  for i in 0 ..< TtLists:
    cursor[i] = 1
    searchBase[i] = 1
    searchLow[i] = 1
    searchStep[i] = 1
    searchProbe[i] = 1
    if input[base[i]] == candidate: color[i] = TtGreen
    elif input[base[i]] > candidate:
      color[i] = TtRed
      representativePresent[i] = true

  var staged: array[TtMaxValues, int64]
  var resultCount = 0
  var roundRobin = 0
  while candidate <= maximumCandidate:
    var greenCount, redCount, whiteCount = 0
    for i in 0 ..< TtLists:
      if color[i] == TtGreen: inc greenCount
      elif color[i] == TtRed: inc redCount
      else: inc whiteCount
    if greenCount >= 2 or redCount >= 2:
      if greenCount >= 2:
        staged[resultCount] = candidate
        inc resultCount
      var recolorCount = if whiteCount == 0: 1 else: 0
      for i in 0 ..< TtLists:
        if recolorCount == 0: break
        if color[i] != TtGreen: continue
        color[i] = TtWhite
        searchBase[i] = cursor[i]
        searchLow[i] = cursor[i]
        searchStep[i] = 1
        searchProbe[i] = cursor[i]
        dec recolorCount
      for i in 0 ..< TtLists:
        if color[i] != TtGreen: continue
        color[i] = TtRed
        representative[i] = cursor[i]
        representativePresent[i] = cursor[i] < sizes[i]

      var found = false
      var nextCandidate = high(int64)
      for i in 0 ..< TtLists:
        if not representativePresent[i]: continue
        let value = input[base[i] + representative[i]]
        if not found or value < nextCandidate:
          found = true
          nextCandidate = value
      if not found: break
      candidate = nextCandidate
      for i in 0 ..< TtLists:
        if color[i] != TtRed or not representativePresent[i] or
            input[base[i] + representative[i]] != candidate: continue
        color[i] = TtGreen
        representativePresent[i] = false
        cursor[i] = representative[i] + 1
        searchBase[i] = cursor[i]
        searchLow[i] = cursor[i]
        searchStep[i] = 1
        searchProbe[i] = cursor[i]
      continue

    var listId = TtLists
    for offset in 0 ..< TtLists:
      let i = (roundRobin + offset) mod TtLists
      if color[i] == TtWhite:
        listId = i
        break
    if listId == TtLists: break
    roundRobin = (listId + 1) mod TtLists
    let probe = min(searchProbe[listId], sizes[listId] - 1)
    if input[base[listId] + probe] < candidate:
      searchLow[listId] = probe + 1
      if probe + 1 == sizes[listId]:
        color[listId] = TtRed
        representative[listId] = sizes[listId]
        representativePresent[listId] = false
      else:
        searchStep[listId] *= 2
        searchProbe[listId] = min(searchBase[listId] + searchStep[listId] - 1, sizes[listId] - 1)
      continue
    var low = searchLow[listId]
    var high = probe + 1
    while low < high:
      let middle = low + (high - low) div 2
      if input[base[listId] + middle] < candidate: low = middle + 1
      else: high = middle
    if low < sizes[listId] and input[base[listId] + low] == candidate:
      color[listId] = TtGreen
      cursor[listId] = low + 1
    else:
      color[listId] = TtRed
      representative[listId] = low
      representativePresent[listId] = low < sizes[listId]

  let outputBytes = 8 * (1 + resultCount)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  ttPutI64Le(output, 0, int64(resultCount))
  for i in 0 ..< resultCount: ttPutI64Le(output, 8 * (i + 1), staged[i])
  int64(outputBytes)
