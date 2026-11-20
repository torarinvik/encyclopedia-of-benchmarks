const
  MaxN = 8
  MaxInputLength = 66

proc housing_top_trading_cycles*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "housing_top_trading_cycles".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(1 + n * n): return -1

  var preferences: array[MaxN * MaxN, int]
  var cursor = 1
  for agent in 0 ..< n:
    var seen: array[MaxN, bool]
    for rank in 0 ..< n:
      let houseValue = input[cursor]
      inc cursor
      if houseValue < 0 or houseValue >= nValue: return -1
      let house = int(houseValue)
      if seen[house]: return -1
      seen[house] = true
      preferences[agent * n + rank] = house

  var agentActive: array[MaxN, bool]
  var houseActive: array[MaxN, bool]
  var allocation: array[MaxN, int]
  for index in 0 ..< n:
    agentActive[index] = true
    houseActive[index] = true
  var activeCount = n
  while activeCount > 0:
    var choice: array[MaxN, int]
    for agent in 0 ..< n:
      if not agentActive[agent]: continue
      choice[agent] = -1
      for rank in 0 ..< n:
        let house = preferences[agent * n + rank]
        if houseActive[house]:
          choice[agent] = house
          break
      if choice[agent] < 0: return -1

    # Contract each agent -> chosen house -> owner edge pair into one agent edge.
    var nextAgent: array[MaxN, int]
    for agent in 0 ..< n:
      if agentActive[agent]: nextAgent[agent] = choice[agent]

    var state: array[MaxN, int]
    var pathPosition: array[MaxN, int]
    for agent in 0 ..< n: pathPosition[agent] = -1
    var selectedThisRound: array[MaxN, bool]
    var path: array[MaxN, int]
    for start in 0 ..< n:
      if not agentActive[start] or state[start] != 0: continue
      var current = start
      var pathLength = 0
      while state[current] == 0:
        state[current] = 1
        pathPosition[current] = pathLength
        path[pathLength] = current
        inc pathLength
        current = nextAgent[current]
      if state[current] == 1:
        let cycleStart = pathPosition[current]
        for index in cycleStart ..< pathLength:
          selectedThisRound[path[index]] = true
      for index in 0 ..< pathLength:
        state[path[index]] = 2
        pathPosition[path[index]] = -1

    var removed = 0
    for agent in 0 ..< n:
      if selectedThisRound[agent]:
        allocation[agent] = choice[agent]
        agentActive[agent] = false
        houseActive[choice[agent]] = false
        inc removed
    if removed == 0: return -1
    activeCount -= removed

  var packed = 1'i64
  for agent in 0 ..< n:
    packed += int64(allocation[agent]) shl (3 * agent)
  packed
