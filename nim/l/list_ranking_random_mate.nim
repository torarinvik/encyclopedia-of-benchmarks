const MaxN = 8
const MaxRounds = 32
const MaxInput = 275
const MaxOutput = 64

proc list_ranking_random_mate*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "list_ranking_random_mate".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let head64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or head64 < 0 or head64 >= n64: return -1
  let n = int(n64)
  let head = int(head64)
  if length < csize_t(3 + 2*n): return -1
  let rounds64 = input[2 + 2*n]
  if rounds64 < 0 or rounds64 > int64(MaxRounds) or
      int64(length) != 3 + 2*n64 + rounds64*n64: return -1
  let rounds = int(rounds64)
  var weight: array[MaxN, int64]
  var successor: array[MaxN, int64]
  var indegree: array[MaxN, int]
  var tails = 0
  for index in 0 ..< n:
    weight[index] = input[2 + index]
    successor[index] = input[2 + n + index]
    if weight[index] < 1 or weight[index] > 10000 or successor[index] < -1 or successor[index] >= n64:
      return -1
    if successor[index] == -1:
      inc tails
    else:
      let target = int(successor[index])
      inc indegree[target]
      if indegree[target] > 1: return -1
  if tails != 1 or indegree[head] != 0: return -1
  let coinStart = 3 + 2*n
  for index in 0 ..< rounds*n:
    let coin = input[coinStart + index]
    if coin < 0 or coin > 1: return -1

  var seen: array[MaxN, bool]
  var pathLength = 0
  var node = head64
  while node != -1:
    let index = int(node)
    if seen[index] or pathLength == n: return -1
    seen[index] = true
    inc pathLength
    node = successor[index]
  if pathLength != n: return -1

  var active: array[MaxN, bool]
  var removalRound: array[MaxN, int]
  for index in 0 ..< n:
    active[index] = true
    removalRound[index] = -1
  for round in 0 ..< rounds:
    if successor[head] == -1: break
    let oldSuccessor = successor
    let oldWeight = weight
    var remove: array[MaxN, bool]
    let coinOffset = coinStart + round*n
    for index in 0 ..< n:
      let targetValue = oldSuccessor[index]
      if active[index] and targetValue != -1 and input[coinOffset + index] == 0 and
          input[coinOffset + int(targetValue)] == 1:
        let target = int(targetValue)
        remove[target] = true
        removalRound[target] = round
    for index in 0 ..< n:
      let targetValue = oldSuccessor[index]
      if active[index] and targetValue != -1 and remove[int(targetValue)]:
        let target = int(targetValue)
        weight[index] = oldWeight[index] + oldWeight[target]
        successor[index] = oldSuccessor[target]
    for index in 0 ..< n:
      if remove[index]: active[index] = false
  if successor[head] != -1: return -1

  var rank = weight
  for round in countdown(rounds - 1, 0):
    for index in 0 ..< n:
      if removalRound[index] == round and successor[index] != -1:
        rank[index] += rank[int(successor[index])]
  let outputBytes = 8*n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutput, uint8]
  for index in 0 ..< n:
    let bits = cast[uint64](rank[index])
    for byte in 0 ..< 8:
      staged[8*index + byte] = uint8((bits shr (8*byte)) and 255)
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
