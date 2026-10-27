const MaxM = 6
const MaxW = 6
const MaxInput = 74
const MaxOutput = 48
const MaxSteps = 121

proc put64(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[position + byte] = uint8((bits shr (8 * byte)) and 255)

proc manPrefers(man, a, b: int, rank: array[MaxM * MaxW, int64],
                womanPartner: array[MaxW, int64]): bool =
  let ra = rank[man * MaxW + a]
  let rb = rank[man * MaxW + b]
  if ra != rb: return ra < rb
  let aMaiden = womanPartner[a] == -1
  let bMaiden = womanPartner[b] == -1
  if aMaiden != bMaiden: return aMaiden
  a < b

proc uncertain(man, w: int, rank: array[MaxM * MaxW, int64],
               live: array[MaxM * MaxW, bool], assignment: array[MaxM, int64],
               womanPartner: array[MaxW, int64], status: array[MaxM, int64]): bool =
  if status[man] != 0 or assignment[man] < 0: return false
  let fiance = int(assignment[man])
  for woman in 0 ..< w:
    if live[man * MaxW + woman] and woman != fiance and
        (rank[man*MaxW + woman] < rank[man*MaxW + fiance] or
         (rank[man*MaxW + woman] == rank[man*MaxW + fiance] and
          womanPartner[woman] == -1 and womanPartner[fiance] != -1)):
      return true
  false

proc womanPrefers(woman, candidate, incumbent: int, incumbentUncertain: bool,
                  rank: array[MaxW * MaxM, int64], status: array[MaxM, int64]): bool =
  if incumbentUncertain: return true
  let rc = rank[woman * MaxM + candidate]
  let ri = rank[woman * MaxM + incumbent]
  if rc != ri: return rc < ri
  if status[candidate] != status[incumbent]: return status[candidate] > status[incumbent]
  candidate < incumbent

proc kiraly_max_smt_i_approx*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "kiraly_max_smt_i_approx".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let m64 = input[0]
  let w64 = input[1]
  if m64 < 1 or m64 > int64(MaxM) or w64 < 1 or w64 > int64(MaxW): return -1
  let m = int(m64)
  let w = int(w64)
  if int64(length) != int64(2 + 2*m*w): return -1
  var menRank: array[MaxM * MaxW, int64]
  var womenRank: array[MaxW * MaxM, int64]
  var live: array[MaxM * MaxW, bool]
  var assignment: array[MaxM, int64]
  var womanPartner: array[MaxW, int64]
  var status: array[MaxM, int64]
  for man in 0 ..< m:
    assignment[man] = -1
    for woman in 0 ..< w:
      let rank = input[2 + man*w + woman]
      if rank < -1 or rank >= int64(MaxW): return -1
      menRank[man*MaxW + woman] = rank
  for woman in 0 ..< w:
    womanPartner[woman] = -1
    for man in 0 ..< m:
      let rank = input[2 + m*w + woman*m + man]
      if rank < -1 or rank >= int64(MaxM): return -1
      womenRank[woman*MaxM + man] = rank
  for man in 0 ..< m:
    for woman in 0 ..< w:
      let manAccepts = menRank[man*MaxW + woman] >= 0
      let womanAccepts = womenRank[woman*MaxM + man] >= 0
      if manAccepts != womanAccepts: return -1
      live[man*MaxW + woman] = manAccepts
  let outputBytes = 8*m
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var steps = 0
  while true:
    inc steps
    if steps > MaxSteps: return -1
    var man = m
    for x in 0 ..< m:
      if status[x] != 2 and assignment[x] == -1: man = x; break
    if man == m: break
    var woman = w
    for x in 0 ..< w:
      if live[man*MaxW + x] and (woman == w or manPrefers(man, x, woman, menRank, womanPartner)):
        woman = x
    if woman == w:
      if status[man] == 0:
        status[man] = 1
        for x in 0 ..< w: live[man*MaxW + x] = menRank[man*MaxW + x] >= 0
      else: status[man] = 2
      continue
    let incumbent64 = womanPartner[woman]
    if incumbent64 < 0:
      assignment[man] = int64(woman)
      womanPartner[woman] = int64(man)
      continue
    let incumbent = int(incumbent64)
    let oldUncertain = uncertain(incumbent, w, menRank, live, assignment, womanPartner, status)
    if womanPrefers(woman, man, incumbent, oldUncertain, womenRank, status):
      assignment[incumbent] = -1
      womanPartner[woman] = -1
      if not oldUncertain: live[incumbent*MaxW + woman] = false
      assignment[man] = int64(woman)
      womanPartner[woman] = int64(man)
    else: live[man*MaxW + woman] = false
  var staged: array[MaxOutput, uint8]
  for man in 0 ..< m: put64(addr staged[0], 8*man, assignment[man])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
