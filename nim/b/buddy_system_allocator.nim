const Arena = 256
const MaxOrder = 8
const MaxOps = 64
const MaxIds = 32
const MaxInputWords = 194
const MaxOutputWords = 3 * MaxOps + 1 + 2 * Arena

type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

proc buddy_system_allocator*(values: I64Input, length: csize_t, output: ByteOutput,
                             capacity: csize_t): int64 {.cdecl, exportc: "buddy_system_allocator".} =
  if values == nil or length < 1 or length > MaxInputWords: return -1
  let rawCount = values[0]
  if rawCount < 0 or rawCount > MaxOps or length != csize_t(1 + 3 * rawCount): return -1
  let operationCount = int(rawCount)

  var freeBlocks: array[MaxOrder + 1, array[Arena, bool]]
  var active: array[MaxIds, bool]
  var allocationBase: array[MaxIds, int]
  var allocationOrder: array[MaxIds, int]
  var staged: array[MaxOutputWords, int64]
  freeBlocks[MaxOrder][0] = true
  var stagedWords = 0

  for i in 0 ..< operationCount:
    let opcode = values[1 + 3 * i]
    let rawId = values[2 + 3 * i]
    let argument = values[3 + 3 * i]
    if rawId < 0 or rawId >= MaxIds: return -1
    let id = int(rawId)
    if opcode == 0:
      if argument < 1 or argument > Arena or active[id]: return -1
      var target = 0
      var rounded = 1
      while rounded < int(argument):
        rounded = rounded * 2
        inc target
      var foundOrder = MaxOrder + 1
      var foundBase = Arena
      for order in target .. MaxOrder:
        let blockSize = 1 shl order
        var base = 0
        while base + blockSize <= Arena:
          if freeBlocks[order][base]:
            foundOrder = order
            foundBase = base
            break
          base += blockSize
        if foundOrder <= MaxOrder: break
      if foundOrder > MaxOrder:
        staged[stagedWords] = 0; staged[stagedWords + 1] = -1; staged[stagedWords + 2] = 0
        stagedWords += 3
        continue
      freeBlocks[foundOrder][foundBase] = false
      while foundOrder > target:
        dec foundOrder
        let half = 1 shl foundOrder
        freeBlocks[foundOrder][foundBase + half] = true
      active[id] = true
      allocationBase[id] = foundBase
      allocationOrder[id] = target
      staged[stagedWords] = 1
      staged[stagedWords + 1] = int64(foundBase)
      staged[stagedWords + 2] = int64(1 shl target)
      stagedWords += 3
    elif opcode == 1:
      if argument != 0 or not active[id]: return -1
      let originalBase = allocationBase[id]
      let originalOrder = allocationOrder[id]
      let originalSize = 1 shl originalOrder
      active[id] = false
      var base = originalBase
      var order = originalOrder
      while order < MaxOrder:
        let buddy = base xor (1 shl order)
        if not freeBlocks[order][buddy]: break
        freeBlocks[order][buddy] = false
        if buddy < base: base = buddy
        inc order
      freeBlocks[order][base] = true
      staged[stagedWords] = 1
      staged[stagedWords + 1] = int64(originalBase)
      staged[stagedWords + 2] = int64(originalSize)
      stagedWords += 3
    else: return -1

  let countIndex = stagedWords
  staged[stagedWords] = 0
  inc stagedWords
  for base in 0 ..< Arena:
    for order in countdown(MaxOrder, 0):
      if freeBlocks[order][base]:
        inc staged[countIndex]
        staged[stagedWords] = int64(base)
        staged[stagedWords + 1] = int64(1 shl order)
        stagedWords += 2
        break
  let required = csize_t(stagedWords * 8)
  if output == nil or capacity < required: return -2
  for i in 0 ..< stagedWords:
    let bits = cast[uint64](staged[i])
    for byte in 0 ..< 8:
      output[8 * i + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(required)
