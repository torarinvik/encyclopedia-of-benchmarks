const MaxTasks = 8
const MaxInput = 17
const MaxOutputBytes = 80

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc rate_monotonic_scheduling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rate_monotonic_scheduling".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > MaxTasks or int(length) != 1 + 2 * int(countValue): return -1
  let count = int(countValue)
  var execution, period: array[MaxTasks, int64]
  var order: array[MaxTasks, int]
  var response: array[MaxTasks, int64]
  for task in 0 ..< count:
    execution[task] = input[1 + 2 * task]
    period[task] = input[2 + 2 * task]
    if execution[task] < 1 or execution[task] > 16 or period[task] < 1 or period[task] > 32: return -1
    order[task] = task
    response[task] = -1
  for index in 1 ..< count:
    let key = order[index]
    var position = index
    while position > 0 and (period[order[position - 1]] > period[key] or
        period[order[position - 1]] == period[key] and order[position - 1] > key):
      order[position] = order[position - 1]
      dec position
    order[position] = key

  var schedulable = 1'i64
  var failedTask = -1'i64
  for rank in 0 ..< count:
    let target = order[rank]
    var remainingTarget = execution[target]
    var active: array[MaxTasks, int64]
    var elapsed = 0'i64
    while remainingTarget > 0 and elapsed < period[target]:
      for higherRank in 0 ..< rank:
        let higher = order[higherRank]
        if elapsed mod period[higher] == 0: active[higher] += execution[higher]
      var selected = -1
      for higherRank in 0 ..< rank:
        let higher = order[higherRank]
        if active[higher] > 0:
          selected = higher
          break
      if selected >= 0: dec active[selected]
      else: dec remainingTarget
      inc elapsed
    if remainingTarget > 0:
      schedulable = 0
      failedTask = int64(target)
      break
    response[target] = elapsed

  let outputBytes = 8 * (count + 2)
  if output.isNil or int(capacity) < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  storeI64Le(addr staged[0], 0, schedulable)
  storeI64Le(addr staged[0], 8, failedTask)
  for task in 0 ..< count: storeI64Le(addr staged[0], 8 * (task + 2), response[task])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
