const MaxJobs = 128
const MaxInput = 513
const MaxProfit = 1_000_000'i64
const PackBase = 4_294_967_296'i64

proc job_scheduling_with_deadline*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "job_scheduling_with_deadline".} =
  if packed.isNil or length < 1 or length > csize_t(MaxInput): return -1
  let countValue = packed[0]
  if countValue < 0 or countValue > int64(MaxJobs) or
     length != csize_t(1 + countValue * 4): return -1
  let count = int(countValue)

  var ids: array[MaxJobs, int64]
  var arrivals: array[MaxJobs, int64]
  var deadlines: array[MaxJobs, int64]
  var profits: array[MaxJobs, int64]
  var maxDeadline = 0'i64
  for i in 0 ..< count:
    let base = 1 + i * 4
    ids[i] = packed[base]
    arrivals[i] = packed[base + 1]
    deadlines[i] = packed[base + 2]
    profits[i] = packed[base + 3]
    if ids[i] < 0 or ids[i] > 2_147_483_647'i64 or
       arrivals[i] < 1 or arrivals[i] > 32 or
       deadlines[i] < 1 or deadlines[i] > 32 or
       profits[i] < -MaxProfit or profits[i] > MaxProfit: return -1
    for previous in 0 ..< i:
      if ids[previous] == ids[i]: return -1
    maxDeadline = max(maxDeadline, deadlines[i])

  # Stable insertion sort retains input order for equal profits.
  for i in 1 ..< count:
    let keyId = ids[i]
    let keyArrival = arrivals[i]
    let keyDeadline = deadlines[i]
    let keyProfit = profits[i]
    var position = i
    while position > 0 and profits[position - 1] < keyProfit:
      ids[position] = ids[position - 1]
      arrivals[position] = arrivals[position - 1]
      deadlines[position] = deadlines[position - 1]
      profits[position] = profits[position - 1]
      dec position
    ids[position] = keyId
    arrivals[position] = keyArrival
    deadlines[position] = keyDeadline
    profits[position] = keyProfit

  var occupied: array[32, bool]
  var scheduled = 0'i64
  var totalProfit = 0'i64
  for i in 0 ..< count:
    if arrivals[i] > deadlines[i]: continue
    let lastSlot = min(deadlines[i] - 1, maxDeadline - 1)
    var slot = lastSlot
    while slot >= arrivals[i] - 1:
      let index = int(slot)
      if not occupied[index]:
        occupied[index] = true
        inc scheduled
        totalProfit += profits[i]
        break
      dec slot

  let lowWord = if totalProfit < 0: totalProfit + PackBase else: totalProfit
  scheduled * PackBase + lowWord
