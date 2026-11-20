const MaxN = 10
const MaxStates = 10240
const MaxParseableLength = 93

proc shortest_path_visiting_all_nodes*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "shortest_path_visiting_all_nodes".} =
  if input == nil or length < 2 or length > csize_t(MaxParseableLength): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxN or mValue < 0 or mValue > 45: return -1
  let n = int(nValue)
  let m = int(mValue)
  if m > n*(n-1) div 2 or int(length) != 2 + 2*m: return -1

  var adjacency: array[MaxN, uint16]
  for edge in 0 ..< m:
    let uValue = input[2 + 2*edge]
    let vValue = input[3 + 2*edge]
    if uValue < 0 or vValue < 0 or uValue >= nValue or vValue >= nValue or uValue == vValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    let uBit = 1'u16 shl v
    let vBit = 1'u16 shl u
    if (adjacency[u] and uBit) != 0: return -1
    adjacency[u] = adjacency[u] or uBit
    adjacency[v] = adjacency[v] or vBit

  var reached = 1'u16
  while true:
    let previous = reached
    for vertex in 0 ..< n:
      if (reached and (1'u16 shl vertex)) != 0: reached = reached or adjacency[vertex]
    if reached == previous: break
  let full = (1'u16 shl n) - 1'u16
  if reached != full: return -1

  let stateCount = (1 shl n) * n
  var distance: array[MaxStates, int16]
  var queue: array[MaxStates, uint16]
  for i in 0 ..< stateCount: distance[i] = -1
  var head = 0
  var tail = 0
  for start in 0 ..< n:
    let state = (1 shl start) * n + start
    distance[state] = 0
    queue[tail] = uint16(state)
    inc tail
  while head < tail:
    let state = int(queue[head])
    inc head
    let mask = state div n
    let vertex = state mod n
    if mask == int(full): return int64(distance[state])
    for next in 0 ..< n:
      if (adjacency[vertex] and (1'u16 shl next)) == 0: continue
      let nextMask = mask or (1 shl next)
      let nextState = nextMask*n + next
      if distance[nextState] >= 0: continue
      distance[nextState] = distance[state] + 1
      queue[tail] = uint16(nextState)
      inc tail
  -1
