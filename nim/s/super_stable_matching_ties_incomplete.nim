const
  MaxN = 4
  MaxParseableLength = 34

proc solve(input: ptr UncheckedArray[int64], length: csize_t): int64 =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let nRaw = input[0]
  if nRaw < 1 or nRaw > MaxN: return -1
  let n = int(nRaw)
  if length != csize_t(1 + 2 * n * n): return -1
  let side = n * n
  var menRank: array[MaxN, array[MaxN, int64]]
  var womenRank: array[MaxN, array[MaxN, int64]]
  for man in 0 ..< n:
    for woman in 0 ..< n:
      let rank = input[1 + man * n + woman]
      if rank < 0 or rank > nRaw: return -1
      menRank[man][woman] = rank
  for woman in 0 ..< n:
    for man in 0 ..< n:
      let rank = input[1 + side + woman * n + man]
      if rank < 0 or rank > nRaw or ((rank > 0) != (menRank[man][woman] > 0)):
        return -1
      womenRank[woman][man] = rank
  for person in 0 ..< n:
    var maximum = 0'i64
    for partner in 0 ..< n:
      maximum = max(maximum, menRank[person][partner])
    for level in 1'i64 .. maximum:
      var found = false
      for partner in 0 ..< n:
        if menRank[person][partner] == level: found = true
      if not found: return -1
    maximum = 0
    for partner in 0 ..< n:
      maximum = max(maximum, womenRank[person][partner])
    for level in 1'i64 .. maximum:
      var found = false
      for partner in 0 ..< n:
        if womenRank[person][partner] == level: found = true
      if not found: return -1

  var alive: array[MaxN, array[MaxN, bool]]
  var engaged: array[MaxN, array[MaxN, bool]]
  var proposed: array[MaxN, bool]
  for man in 0 ..< n:
    for woman in 0 ..< n:
      alive[man][woman] = menRank[man][woman] > 0
  while true:
    var proposer = -1
    for man in 0 ..< n:
      var hasEngagement = false
      var hasChoice = false
      for woman in 0 ..< n:
        hasEngagement = hasEngagement or engaged[man][woman]
        hasChoice = hasChoice or alive[man][woman]
      if proposer < 0 and not hasEngagement and hasChoice: proposer = man
    if proposer < 0: break
    var headRank = nRaw + 1
    for woman in 0 ..< n:
      if alive[proposer][woman]:
        headRank = min(headRank, menRank[proposer][woman])
    for woman in 0 ..< n:
      if not alive[proposer][woman] or menRank[proposer][woman] != headRank: continue
      proposed[woman] = true
      engaged[proposer][woman] = true
      for successor in 0 ..< n:
        if alive[successor][woman]
            and womenRank[woman][successor] > womenRank[woman][proposer]:
          engaged[successor][woman] = false
          alive[successor][woman] = false
    for woman in 0 ..< n:
      var count = 0
      var tailRank = 0'i64
      for man in 0 ..< n:
        if engaged[man][woman]: inc count
        if alive[man][woman]: tailRank = max(tailRank, womenRank[woman][man])
      if count > 1:
        for man in 0 ..< n:
          engaged[man][woman] = false
          if alive[man][woman] and womenRank[woman][man] == tailRank:
            alive[man][woman] = false

  let base = nRaw + 1
  var limit = 1'i64
  for _ in 0 ..< n: limit *= base
  var bestCode = 0'i64
  var bestSize = -1
  for code in 0'i64 ..< limit:
    var used = 0
    var size = 0
    var valid = true
    var place = limit div base
    for man in 0 ..< n:
      let woman = int((code div place) mod base)
      if woman < n:
        if not engaged[man][woman] or (used and (1 shl woman)) != 0: valid = false
        used = used or (1 shl woman)
        inc size
      if man + 1 < n: place = place div base
    if valid and size > bestSize:
      bestSize = size
      bestCode = code
  var matched: array[MaxN, bool]
  var place = limit div base
  for man in 0 ..< n:
    let woman = int((bestCode div place) mod base)
    if woman < n: matched[woman] = true
    if man + 1 < n: place = place div base
  for woman in 0 ..< n:
    if proposed[woman] and not matched[woman]: return -2
  bestCode

proc super_stable_matching_ties_incomplete*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "super_stable_matching_ties_incomplete".} =
  solve(input, length)
