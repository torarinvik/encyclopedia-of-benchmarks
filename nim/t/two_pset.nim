const MaxQ = 256
const MaxInput = 1025
const HashMultiplier = 1_000_003'i64
const HashModulus = 1_000_000_007'i64

proc two_pset*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "two_pset".} =
  if packed.isNil or length < 1 or length > MaxInput: return -1
  let qv = packed[0]
  if qv < 0 or qv > MaxQ or length != csize_t(1 + qv * 4): return -1
  let q = int(qv)
  for i in 0 ..< q:
    let op = packed[1 + i * 4]
    let setId = packed[2 + i * 4]
    let value = packed[3 + i * 4]
    let otherId = packed[4 + i * 4]
    if op >= 0 and op <= 2:
      if setId < 0 or setId > 1 or value < 0 or value > 63 or otherId != 0: return -1
    elif op == 3 or op == 4:
      if setId < 0 or setId > 1 or value != 0 or otherId < 0 or otherId > 1: return -1
    else:
      return -1

  var additions: array[128, int64]
  var tombstones: array[128, int64]
  var digest = 0'i64
  for i in 0 ..< q:
    let op = packed[1 + i * 4]
    let setId = int(packed[2 + i * 4])
    let value = packed[3 + i * 4]
    let otherId = int(packed[4 + i * 4])
    let base = setId * 64
    var operationResult = 0'i64
    if op == 0:
      additions[base + int(value)] = 1
    elif op == 1:
      let index = base + int(value)
      if additions[index] != 0 and tombstones[index] == 0: tombstones[index] = 1
    elif op == 2:
      let index = base + int(value)
      if additions[index] != 0 and tombstones[index] == 0: operationResult = 1
    elif op == 3:
      let otherBase = otherId * 64
      var subset = true
      for e in 0 ..< 64:
        if (additions[base + e] != 0 and additions[otherBase + e] == 0) or
           (tombstones[base + e] != 0 and tombstones[otherBase + e] == 0):
          subset = false
      if subset: operationResult = 1
    else:
      let otherBase = otherId * 64
      for e in 0 ..< 64:
        if additions[base + e] != 0 or additions[otherBase + e] != 0: additions[base + e] = 1
        if tombstones[base + e] != 0 or tombstones[otherBase + e] != 0: tombstones[base + e] = 1

    digest = (digest * HashMultiplier + op) mod HashModulus
    digest = (digest * HashMultiplier + operationResult) mod HashModulus
  for setId in 0 ..< 2:
    let base = setId * 64
    for e in 0 ..< 64:
      digest = (digest * HashMultiplier + additions[base + e]) mod HashModulus
    for e in 0 ..< 64:
      digest = (digest * HashMultiplier + tombstones[base + e]) mod HashModulus
  digest
