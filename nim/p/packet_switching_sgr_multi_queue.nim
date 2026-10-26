const MaxQueues = 4
const MaxSlots = 8
const MaxInput = 36
const MaxOutputBytes = 64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc packet_switching_sgr_multi_queue*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "packet_switching_sgr_multi_queue".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let queueValue = input[0]
  let buffer = input[1]
  let slotsValue = input[2]
  if queueValue < 2 or queueValue > int64(MaxQueues) or buffer < 1 or buffer > int64(MaxQueues) or
      slotsValue < 1 or slotsValue > int64(MaxSlots): return -1
  let queues = int(queueValue)
  let slots = int(slotsValue)
  if int(length) != 3 + queues * slots: return -1
  var loads, peaks: array[MaxQueues, int64]
  var schedule: array[MaxSlots, int64]
  for slot in 0 ..< slots:
    for queue in 0 ..< queues:
      let arrivals = input[3 + slot * queues + queue]
      if arrivals < 0 or arrivals > buffer: return -1
      loads[queue] += arrivals
      if loads[queue] > buffer: loads[queue] = buffer
      if loads[queue] > peaks[queue]: peaks[queue] = loads[queue]
    var hasLarge, hasNonempty, hasUnderfullPeak = false
    for queue in 0 ..< queues:
      if loads[queue] > 0:
        hasNonempty = true
        if loads[queue] > buffer div 2: hasLarge = true
        if peaks[queue] < buffer: hasUnderfullPeak = true
    if not hasNonempty:
      schedule[slot] = -1
      for queue in 0 ..< queues: peaks[queue] = 0
      continue
    let useHistory = not hasLarge and hasUnderfullPeak
    var selected = queues
    for queue in 0 ..< queues:
      if loads[queue] == 0 or (useHistory and peaks[queue] >= buffer): continue
      if selected == queues or loads[queue] > loads[selected]: selected = queue
    schedule[slot] = int64(selected)
    dec loads[selected]
    var anyLeft = false
    for queue in 0 ..< queues:
      if loads[queue] > 0: anyLeft = true
    if not anyLeft:
      for queue in 0 ..< queues: peaks[queue] = 0
  let outputBytes = 8 * slots
  if output.isNil or int(capacity) < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  for slot in 0 ..< slots: storeI64Le(addr staged[0], 8 * slot, schedule[slot])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
