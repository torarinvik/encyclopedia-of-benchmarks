proc zpgAttractor(active: int64, player: int, target: int64,
                  owners, adjacency: array[8, int64], n: int): int64 =
  var attracted = target
  while true:
    var additions = 0'i64
    for vertex in 0..<n:
      let bit = 1'i64 shl vertex
      if (active and bit) == 0 or (attracted and bit) != 0: continue
      let successors = adjacency[vertex] and active
      if owners[vertex] == player:
        if (successors and attracted) != 0: additions = additions or bit
      elif successors != 0 and (successors and (not attracted)) == 0:
        additions = additions or bit
    if additions == 0: return attracted
    attracted = attracted or additions

proc zpgSolve(active: int64, owners, priorities, adjacency: array[8, int64], n: int): int64 =
  if active == 0: return 0
  var lowest = 6'i64
  for vertex in 0..<n:
    if (active and (1'i64 shl vertex)) != 0 and priorities[vertex] < lowest:
      lowest = priorities[vertex]
  let player = int(lowest and 1)
  var target = 0'i64
  for vertex in 0..<n:
    if (active and (1'i64 shl vertex)) != 0 and priorities[vertex] == lowest:
      target = target or (1'i64 shl vertex)
  let first = zpgAttractor(active, player, target, owners, adjacency, n)
  let remainder = active and (not first)
  let evenFirst = zpgSolve(remainder, owners, priorities, adjacency, n)
  let oddFirst = remainder and (not evenFirst)
  let opponentRegion = if player == 1: evenFirst else: oddFirst
  if opponentRegion == 0:
    return evenFirst or (if player == 0: first else: 0'i64)
  let second = zpgAttractor(active, 1 - player, opponentRegion, owners, adjacency, n)
  let evenSecond = zpgSolve(active and (not second), owners, priorities, adjacency, n)
  return evenSecond or (if player == 1: second else: 0'i64)

proc zielonka_parity_game_solver*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "zielonka_parity_game_solver".} =
  if input == nil or length < 6 or length > 59: return -1
  let vertexRaw = input[0]
  let edgeRaw = input[1]
  if vertexRaw < 1 or vertexRaw > 8 or edgeRaw < vertexRaw or edgeRaw > 20: return -1
  let n = int(vertexRaw)
  let edgeCount = int(edgeRaw)
  if length != csize_t(2 + 2 * n + 2 * edgeCount): return -1
  var owners: array[8, int64]
  var priorities: array[8, int64]
  var adjacency: array[8, int64]
  var outdegree: array[8, int]
  var cursor = 2
  for vertex in 0..<n:
    let owner = input[cursor]
    let priority = input[cursor + 1]
    cursor += 2
    if owner < 0 or owner > 1 or priority < 0 or priority > 5: return -1
    owners[vertex] = owner
    priorities[vertex] = priority
  for _ in 0..<edgeCount:
    let sourceRaw = input[cursor]
    let destinationRaw = input[cursor + 1]
    cursor += 2
    if sourceRaw < 0 or sourceRaw >= vertexRaw or destinationRaw < 0 or destinationRaw >= vertexRaw:
      return -1
    let source = int(sourceRaw)
    let destination = int(destinationRaw)
    let bit = 1'i64 shl destination
    if (adjacency[source] and bit) != 0: return -1
    adjacency[source] = adjacency[source] or bit
    outdegree[source] += 1
  for vertex in 0..<n:
    if outdegree[vertex] == 0: return -1
  return zpgSolve((1'i64 shl n) - 1, owners, priorities, adjacency, n)
