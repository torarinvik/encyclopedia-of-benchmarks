const MaxQ = 32
const MaxTags = 64
const MaxInput = 129

proc observed_remove_set*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "observed_remove_set".} =
  if packed.isNil or length < 1 or length > MaxInput: return -1
  let qv = packed[0]
  if qv < 0 or qv > MaxQ or length != csize_t(1 + qv * 4): return -1
  let q = int(qv)
  for i in 0 ..< q:
    let op = packed[1 + 4 * i]
    let replica = packed[2 + 4 * i]
    let element = packed[3 + 4 * i]
    let peer = packed[4 + 4 * i]
    if op >= 0 and op <= 2:
      if replica < 0 or replica > 1 or element < 0 or element > 15 or peer != 0: return -1
    elif op == 3 or op == 4:
      if replica < 0 or replica > 1 or element != 0 or peer < 0 or peer > 1: return -1
    else:
      return -1

  var used: array[MaxTags, bool]
  var tagElement: array[MaxTags, int64]
  var nextSequence: array[2, int]
  var additions: array[2 * MaxTags, bool]
  var removals: array[2 * MaxTags, bool]
  var answer = 0'u64
  var readCount = 0
  for i in 0 ..< q:
    let op = packed[1 + 4 * i]
    let replica = int(packed[2 + 4 * i])
    let element = packed[3 + 4 * i]
    let peer = int(packed[4 + 4 * i])
    let base = replica * MaxTags
    let peerBase = peer * MaxTags
    var result = false
    if op == 0:
      let tag = replica * MaxQ + nextSequence[replica]
      inc nextSequence[replica]
      used[tag] = true
      tagElement[tag] = element
      additions[base + tag] = true
    elif op == 1:
      for tag in 0 ..< MaxTags:
        if additions[base + tag] and not removals[base + tag] and used[tag] and tagElement[tag] == element:
          removals[base + tag] = true
    elif op == 2:
      for tag in 0 ..< MaxTags:
        if additions[base + tag] and not removals[base + tag] and used[tag] and tagElement[tag] == element:
          result = true
    elif op == 3:
      for tag in 0 ..< MaxTags:
        additions[base + tag] = additions[base + tag] or additions[peerBase + tag]
        removals[base + tag] = removals[base + tag] or removals[peerBase + tag]
    else:
      result = true
      for tag in 0 ..< MaxTags:
        if (additions[base + tag] and not additions[peerBase + tag]) or
            (removals[base + tag] and not removals[peerBase + tag]): result = false
    if op == 2 or op == 4:
      if result: answer = answer or (1'u64 shl readCount)
      inc readCount
  int64(answer)
