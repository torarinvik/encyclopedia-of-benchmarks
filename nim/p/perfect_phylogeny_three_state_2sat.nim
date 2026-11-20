const MaxTaxa = 8
const MaxCharacters = 8
const MaxLiterals = 48
const MaxInput = 67
type Graph = array[MaxLiterals, array[MaxLiterals, bool]]

proc addClause(graph: var Graph, reverse: var Graph, left, right: int) =
  let fromLeft = left xor 1
  let fromRight = right xor 1
  graph[fromLeft][right] = true
  reverse[right][fromLeft] = true
  graph[fromRight][left] = true
  reverse[left][fromRight] = true

proc solve(values: ptr UncheckedArray[int64], length: int): int64 =
  if length < 2 or length > MaxInput: return -1
  let taxaRaw = values[0]
  let charactersRaw = values[1]
  if taxaRaw < 1 or taxaRaw > MaxTaxa or charactersRaw < 0 or charactersRaw > MaxCharacters: return -1
  let taxa = int(taxaRaw)
  let characters = int(charactersRaw)
  if length != 2 + taxa * characters: return -1

  var masks: array[MaxCharacters, array[3, uint16]]
  for taxon in 0 ..< taxa:
    for character in 0 ..< characters:
      let state = values[2 + taxon * characters + character]
      if state < 0 or state > 2: return -1
      masks[character][int(state)] = masks[character][int(state)] or (uint16(1) shl taxon)

  var graph, reverse: Graph
  for character in 0 ..< characters:
    let v0 = 3 * character
    addClause(graph, reverse, 2 * v0, 2 * (v0 + 1))
    addClause(graph, reverse, 2 * v0, 2 * (v0 + 2))
    addClause(graph, reverse, 2 * (v0 + 1), 2 * (v0 + 2))
    var present = 0
    var missing = 0
    for state in 0 ..< 3:
      if masks[character][state] == 0: missing = state else: inc present
    if present == 2:
      let absentLiteral = 2 * (3 * character + missing) + 1
      addClause(graph, reverse, absentLiteral, absentLiteral)
  let universe = (uint16(1) shl taxa) - 1
  for leftCharacter in 0 ..< characters:
    for rightCharacter in leftCharacter + 1 ..< characters:
      for leftState in 0 ..< 3:
        let left = masks[leftCharacter][leftState]
        for rightState in 0 ..< 3:
          let right = masks[rightCharacter][rightState]
          if (left and right) != 0 and (left and universe and not right) != 0 and
             (right and universe and not left) != 0 and (universe and not (left or right)) != 0:
            let leftVariable = 3 * leftCharacter + leftState
            let rightVariable = 3 * rightCharacter + rightState
            addClause(graph, reverse, 2 * leftVariable + 1, 2 * rightVariable + 1)

  let literalCount = 6 * characters
  var seen: array[MaxLiterals, bool]
  var order, stack, nextIndex: array[MaxLiterals, int]
  var orderCount = 0
  for start in 0 ..< literalCount:
    if seen[start]: continue
    var top = 1
    stack[0] = start
    seen[start] = true
    while top > 0:
      let vertex = stack[top - 1]
      var next = nextIndex[vertex]
      while next < literalCount and (not graph[vertex][next] or seen[next]): inc next
      if next < literalCount:
        nextIndex[vertex] = next + 1
        seen[next] = true
        stack[top] = next
        inc top
      else:
        order[orderCount] = vertex
        inc orderCount
        dec top
  var component: array[MaxLiterals, int]
  for i in 0 ..< literalCount: component[i] = -1
  var label = 0
  while orderCount > 0:
    dec orderCount
    let start = order[orderCount]
    if component[start] >= 0: continue
    var top = 1
    stack[0] = start
    component[start] = label
    while top > 0:
      dec top
      let vertex = stack[top]
      for next in 0 ..< literalCount:
        if reverse[vertex][next] and component[next] < 0:
          component[next] = label
          stack[top] = next
          inc top
    inc label
  for variable in 0 ..< 3 * characters:
    if component[2 * variable] == component[2 * variable + 1]: return 0
  return 1

proc perfect_phylogeny_three_state_2sat*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "perfect_phylogeny_three_state_2sat".} =
  if input.isNil or length < 2 or length > MaxInput: return -1
  solve(input, int(length))
