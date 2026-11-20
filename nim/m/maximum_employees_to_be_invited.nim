const MaxN = 8'i64
const MaxInput = 10

proc maximum_employees_to_be_invited*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_employees_to_be_invited".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 2 or nValue > MaxN or int(length) != int(nValue) + 1: return -1
  let n = int(nValue)
  var favorite: array[MaxN.int, int64]
  var indegree: array[MaxN.int, int64]
  var chain: array[MaxN.int, int64]
  var queue: array[MaxN.int, int]
  var visited: array[MaxN.int, bool]
  for i in 0 ..< n:
    let target = input[i + 1]
    if target < 0 or target >= nValue or target == int64(i): return -1
    favorite[i] = target
    indegree[int(target)] += 1
    chain[i] = 1
  var head = 0
  var tail = 0
  for i in 0 ..< n:
    if indegree[i] == 0:
      queue[tail] = i
      inc tail
  while head < tail:
    let node = queue[head]
    inc head
    let target = int(favorite[node])
    chain[target] = max(chain[target], chain[node] + 1)
    dec indegree[target]
    if indegree[target] == 0:
      queue[tail] = target
      inc tail
  var pairTotal = 0'i64
  var longestCycle = 0'i64
  for start in 0 ..< n:
    if indegree[start] == 0 or visited[start]: continue
    var node = start
    var first = 0
    var second = 0
    var cycleLength = 0
    while not visited[node]:
      visited[node] = true
      if cycleLength == 0: first = node
      elif cycleLength == 1: second = node
      inc cycleLength
      node = int(favorite[node])
    if cycleLength == 2: pairTotal += chain[first] + chain[second]
    elif int64(cycleLength) > longestCycle: longestCycle = int64(cycleLength)
  max(pairTotal, longestCycle)
