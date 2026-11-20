const
  MaxN = 8
  MaxM = 10
  MaxInputLength = 43
  MaxArcs = 2 * MaxM
  CostOffset = 81'i64

type ResidualArc = object
  fromVertex: int
  toVertex: int
  reverseIndex: int
  capacity: int64
  cost: int64

proc minimum_cost_circulation_cost_scaling*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_cost_circulation_cost_scaling".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nArg = input[0]
  let mArg = input[1]
  if nArg < 1 or nArg > MaxN or mArg < 0 or mArg > MaxM: return -1
  let n = int(nArg)
  let m = int(mArg)
  if length != csize_t(2 + 4 * m): return -1

  var edges: array[MaxArcs, ResidualArc]
  var maxScaledCost = 0'i64
  for index in 0 ..< m:
    let offset = 2 + 4 * index
    let fromArg = input[offset]
    let toArg = input[offset + 1]
    let capacity = input[offset + 2]
    let cost = input[offset + 3]
    if fromArg < 0 or fromArg >= nArg or toArg < 0 or toArg >= nArg or
        capacity < 0 or capacity > 2 or cost < -4 or cost > 4:
      return -1
    let fromVertex = int(fromArg)
    let toVertex = int(toArg)
    let scaledCost = cost * int64(n + 1)
    let forward = 2 * index
    let reverse = forward + 1
    edges[forward] = ResidualArc(fromVertex: fromVertex, toVertex: toVertex,
      reverseIndex: reverse, capacity: capacity, cost: scaledCost)
    edges[reverse] = ResidualArc(fromVertex: toVertex, toVertex: fromVertex,
      reverseIndex: forward, capacity: 0, cost: -scaledCost)
    maxScaledCost = max(maxScaledCost, abs(scaledCost))

  var epsilon = 1'i64
  while epsilon < maxScaledCost: epsilon *= 2
  var price: array[MaxN, int64]
  let arcCount = 2 * m

  while epsilon > 1:
    epsilon = epsilon div 2
    var excess: array[MaxN, int64]
    for vertex in 0 ..< n: excess[vertex] = 0

    for edgeIndex in 0 ..< arcCount:
      if edges[edgeIndex].capacity <= 0: continue
      let fromVertex = edges[edgeIndex].fromVertex
      let toVertex = edges[edgeIndex].toVertex
      let reducedCost = edges[edgeIndex].cost + price[fromVertex] - price[toVertex]
      if reducedCost < 0:
        let amount = edges[edgeIndex].capacity
        edges[edgeIndex].capacity = 0
        edges[edges[edgeIndex].reverseIndex].capacity += amount
        excess[fromVertex] -= amount
        excess[toVertex] += amount

    var queue: array[MaxN, int]
    var queued: array[MaxN, bool]
    var head = 0
    var tail = 0
    var queueCount = 0
    for vertex in 0 ..< n:
      if excess[vertex] > 0:
        queue[tail] = vertex
        tail = (tail + 1) mod n
        inc queueCount
        queued[vertex] = true

    while queueCount > 0:
      let vertex = queue[head]
      head = (head + 1) mod n
      dec queueCount
      queued[vertex] = false
      while excess[vertex] > 0:
        var admissible = -1
        for edgeIndex in 0 ..< arcCount:
          if edges[edgeIndex].fromVertex != vertex or edges[edgeIndex].toVertex == vertex or
              edges[edgeIndex].capacity <= 0:
            continue
          let toVertex = edges[edgeIndex].toVertex
          if edges[edgeIndex].cost + price[vertex] - price[toVertex] < 0:
            admissible = edgeIndex
            break

        if admissible >= 0:
          let toVertex = edges[admissible].toVertex
          let reverse = edges[admissible].reverseIndex
          let amount = min(excess[vertex], edges[admissible].capacity)
          edges[admissible].capacity -= amount
          edges[reverse].capacity += amount
          let oldExcess = excess[toVertex]
          excess[vertex] -= amount
          excess[toVertex] += amount
          if oldExcess <= 0 and excess[toVertex] > 0 and not queued[toVertex]:
            queue[tail] = toVertex
            tail = (tail + 1) mod n
            inc queueCount
            queued[toVertex] = true
        else:
          var hasExit = false
          var bestPrice = low(int64)
          for edgeIndex in 0 ..< arcCount:
            if edges[edgeIndex].fromVertex != vertex or edges[edgeIndex].capacity <= 0: continue
            let toVertex = edges[edgeIndex].toVertex
            let candidate = price[toVertex] - edges[edgeIndex].cost - epsilon
            if not hasExit or candidate > bestPrice:
              hasExit = true
              bestPrice = candidate
          if not hasExit: return -1
          price[vertex] = bestPrice

    for vertex in 0 ..< n:
      if excess[vertex] != 0: return -1

  var totalCost = 0'i64
  for index in 0 ..< m:
    let capacity = input[2 + 4 * index + 2]
    let cost = input[2 + 4 * index + 3]
    let flow = capacity - edges[2 * index].capacity
    totalCost += flow * cost
  totalCost + CostOffset
