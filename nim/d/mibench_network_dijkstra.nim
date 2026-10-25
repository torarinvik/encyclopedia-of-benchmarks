const MaxNodes = 6
const MaxQueueItems = 1024
const NoneCost = 9999'i64
type
  QueueItem = object
    node: int
    distance: int64
    previous: int

proc mibench_network_dijkstra*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "mibench_network_dijkstra".} =
  if input == nil or length < 3: return -1
  let nodeValue = input[0]
  if nodeValue < 1 or nodeValue > MaxNodes: return -1
  let nodes = int(nodeValue)
  if length != csize_t(2 + nodes * nodes): return -1
  let sourceValue = input[1]
  if sourceValue < 0 or sourceValue >= nodeValue: return -1
  for index in 0 ..< nodes * nodes:
    let cost = input[2 + index]
    if cost != NoneCost and (cost < 0 or cost > 31): return -1

  var distance: array[MaxNodes, int64]
  var reachable: array[MaxNodes, bool]
  var queue: array[MaxQueueItems, QueueItem]
  for node in 0 ..< nodes: distance[node] = NoneCost
  let source = int(sourceValue)
  distance[source] = 0
  reachable[source] = true
  var head = 0
  var tail = 0
  queue[tail] = QueueItem(node: source, distance: 0, previous: int(NoneCost))
  inc tail
  while head < tail:
    let item = queue[head]
    inc head
    for destination in 0 ..< nodes:
      let cost = input[2 + item.node * nodes + destination]
      if cost == NoneCost: continue
      let candidate = item.distance + cost
      if not reachable[destination] or distance[destination] > candidate:
        distance[destination] = candidate
        reachable[destination] = true
        if tail >= MaxQueueItems: return -2
        queue[tail] = QueueItem(node: destination, distance: candidate, previous: item.node)
        inc tail
  var checksum = 0'i64
  var mask = 0'u64
  for node in 0 ..< nodes:
    if reachable[node]:
      checksum += int64(node + 1) * distance[node]
      mask = mask or (1'u64 shl node)
  checksum + int64(mask)
