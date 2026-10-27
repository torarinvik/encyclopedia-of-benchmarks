const MaxJobs = 8
const MaxInput = 18
const MaxOutput = 112

proc shortest_elapsed_time_first*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "shortest_elapsed_time_first".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  if n64 < 0 or n64 > int64(MaxJobs) or int64(length) != 1 + 2 * n64: return -1
  let n = int(n64)
  var release, remaining, attained: array[MaxJobs, int64]
  for job in 0..<n:
    release[job] = input[1 + 2 * job]
    remaining[job] = input[2 + 2 * job]
    if release[job] < 0 or release[job] > 16 or remaining[job] < 1 or remaining[job] > 12: return -1
  if output.isNil: return -2
  var trace: array[MaxOutput, uint8]
  var time = 0
  var completed = 0
  while completed < n and time < MaxOutput:
    var chosen = n
    for job in 0..<n:
      if release[job] <= int64(time) and remaining[job] > 0 and
          (chosen == n or attained[job] < attained[chosen]): chosen = job
    if chosen < n:
      trace[time] = uint8(chosen + 1)
      inc attained[chosen]
      dec remaining[chosen]
      if remaining[chosen] == 0: inc completed
    inc time
  if completed != n: return -1
  if capacity < csize_t(time): return -2
  for t in 0..<time: output[t] = trace[t]
  int64(time)
