const MaxN = 6
const MaxInput = 73
const MaxOutputBytes = 104

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc weak_stable_matching_ties_incomplete*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "weak_stable_matching_ties_incomplete".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxInput): return -1
  let nRaw = input[0]
  if nRaw < 1 or nRaw > MaxN: return -1
  let n = int(nRaw)
  let sideSize = n * n
  if length != csize_t(1 + 2 * sideSize): return -1
  var menRank: array[MaxN, array[MaxN, int64]]
  var womenRank: array[MaxN, array[MaxN, int64]]
  var choices: array[MaxN, array[MaxN, int]]
  var choiceCount: array[MaxN, int]
  for man in 0 ..< n:
    for woman in 0 ..< n:
      let rank = input[1 + man * n + woman]
      if rank < 0 or rank > nRaw: return -1
      menRank[man][woman] = rank
  for woman in 0 ..< n:
    for man in 0 ..< n:
      let rank = input[1 + sideSize + woman * n + man]
      if rank < 0 or rank > nRaw or ((rank > 0) != (menRank[man][woman] > 0)): return -1
      womenRank[woman][man] = rank
  for man in 0 ..< n:
    for woman in 0 ..< n:
      if menRank[man][woman] == 0: continue
      var at = choiceCount[man]
      while at > 0:
        let prior = choices[man][at - 1]
        if menRank[man][prior] < menRank[man][woman] or
            (menRank[man][prior] == menRank[man][woman] and prior < woman): break
        choices[man][at] = prior
        dec at
      choices[man][at] = woman
      inc choiceCount[man]
  var manPartner: array[MaxN, int]
  var womanPartner: array[MaxN, int]
  var nextChoice: array[MaxN, int]
  for i in 0 ..< n:
    manPartner[i] = -1
    womanPartner[i] = -1
  while true:
    var man = -1
    for candidate in 0 ..< n:
      if manPartner[candidate] < 0 and nextChoice[candidate] < choiceCount[candidate]:
        man = candidate
        break
    if man < 0: break
    let woman = choices[man][nextChoice[man]]
    inc nextChoice[man]
    let incumbent = womanPartner[woman]
    if incumbent < 0 or womenRank[woman][man] < womenRank[woman][incumbent] or
        (womenRank[woman][man] == womenRank[woman][incumbent] and man < incumbent):
      womanPartner[woman] = man
      manPartner[man] = woman
      if incumbent >= 0: manPartner[incumbent] = -1
  var words: array[1 + 2 * MaxN, int64]
  var pairs = 0
  for man in 0 ..< n:
    if manPartner[man] >= 0:
      words[1 + 2 * pairs] = int64(man)
      words[2 + 2 * pairs] = int64(manPartner[man])
      inc pairs
  words[0] = int64(pairs)
  let outputBytes = csize_t(8 * (1 + 2 * pairs))
  if output.isNil or capacity < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  for word in 0 ..< 1 + 2 * pairs: storeI64Le(addr staged[0], 8 * word, words[word])
  for byte in 0 ..< int(outputBytes): output[byte] = staged[byte]
  int64(outputBytes)
