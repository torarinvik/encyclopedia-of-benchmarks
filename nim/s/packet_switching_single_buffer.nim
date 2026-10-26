const MaxPackets = 16
const MaxSlots = 8
const MaxInput = 38
const MaxOutputBytes = 64
const Beta = 15'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc erasePacket(ids: var array[MaxPackets, int64], values: var array[MaxPackets, int64],
    count: var int, index: int) =
  for position in index ..< count - 1:
    ids[position] = ids[position + 1]
    values[position] = values[position + 1]
  dec count

proc packet_switching_single_buffer*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "packet_switching_single_buffer".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInput): return -1
  let mode = input[0]
  let buffer = input[1]
  let beta = input[2]
  let slotsValue = input[3]
  let countValue = input[4]
  if mode < 0 or mode > 2 or buffer < 1 or buffer > 4 or slotsValue < 1 or slotsValue > int64(MaxSlots) or
      countValue < 0 or countValue > int64(MaxPackets) or int(length) != 5 + 2 * int(countValue) or
      (mode == 0 and beta != 0) or (mode != 0 and beta != Beta): return -1
  let slots = int(slotsValue)
  let packetCount = int(countValue)
  var arrivals, packetValues: array[MaxPackets, int64]
  var previousSlot = -1'i64
  for packet in 0 ..< packetCount:
    arrivals[packet] = input[5 + 2 * packet]
    packetValues[packet] = input[6 + 2 * packet]
    if arrivals[packet] < 0 or arrivals[packet] >= slotsValue or arrivals[packet] < previousSlot or
        packetValues[packet] < 1 or packetValues[packet] > 100: return -1
    previousSlot = arrivals[packet]
  var residentIds, residentValues: array[MaxPackets, int64]
  var schedule: array[MaxSlots, int64]
  var residentCount = 0
  var nextPacket = 0
  for slot in 0 ..< slots:
    while nextPacket < packetCount and arrivals[nextPacket] == int64(slot):
      let value = packetValues[nextPacket]
      var preempt = residentCount
      if mode == 1:
        for index in 0 ..< residentCount:
          if residentValues[index] * Beta <= value:
            preempt = index
            break
      elif mode == 2:
        for index in 0 ..< residentCount:
          let followingOk = index + 1 == residentCount or residentValues[index] <= residentValues[index + 1]
          if residentValues[index] * Beta < value and followingOk:
            preempt = index
            break
      if preempt < residentCount:
        erasePacket(residentIds, residentValues, residentCount, preempt)
        residentIds[residentCount] = int64(nextPacket)
        residentValues[residentCount] = value
        inc residentCount
      elif residentCount < int(buffer):
        residentIds[residentCount] = int64(nextPacket)
        residentValues[residentCount] = value
        inc residentCount
      else:
        var smallest = residentValues[0]
        for index in 1 ..< residentCount:
          if residentValues[index] < smallest: smallest = residentValues[index]
        if value > smallest:
          var evict = 0
          while residentValues[evict] != smallest: inc evict
          erasePacket(residentIds, residentValues, residentCount, evict)
          residentIds[residentCount] = int64(nextPacket)
          residentValues[residentCount] = value
          inc residentCount
      inc nextPacket
    if residentCount > 0:
      schedule[slot] = residentIds[0]
      erasePacket(residentIds, residentValues, residentCount, 0)
    else:
      schedule[slot] = -1
  let outputBytes = 8 * slots
  if output.isNil or int(capacity) < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  for slot in 0 ..< slots: storeI64Le(addr staged[0], 8 * slot, schedule[slot])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
