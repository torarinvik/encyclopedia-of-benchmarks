const MaxQueues = 4
const MaxBuffer = 4
const MaxSlots = 8
const MaxParseableInput = 68
const MaxOutputBytes = 64

type Tag = object
  priority: int64
  marked: bool

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc packet_switching_random_schedule*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "packet_switching_random_schedule".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxParseableInput): return -1
  let mValue = input[0]
  let bValue = input[1]
  let slotsValue = input[2]
  if mValue < 2 or mValue > int64(MaxQueues) or bValue < 1 or bValue > int64(MaxBuffer) or
      slotsValue < 1 or slotsValue > int64(MaxSlots): return -1
  let m = int(mValue)
  let b = int(bValue)
  let slots = int(slotsValue)
  let cells = m * slots
  if int(length) != 3 + 2 * cells: return -1
  for cell in 0 ..< cells:
    let flag = input[3 + cell]
    let priority = input[3 + cells + cell]
    if flag < 0 or flag > 1 or priority < 0 or priority > 4_294_967_295'i64: return -1
  var load: array[MaxQueues, int]
  var count: array[MaxQueues, int]
  var tags: array[MaxQueues, array[MaxBuffer, Tag]]
  var trace: array[MaxSlots, int64]
  for slot in 0 ..< slots:
    for q in 0 ..< m:
      let cell = slot * m + q
      if input[3 + cell] == 0 or load[q] == b: continue
      if count[q] == b:
        for i in 1 ..< count[q]: tags[q][i - 1] = tags[q][i]
        dec count[q]
      tags[q][count[q]] = Tag(priority: input[3 + cells + cell], marked: false)
      inc count[q]
      inc load[q]
    var bestQ = m
    var bestI = 0
    var bestPriority = -1'i64
    for q in 0 ..< m:
      for i in 0 ..< count[q]:
        if tags[q][i].marked: continue
        if bestQ == m or tags[q][i].priority > bestPriority:
          bestQ = q
          bestI = i
          bestPriority = tags[q][i].priority
    if bestQ < m:
      tags[bestQ][bestI].marked = true
    else:
      bestQ = m
      for q in 0 ..< m:
        if load[q] > 0:
          bestQ = q
          break
    if bestQ == m: trace[slot] = -1
    else:
      trace[slot] = int64(bestQ)
      dec load[bestQ]
  let outputBytes = 8 * slots
  if output.isNil or int(capacity) < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  for slot in 0 ..< slots: storeI64Le(addr staged[0], 8 * slot, trace[slot])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
