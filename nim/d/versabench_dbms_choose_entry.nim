const MaxChildren = 8
const MaxInputLength = 1 + 8 * MaxChildren + 8

proc validBox(values: ptr UncheckedArray[int64], at: int): bool =
  for d in 0 ..< 4:
    if values[at + d] < -8 or values[at + d] > 8 or
        values[at + 4 + d] < -8 or values[at + 4 + d] > 8 or
        values[at + d] >= values[at + 4 + d]:
      return false
  true

proc volumeAt(values: ptr UncheckedArray[int64], at: int): int64 =
  result = 1
  for d in 0 ..< 4: result *= values[at + 4 + d] - values[at + d]

proc penaltyAt(values: ptr UncheckedArray[int64], child, incoming: int): int64 =
  var joinedVolume = 1'i64
  for d in 0 ..< 4:
    let lo = min(values[child + d], values[incoming + d])
    let hi = max(values[child + 4 + d], values[incoming + 4 + d])
    joinedVolume *= hi - lo
  joinedVolume - volumeAt(values, child)

proc versabench_dbms_choose_entry*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "versabench_dbms_choose_entry".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength + 1): return -1
  let rawCount = values[0]
  if rawCount < 1 or rawCount > MaxChildren: return -1
  let count = int(rawCount)
  if length != csize_t(1 + 8 * count + 8): return -1
  let incoming = 1 + 8 * count
  for i in 0 ..< count:
    if not validBox(values, 1 + 8 * i): return -1
  if not validBox(values, incoming): return -1
  var best = 0
  var bestPenalty = penaltyAt(values, 1, incoming)
  for i in 1 ..< count:
    let candidate = penaltyAt(values, 1 + 8 * i, incoming)
    if candidate < bestPenalty:
      best = i
      bestPenalty = candidate
  int64(best)
