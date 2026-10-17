const
  MaxN = 8
  MaxInputLength = 129

proc stable_matching*(input: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "stable_matching".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nArg = input[0]
  if nArg < 0 or nArg > MaxN: return -1
  let n = int(nArg)
  let sideSize = n * n
  if length != csize_t(1 + 2 * sideSize): return -1

  var menPreferences: array[64, int64]
  var womenRank: array[64, int64]
  for row in 0 ..< 2 * n:
    var seen: array[8, bool]
    for id in 0 ..< MaxN: seen[id] = false
    let rowStart = if row < n: 1 + row * n else: 1 + sideSize + (row - n) * n
    for rank in 0 ..< n:
      let participant = input[rowStart + rank]
      if participant < 0 or participant >= nArg or seen[int(participant)]: return -1
      seen[int(participant)] = true
      if row < n: menPreferences[row * n + rank] = participant
      else: womenRank[(row - n) * n + int(participant)] = int64(rank)

  let outputBytes = csize_t(16 * n)
  if output == nil or capacity < outputBytes: return -2

  var womanPartner: array[8, int64]
  var manPartner: array[8, int64]
  var nextProposal: array[8, int]
  var freeQueue: array[8, int]
  for index in 0 ..< n:
    womanPartner[index] = -1
    manPartner[index] = -1
    freeQueue[index] = index

  var head = 0
  var tail = 0
  var queueCount = n
  while queueCount > 0:
    let man = freeQueue[head]
    head = (head + 1) mod n
    dec queueCount
    let rank = nextProposal[man]
    inc nextProposal[man]
    let woman = int(menPreferences[man * n + rank])
    let incumbent = womanPartner[woman]
    if incumbent < 0:
      womanPartner[woman] = int64(man)
      manPartner[man] = int64(woman)
    elif womenRank[woman * n + man] < womenRank[woman * n + int(incumbent)]:
      womanPartner[woman] = int64(man)
      manPartner[man] = int64(woman)
      manPartner[int(incumbent)] = -1
      freeQueue[tail] = int(incumbent)
      tail = (tail + 1) mod n
      inc queueCount
    else:
      freeQueue[tail] = man
      tail = (tail + 1) mod n
      inc queueCount

  for man in 0 ..< n:
    let pair = [int64(man), manPartner[man]]
    for item in 0 ..< 2:
      let bits = cast[uint64](pair[item])
      for byte in 0 ..< 8:
        output[(man * 2 + item) * 8 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(outputBytes)
