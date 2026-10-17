const MaxActions = 4096
const MaxEvents = 1024
const MaxEventId = 4_294_967_295'u64
const FnvPrime = 1_099_511_628_211'u64

proc hashWord(hashInput, word: uint64): uint64 =
  var hash = hashInput
  for byte in 0 ..< 8:
    hash = hash xor ((word shr (8 * byte)) and 255'u64)
    hash = hash *% FnvPrime
  hash

proc time_simulation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "time_simulation".} =
  if values == nil or length < 1 or length > 8194: return -1
  let count = values[0]
  if count < 0 or count > MaxActions or int(length) != 1 + 2 * int(count): return -1
  var hash = hashWord(14_695_981_039_346_656_037'u64, uint64(count))
  var now = 0'i64
  var nextId = 1'u64
  var activeCount, totalProcessed, firedCount = 0
  var active: array[MaxEvents, bool]
  var timestamps: array[MaxEvents, int64]
  var eventIds: array[MaxEvents, uint64]
  # Reused queue slots can fire repeatedly, so trace storage spans all actions.
  var firedIds: array[MaxActions, uint64]
  var firedTimes: array[MaxActions, int64]
  for action in 0 ..< int(count):
    let opcode = values[1 + 2 * action]
    let operand = values[2 + 2 * action]
    var result = 0'u64
    if opcode == 0:
      if operand < 0 or operand < now: return -1
      if activeCount < MaxEvents:
        var slot = 0
        while active[slot]: inc slot
        eventIds[slot] = nextId; timestamps[slot] = operand; active[slot] = true; inc activeCount
        result = nextId; inc nextId
        if nextId > MaxEventId: nextId = 1
    elif opcode == 1:
      if operand < 1 or uint64(operand) > MaxEventId: return -1
      for slot in 0 ..< MaxEvents:
        if active[slot] and eventIds[slot] == uint64(operand):
          active[slot] = false; dec activeCount; result = 1; break
    elif opcode == 2:
      if operand < 0 or operand < now: return -1
      var processed = 0'u64
      while true:
        var chosen = -1
        var earliest = 0'i64
        for slot in 0 ..< MaxEvents:
          if active[slot] and timestamps[slot] <= operand and (chosen < 0 or timestamps[slot] < earliest):
            chosen = slot; earliest = timestamps[slot]
        if chosen < 0: break
        now = timestamps[chosen]; active[chosen] = false; dec activeCount
        firedIds[firedCount] = eventIds[chosen]; firedTimes[firedCount] = timestamps[chosen]; inc firedCount
        inc processed; inc totalProcessed
      now = operand; result = processed
    elif opcode == 3:
      if operand != 0: return -1
      result = uint64(now)
    elif opcode == 4:
      if operand != 0: return -1
      result = if activeCount == 0: 1'u64 else: 0'u64
    else: return -1
    hash = hashWord(hash, result)
  hash = hashWord(hash, uint64(firedCount))
  for i in 0 ..< firedCount:
    hash = hashWord(hash, firedIds[i]); hash = hashWord(hash, uint64(firedTimes[i]))
  hash = hashWord(hash, uint64(now)); hash = hashWord(hash, uint64(activeCount)); hash = hashWord(hash, uint64(totalProcessed))
  int64(hash and 0x7FFF_FFFF_FFFF_FFFF'u64)
