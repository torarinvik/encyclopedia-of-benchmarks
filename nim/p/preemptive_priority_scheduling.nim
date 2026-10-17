const MaxProcesses = 8
const MaxScheduleTicks = 80
const MaxOutputWords = 81

proc putI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc preemptive_priority_scheduling*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "preemptive_priority_scheduling".} =
  if input == nil or length < 1 or length > 33: return -1
  let processCount = input[0]
  if processCount < 0 or processCount > MaxProcesses or length != csize_t(1 + 4 * processCount): return -1

  var ids, arrivals, remaining, priorities: array[MaxProcesses, int32]
  var seenIds: array[MaxProcesses, bool]
  for i in 0 ..< int(processCount):
    let offset = 1 + 4 * i
    let id = input[offset]
    let arrival = input[offset + 1]
    let burst = input[offset + 2]
    let priority = input[offset + 3]
    if id < 0 or id >= MaxProcesses or seenIds[int(id)] or arrival < 0 or arrival > 16 or burst < 1 or burst > 8: return -1
    for previous in 0 ..< i:
      if priorities[previous] == priority and arrivals[previous] == arrival: return -1
    seenIds[int(id)] = true
    ids[i] = id
    arrivals[i] = arrival
    remaining[i] = burst
    priorities[i] = priority

  var schedule: array[MaxScheduleTicks, int32]
  var tickCount = 0
  var completed = 0
  while completed < int(processCount):
    var best = int(processCount)
    for i in 0 ..< int(processCount):
      if remaining[i] <= 0 or arrivals[i] > int32(tickCount): continue
      if best == int(processCount) or priorities[i] > priorities[best] or
          (priorities[i] == priorities[best] and arrivals[i] < arrivals[best]): best = i
    if best == int(processCount):
      schedule[tickCount] = -1
    else:
      schedule[tickCount] = ids[best]
      dec remaining[best]
      if remaining[best] == 0: inc completed
    inc tickCount

  let bytes = (1 + tickCount) * 4
  if output == nil or capacity < csize_t(bytes): return -2
  var buffer: array[MaxOutputWords * 4, uint8]
  putI32Le(addr buffer[0], 0, int32(tickCount))
  for i in 0 ..< tickCount: putI32Le(addr buffer[0], 4 * (i + 1), schedule[i])
  for i in 0 ..< bytes: output[i] = buffer[i]
  int64(bytes)
