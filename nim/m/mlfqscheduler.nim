proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc mlfqscheduler*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mlfqscheduler".} =
  if input == nil or length < 2 or length > 55: return -1
  let levelsValue = input[0]
  let processCountValue = input[1]
  if levelsValue < 1 or levelsValue > 4 or processCountValue < 0 or processCountValue > 16: return -1
  let levels = int(levelsValue)
  let processCount = int(processCountValue)
  if length != csize_t(2 + levels + 3 * processCount): return -1
  var quanta: array[4, int64]
  var pids: array[16, int64]
  var remaining: array[16, int64]
  for level in 0 ..< levels:
    quanta[level] = input[2 + level]
    if quanta[level] < 1 or quanta[level] > 32: return -1
  let processOffset = 2 + levels
  for i in 0 ..< processCount:
    let pid = input[processOffset + 3 * i]
    let burst = input[processOffset + 3 * i + 1]
    let arrival = input[processOffset + 3 * i + 2]
    if pid < -2_147_483_648'i64 or pid > 2_147_483_647'i64 or burst < 0 or burst > 1000 or arrival < 0 or arrival > 1_000_000: return -1
    pids[i] = pid
    remaining[i] = burst

  var queues: array[64, int]
  var queueCounts: array[4, int]
  for i in 0 ..< processCount: queues[i] = i
  queueCounts[0] = processCount
  var completionPids: array[16, int64]
  var completionTimes: array[16, int64]
  var completions = 0
  var currentTime = 0'i64
  while true:
    var active = 0
    for level in 0 ..< levels: active += queueCounts[level]
    if active == 0: break
    for level in 0 ..< levels:
      let base = level * 16
      let queued = queueCounts[level]
      if queued == 0: continue
      let process = queues[base]
      for j in 1 ..< queued: queues[base + j - 1] = queues[base + j]
      dec queueCounts[level]
      let slice = if quanta[level] < remaining[process]: quanta[level] else: remaining[process]
      currentTime += slice
      remaining[process] -= slice
      if remaining[process] == 0:
        completionPids[completions] = pids[process]
        completionTimes[completions] = currentTime
        inc completions
      else:
        let destination = if level + 1 < levels: level + 1 else: level
        queues[destination * 16 + queueCounts[destination]] = process
        inc queueCounts[destination]

  let elements = 2 + 2 * completions
  let required = elements * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  putI64Le(output, 0, currentTime)
  putI64Le(output, 8, int64(completions))
  for i in 0 ..< completions:
    putI64Le(output, 16 + 16 * i, completionPids[i])
    putI64Le(output, 24 + 16 * i, completionTimes[i])
  int64(elements)
