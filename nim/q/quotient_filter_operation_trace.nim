const Slots = 8
const MaxOperations = 32
const MaxItems = 6

type
  RemArray = array[Slots, uint8]
  FlagArray = array[Slots, bool]

proc nextSlot(i: int): int = (i + 1) mod Slots
proc prevSlot(i: int): int = (i + Slots - 1) mod Slots

proc emptySlot(i: int, rem: RemArray, occ, cont, shifted: FlagArray): bool =
  rem[i] == 0 and not occ[i] and not cont[i] and not shifted[i]

proc findRun(q: int, occ, cont, shifted: FlagArray, runStartOut: var int): int =
  if not occ[q]: return 0
  var bucket = q
  var steps = 0
  while shifted[bucket] and steps < Slots:
    bucket = prevSlot(bucket)
    inc steps
  if steps >= Slots: return -1
  var slot = bucket
  while bucket != q:
    slot = nextSlot(slot)
    steps = 0
    while cont[slot] and steps < Slots:
      slot = nextSlot(slot)
      inc steps
    if steps >= Slots: return -1
    bucket = nextSlot(bucket)
    steps = 0
    while not occ[bucket] and steps < Slots:
      bucket = nextSlot(bucket)
      inc steps
    if steps >= Slots: return -1
  runStartOut = slot
  1

proc findInsertPosition(q: int, occ, cont, shifted: FlagArray): int =
  var bucket = q
  var steps = 0
  while shifted[bucket] and steps < Slots:
    bucket = prevSlot(bucket)
    inc steps
  if steps >= Slots: return -1
  var slot = bucket
  while bucket != q:
    steps = 0
    while steps < Slots:
      slot = nextSlot(slot)
      inc steps
      if not cont[slot]: break
    if steps >= Slots: return -1
    bucket = nextSlot(bucket)
    steps = 0
    while bucket != q and not occ[bucket] and steps < Slots:
      bucket = nextSlot(bucket)
      inc steps
    if steps >= Slots: return -1
  slot

proc nextOccupied(q: int, occ: FlagArray): int =
  var bucket = nextSlot(q)
  for _ in 0 ..< Slots:
    if occ[bucket]: return bucket
    bucket = nextSlot(bucket)
  -1

proc insertAt(position, q: int, r: uint8, hasRun: bool, runStart: int,
              rem: var RemArray, occ, cont, shifted: var FlagArray): bool =
  let newCont = hasRun and position != runStart
  if hasRun and position == runStart: cont[position] = true
  var empty = position
  var foundEmpty = false
  for _ in 0 ..< Slots:
    if emptySlot(empty, rem, occ, cont, shifted):
      foundEmpty = true
      break
    empty = nextSlot(empty)
  if not foundEmpty: return false
  var slot = empty
  while slot != position:
    let previous = prevSlot(slot)
    rem[slot] = rem[previous]
    cont[slot] = cont[previous]
    shifted[slot] = true
    slot = previous
  rem[position] = r
  cont[position] = newCont
  shifted[position] = position != q
  occ[q] = true
  true

proc quotient_filter_operation_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 1 or length > 66: return -1
  let rawCount = input[0]
  if rawCount < 0 or rawCount > int64(MaxOperations) or int(length) != 1 + 2 * int(rawCount): return -1
  let count = int(rawCount)
  for op in 0 ..< count:
    let opcode = input[1 + 2 * op]
    let fp = input[2 + 2 * op]
    if opcode < 0 or opcode > 2 or fp < 0 or fp > 255: return -1
  if output.isNil or int(capacity) < count: return -2

  var rem: RemArray
  var occ, cont, shifted: FlagArray
  var statuses: array[MaxOperations, uint8]
  var total = 0
  for op in 0 ..< count:
    let opcode = input[1 + 2 * op]
    let fp = int(input[2 + 2 * op])
    let q = fp shr 5
    let r = uint8(fp and 31)
    if opcode == 0:
      if total == MaxItems:
        statuses[op] = 2
        continue
      var position = 0
      let hasRun = findRun(q, occ, cont, shifted, position)
      if hasRun < 0: return -1
      let runStart = position
      if hasRun != 0:
        for _ in 0 ..< Slots:
          if rem[position] > r: break
          let next = nextSlot(position)
          position = next
          if not cont[next]: break
      elif not emptySlot(q, rem, occ, cont, shifted):
        position = findInsertPosition(q, occ, cont, shifted)
        if position < 0: return -1
      else:
        position = q
      if not insertAt(position, q, r, hasRun != 0, runStart,
                      rem, occ, cont, shifted): return -1
      inc total
      statuses[op] = 1
    elif opcode == 1:
      var position = 0
      let hasRun = findRun(q, occ, cont, shifted, position)
      if hasRun < 0: return -1
      var found = false
      if hasRun != 0:
        for _ in 0 ..< Slots:
          if rem[position] == r:
            found = true
            break
          if rem[position] > r: break
          let next = nextSlot(position)
          if not cont[next]: break
          position = next
      statuses[op] = if found: 1'u8 else: 0'u8
    else:
      var position = 0
      let hasRun = findRun(q, occ, cont, shifted, position)
      if hasRun < 0: return -1
      var removed = false
      if hasRun != 0:
        for _ in 0 ..< Slots:
          if rem[position] == r:
            removed = true
            break
          if rem[position] > r: break
          let next = nextSlot(position)
          if not cont[next]: break
          position = next
      if not removed:
        statuses[op] = 0
        continue
      let wasRunStart = not cont[position]
      let following = nextSlot(position)
      let hasMoreSame = not emptySlot(following, rem, occ, cont, shifted) and cont[following]
      if wasRunStart and not hasMoreSame: occ[q] = false
      rem[position] = 0
      cont[position] = false
      shifted[position] = false
      var hole = position
      var currentQ = q
      var firstShift = true
      for _ in 0 ..< Slots - 1:
        let next = nextSlot(hole)
        if emptySlot(next, rem, occ, cont, shifted) or not shifted[next]: break
        let sourceCont = cont[next]
        let promote = firstShift and wasRunStart and hasMoreSame
        if not sourceCont and not promote:
          currentQ = nextOccupied(currentQ, occ)
          if currentQ < 0: return -1
        rem[hole] = rem[next]
        cont[hole] = if promote: false else: sourceCont
        shifted[hole] = cont[hole] or hole != currentQ
        rem[next] = 0
        cont[next] = false
        shifted[next] = false
        hole = next
        firstShift = false
      rem[hole] = 0
      cont[hole] = false
      shifted[hole] = false
      dec total
      statuses[op] = 1
  for i in 0 ..< count: output[i] = statuses[i]
  int64(count)
