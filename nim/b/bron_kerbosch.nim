type I64Input = ptr UncheckedArray[int64]

const MaxVertices = 5

func populationCount(value: uint64): int =
  var bits = value
  while bits != 0:
    result += int(bits and 1'u64)
    bits = bits shr 1

func search(vertexCount: int, adjacency: array[MaxVertices, uint64],
            clique, possible, excluded: uint64): uint64 =
  if possible == 0 and excluded == 0: return 1'u64 shl clique

  var pivot = -1
  var greatestDegree = -1
  let pivotChoices = possible or excluded
  for vertex in 0 ..< vertexCount:
    if (pivotChoices and (1'u64 shl vertex)) == 0: continue
    let degree = populationCount(adjacency[vertex])
    if degree > greatestDegree:
      pivot = vertex
      greatestDegree = degree

  var candidates = possible
  if pivot >= 0: candidates = candidates and not adjacency[pivot]
  var remainingPossible = possible
  var remainingExcluded = excluded
  for vertex in 0 ..< vertexCount:
    let bit = 1'u64 shl vertex
    if (candidates and bit) == 0: continue
    result = result or search(vertexCount, adjacency, clique or bit,
                              remainingPossible and adjacency[vertex], remainingExcluded and adjacency[vertex])
    remainingPossible = remainingPossible and not bit
    remainingExcluded = remainingExcluded or bit

proc bron_kerbosch*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "bron_kerbosch".} =
  if input == nil or length < 1 or length > 7: return -1
  if input[0] < 0 or input[0] > MaxVertices: return -1
  let vertexCount = int(input[0])
  if length != csize_t(vertexCount + 1): return -1

  let vertexMask = (1'u64 shl vertexCount) - 1
  var adjacency: array[MaxVertices, uint64]
  for vertex in 0 ..< vertexCount:
    let row = input[vertex + 1]
    if row < 0 or (uint64(row) and not vertexMask) != 0: return -1
    adjacency[vertex] = uint64(row) and not (1'u64 shl vertex)
  for left in 0 ..< vertexCount:
    for right in left + 1 ..< vertexCount:
      if ((adjacency[left] shr right) and 1) != ((adjacency[right] shr left) and 1): return -1
  int64(search(vertexCount, adjacency, 0, vertexMask, 0))
