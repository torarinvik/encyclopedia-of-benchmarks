proc assign(job: int, release, deadline: array[32, int], slots: var array[32, int], seen: var array[32, bool]): bool =
  for slot in release[job] .. deadline[job]:
    if seen[slot]: continue
    seen[slot] = true
    if slots[slot] == -1 or assign(slots[slot], release, deadline, slots, seen):
      slots[slot] = job
      return true
  false

proc unit_job_release_deadline_weighted_matching*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "unit_job_release_deadline_weighted_matching".} =
  if input.isNil or length < 1 or length > 98: return -1
  if input[0] < 0 or input[0] > 32: return -1
  let n = int(input[0])
  if length != csize_t(1 + 3*n): return -1
  var release, deadline, slots, order: array[32, int]
  var weight: array[32, int64]
  for slot in 0 ..< 32: slots[slot] = -1
  for i in 0 ..< n:
    let r = input[1+3*i]; let d = input[2+3*i]; let w = input[3+3*i]
    if r < 0 or d < r or d >= 32 or w < 0 or w > 1_000_000: return -1
    release[i] = int(r); deadline[i] = int(d); weight[i] = w
    var j = i
    while j > 0 and weight[order[j-1]] < w:
      order[j] = order[j-1]
      dec j
    order[j] = i
  var total = 0'i64
  for i in 0 ..< n:
    var seen: array[32, bool]
    let job = order[i]
    if assign(job, release, deadline, slots, seen): total += weight[job]
  total
