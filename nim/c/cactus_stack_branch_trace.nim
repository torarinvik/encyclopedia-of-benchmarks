proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc normalize(headStart: int, kinds: var array[48, int], lives: var array[48, bool],
              nexts: var array[48, int]): int =
  var head = headStart
  while head >= 0 and kinds[head] == 1 and not lives[head]:
    head = nexts[head]
  head

proc topValue(headStart: int, kinds: var array[48, int], lives: var array[48, bool],
              nexts: var array[48, int], values: var array[48, int64]): tuple[ok: bool, value: int64] =
  var head = normalize(headStart, kinds, lives, nexts)
  while head >= 0 and kinds[head] == 1:
    head = normalize(nexts[head], kinds, lives, nexts)
  if head < 0: (false, 0'i64) else: (true, values[head])

proc cactus_stack_branch_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "cactus_stack_branch_trace".} =
  if input == nil or length < 1 or length > 146: return -1
  let qWord = input[0]
  if qWord < 0 or qWord > 48 or int(length) != 1 + 3 * int(qWord): return -1
  let q = int(qWord)
  for i in 0 ..< q:
    let op = input[1 + 3*i]
    let a = input[2 + 3*i]
    let b = input[3 + 3*i]
    if op == 0:
      if a < 0 or a >= 8 or b < -1000 or b > 1000: return -1
    elif op >= 1 and op <= 3:
      if a < 0 or a >= 8 or b != 0: return -1
    elif op == 4:
      if a < 0 or a >= 8 or b < 0 or b >= 8: return -1
    else: return -1

  var nodeValues: array[48, int64]
  var nodeNext: array[48, int]
  var nodeKind: array[48, int]
  var nodeLive: array[48, bool]
  var heads: array[8, int]
  var branchChild: array[8, int]
  var attachedOwner: array[8, int]
  var wrapperForChild: array[8, int]
  var statuses: array[48, int64]
  var results: array[48, int64]
  for h in 0 ..< 8:
    heads[h] = -1; branchChild[h] = -1; attachedOwner[h] = -1; wrapperForChild[h] = -1
  var nodeCount = 0

  for i in 0 ..< q:
    let op = int(input[1 + 3*i])
    let a = int(input[2 + 3*i])
    let b = input[3 + 3*i]
    heads[a] = normalize(heads[a], nodeKind, nodeLive, nodeNext)
    let head = heads[a]
    statuses[i] = 1
    if op == 0:
      nodeValues[nodeCount] = b; nodeNext[nodeCount] = head; nodeKind[nodeCount] = 0
      nodeLive[nodeCount] = false; heads[a] = nodeCount; nodeCount += 1
    elif op == 1:
      if head < 0 or (nodeKind[head] == 1 and nodeLive[head]):
        statuses[i] = 0
      else:
        results[i] = nodeValues[head]
        heads[a] = normalize(nodeNext[head], nodeKind, nodeLive, nodeNext)
        if heads[a] < 0 and attachedOwner[a] >= 0:
          let owner = attachedOwner[a]
          nodeLive[wrapperForChild[a]] = false; branchChild[owner] = -1
          attachedOwner[a] = -1; wrapperForChild[a] = -1
    elif op == 2:
      let found = topValue(head, nodeKind, nodeLive, nodeNext, nodeValues)
      if found.ok: results[i] = found.value else: statuses[i] = 0
    elif op == 3:
      if head >= 0 and nodeKind[head] == 1 and nodeLive[head]: results[i] = 1
    else:
      let child = int(b)
      heads[child] = normalize(heads[child], nodeKind, nodeLive, nodeNext)
      let ownerTop = topValue(head, nodeKind, nodeLive, nodeNext, nodeValues)
      if a == child or not ownerTop.ok or attachedOwner[a] >= 0 or branchChild[a] >= 0
          or attachedOwner[child] >= 0 or branchChild[child] >= 0: return -1
      if heads[child] < 0: results[i] = 0
      else:
        nodeValues[nodeCount] = 0; nodeNext[nodeCount] = head; nodeKind[nodeCount] = 1
        nodeLive[nodeCount] = true
        let wrapper = nodeCount; nodeCount += 1; heads[a] = wrapper
        branchChild[a] = child; attachedOwner[child] = a; wrapperForChild[child] = wrapper
        results[i] = 1

  let required = 16 * q
  if output == nil or capacity < csize_t(required): return -2
  for i in 0 ..< q:
    storeLe(output, 16*i, statuses[i]); storeLe(output, 16*i+8, results[i])
  int64(required)
