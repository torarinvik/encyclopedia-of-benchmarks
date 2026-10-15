proc storeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[position + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc fcfs_scheduling*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "fcfs_scheduling".} =
  if values.isNil or length < 1 or length > 193: return -2
  if values[0] < 0 or values[0] > 64: return -2
  let count = int(values[0])
  if int(length) != 1 + 3 * count: return -2

  var ids: array[64, int64]
  var arrivals: array[64, int64]
  var bursts: array[64, int64]
  var order: array[64, int]
  for i in 0 ..< count:
    let id = values[1 + 3 * i]
    let arrival = values[2 + 3 * i]
    let burst = values[3 + 3 * i]
    if id < 0 or id > 63 or arrival < 0 or arrival > 1_000_000 or burst < 1 or burst > 1_000_000:
      return -2
    for previous in 0 ..< i:
      if ids[previous] == id: return -2
    ids[i] = id
    arrivals[i] = arrival
    bursts[i] = burst
    order[i] = i
  for i in 1 ..< count:
    let key = order[i]
    var j = i
    while j > 0 and (arrivals[order[j - 1]] > arrivals[key] or
        (arrivals[order[j - 1]] == arrivals[key] and ids[order[j - 1]] > ids[key])):
      order[j] = order[j - 1]
      dec j
    order[j] = key

  let required = count * 48
  if int(outputCapacity) < required or (required != 0 and output.isNil): return -2
  var elapsed = 0'i64
  for position in 0 ..< count:
    let i = order[position]
    if elapsed < arrivals[i]: elapsed = arrivals[i]
    let completion = elapsed + bursts[i]
    let turnaround = completion - arrivals[i]
    let waiting = turnaround - bursts[i]
    let fields = [ids[i], arrivals[i], bursts[i], completion, turnaround, waiting]
    for field in 0 ..< 6:
      storeI64Le(output, position * 48 + field * 8, fields[field])
    elapsed = completion
  int64(count)
