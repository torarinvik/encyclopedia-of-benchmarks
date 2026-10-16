type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc betterChoice(mode: int64, candidate, best: int,
                  arrival, burst, remaining, priority: openArray[int64]): bool =
  if mode == 1:
    return burst[candidate] < burst[best] or
      (burst[candidate] == burst[best] and (arrival[candidate] < arrival[best] or
       (arrival[candidate] == arrival[best] and candidate < best)))
  if mode == 2:
    return remaining[candidate] < remaining[best] or
      (remaining[candidate] == remaining[best] and (arrival[candidate] < arrival[best] or
       (arrival[candidate] == arrival[best] and candidate < best)))
  priority[candidate] < priority[best] or
    (priority[candidate] == priority[best] and candidate < best)

proc cpu_scheduling_algorithms*(input: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "cpu_scheduling_algorithms".} =
  if input == nil or length < 3 or length > csize_t(3 + 4 * 32): return -1
  let mode = input[0]
  let rawCount = input[1]
  let quantum = input[2]
  if mode < 0 or mode > 5 or rawCount < 0 or rawCount > 32 or quantum < 1 or quantum > 32: return -1
  let count = int(rawCount)
  if length != csize_t(3 + 4 * count): return -1

  var ids, arrival, burst, priority, remaining: array[32, int64]
  var completion, firstRun: array[32, int64]
  var order: array[32, int]
  for i in 0..<count:
    let base = 3 + 4 * i
    ids[i] = input[base]
    arrival[i] = input[base + 1]
    burst[i] = input[base + 2]
    priority[i] = input[base + 3]
    if ids[i] < 0 or ids[i] >= 32 or arrival[i] < 0 or arrival[i] > 256 or
        burst[i] < 1 or burst[i] > 32 or priority[i] < -32 or priority[i] > 32: return -1
    for j in 0..<i:
      if ids[j] == ids[i]: return -1
    remaining[i] = burst[i]
    completion[i] = -1
    firstRun[i] = -1
    order[i] = i
  let bytes = count * 56
  if bytes > 0 and (output == nil or capacity < csize_t(bytes)): return -2

  if mode == 0 or mode == 5:
    for i in 1..<count:
      let key = order[i]
      var j = i
      while j > 0 and arrival[order[j - 1]] > arrival[key]:
        order[j] = order[j - 1]
        dec j
      order[j] = key

  var time = 0'i64
  if mode == 0:
    for position in 0..<count:
      let i = order[position]
      if time < arrival[i]: time = arrival[i]
      firstRun[i] = time
      time += burst[i]
      completion[i] = time
  elif mode == 1 or mode == 3:
    var done = 0
    while done < count:
      var best = count
      for i in 0..<count:
        if completion[i] >= 0 or arrival[i] > time: continue
        if best == count or betterChoice(mode, i, best, arrival, burst, remaining, priority): best = i
      if best == count:
        inc time
        continue
      firstRun[best] = time
      time += burst[best]
      completion[best] = time
      inc done
  elif mode == 2 or mode == 4:
    var done = 0
    while done < count:
      var best = count
      for i in 0..<count:
        if remaining[i] <= 0 or arrival[i] > time: continue
        if best == count or betterChoice(mode, i, best, arrival, burst, remaining, priority): best = i
      if best == count:
        inc time
        continue
      if firstRun[best] < 0: firstRun[best] = time
      dec remaining[best]
      inc time
      if remaining[best] == 0:
        completion[best] = time
        inc done
  else:
    var queue: array[64, int]
    var head, tail, queueSize, nextArrival, done = 0
    while done < count:
      while nextArrival < count and arrival[order[nextArrival]] <= time:
        queue[tail] = order[nextArrival]
        inc nextArrival
        tail = (tail + 1) mod 64
        inc queueSize
      if queueSize == 0:
        inc time
        continue
      let current = queue[head]
      head = (head + 1) mod 64
      dec queueSize
      let runFor = min(quantum, remaining[current])
      for slot in 0..<int(runFor):
        if firstRun[current] < 0: firstRun[current] = time
        dec remaining[current]
        inc time
        while nextArrival < count and arrival[order[nextArrival]] <= time:
          queue[tail] = order[nextArrival]
          inc nextArrival
          tail = (tail + 1) mod 64
          inc queueSize
      if remaining[current] > 0:
        queue[tail] = current
        tail = (tail + 1) mod 64
        inc queueSize
      else:
        completion[current] = time
        inc done

  for i in 0..<count:
    let turnaround = completion[i] - arrival[i]
    let fields = [ids[i], arrival[i], burst[i], completion[i], turnaround,
                  turnaround - burst[i], firstRun[i] - arrival[i]]
    for field in 0..<7: putI64Le(output, i * 56 + field * 8, fields[field])
  int64(bytes)
