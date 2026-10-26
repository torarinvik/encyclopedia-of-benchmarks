const
  MaxN = 8
  MaxInputLength = 129

proc optimal_stable_marriage*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "optimal_stable_marriage".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nArg = input[0]
  if nArg < 0 or nArg > MaxN: return -1
  let n = int(nArg)
  let sideSize = n * n
  if length != csize_t(1 + 2 * sideSize): return -1

  var menPreferences: array[64, int]
  var womenRank: array[64, int]
  for row in 0 ..< 2 * n:
    var seen: array[MaxN, bool]
    for id in 0 ..< MaxN: seen[id] = false
    let start = if row < n: 1 + row * n else: 1 + sideSize + (row - n) * n
    for rank in 0 ..< n:
      let value = input[start + rank]
      if value < 0 or value >= nArg or seen[int(value)]: return -1
      let participant = int(value)
      seen[participant] = true
      if row < n: menPreferences[row * n + rank] = participant
      else: womenRank[(row - n) * n + participant] = rank

  let outputBytes = csize_t(16 * n)
  if output == nil or capacity < outputBytes: return -2
  var finalPartner: array[MaxN, int64]
  for man in 0 ..< n: finalPartner[man] = -1
  for threshold in 0 ..< n:
    var womanPartner: array[MaxN, int64]
    var manPartner: array[MaxN, int64]
    var nextRank: array[MaxN, int]
    var queue: array[MaxN, int]
    for i in 0 ..< n:
      womanPartner[i] = -1
      manPartner[i] = -1
      nextRank[i] = 0
      queue[i] = i
    var head = 0
    var tail = 0
    var queued = n
    while queued > 0:
      let man = queue[head]
      head = (head + 1) mod n
      dec queued
      while nextRank[man] < n:
        let rank = nextRank[man]
        inc nextRank[man]
        let woman = menPreferences[man * n + rank]
        if rank > threshold or womenRank[woman * n + man] > threshold: continue
        let incumbent = womanPartner[woman]
        if incumbent < 0 or womenRank[woman * n + man] < womenRank[woman * n + int(incumbent)]:
          womanPartner[woman] = int64(man)
          manPartner[man] = int64(woman)
          if incumbent >= 0:
            manPartner[int(incumbent)] = -1
            queue[tail] = int(incumbent)
            tail = (tail + 1) mod n
            inc queued
          break
        queue[tail] = man
        tail = (tail + 1) mod n
        inc queued
        break
    var matched = 0
    for man in 0 ..< n:
      if manPartner[man] >= 0: inc matched
    if matched == n:
      for man in 0 ..< n: finalPartner[man] = manPartner[man]
      break

  for man in 0 ..< n:
    let pair = [int64(man), finalPartner[man]]
    for item in 0 ..< 2:
      let bits = cast[uint64](pair[item])
      for byte in 0 ..< 8:
        output[(man * 2 + item) * 8 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(outputBytes)
