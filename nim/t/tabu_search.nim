const MaxCities = 6
const MaxTour = 7
const MaxCandidates = 32
const MaxOutputBytes = 36

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc routeCost(route: array[MaxTour, int64], routeLength: int,
    edgeCost: array[MaxCities * MaxCities, int64]): int64 =
  for i in 0 ..< routeLength - 1:
    result += edgeCost[int(route[i]) * MaxCities + int(route[i + 1])]

proc tabu_search*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tabu_search".} =
  if input == nil or inputLength < 3 or inputLength > 19: return -1
  if input[0] < 4 or input[0] > 6 or input[1] < 0 or input[1] > 8 or input[2] < 1 or input[2] > 3: return -1
  let cities = int(input[0])
  let iterations = int(input[1])
  let tabuSize = int(input[2])
  let edgeCount = cities * (cities - 1) div 2
  if int(inputLength) != 3 + edgeCount: return -1
  var edgeCost: array[MaxCities * MaxCities, int64]
  var offset = 3
  for left in 0 ..< cities:
    for right in left + 1 ..< cities:
      let weight = input[offset]
      if weight < 1 or weight > 99: return -1
      edgeCost[left * MaxCities + right] = weight
      edgeCost[right * MaxCities + left] = weight
      inc offset

  var solution: array[MaxTour, int64]
  var solutionLength = 0
  var visited: array[MaxCities, bool]
  var current = 0
  while not visited[current]:
    var minimum = 10_000'i64
    var bestNode = current
    for node in 0 ..< cities:
      if node != current and not visited[node]:
        let weight = edgeCost[current * MaxCities + node]
        if weight < minimum:
          minimum = weight
          bestNode = node
    visited[current] = true
    solution[solutionLength] = int64(current)
    inc solutionLength
    current = bestNode
  solution[solutionLength] = 0
  inc solutionLength
  var bestSolution = solution
  var bestCost = routeCost(solution, solutionLength, edgeCost)

  var tabu: array[3, array[2, int64]]
  var tabuCount = 0
  for iteration in 0 ..< iterations:
    var candidates: array[MaxCandidates, array[MaxTour, int64]]
    var candidateCosts: array[MaxCandidates, int64]
    var candidateCount = 0
    for first in 1 ..< solutionLength - 1:
      for second in 1 ..< solutionLength - 1:
        if first == second: continue
        var candidate = solution
        swap(candidate[first], candidate[second])
        var duplicate = false
        for prior in 0 ..< candidateCount:
          var same = true
          for i in 0 ..< solutionLength:
            if candidates[prior][i] != candidate[i]: same = false
          if same: duplicate = true
        if not duplicate:
          candidates[candidateCount] = candidate
          candidateCosts[candidateCount] = routeCost(candidate, solutionLength, edgeCost)
          inc candidateCount
    # Stable insertion sort by candidate route cost.
    for i in 1 ..< candidateCount:
      var j = i
      while j > 0 and candidateCosts[j] < candidateCosts[j - 1]:
        swap(candidateCosts[j], candidateCosts[j - 1])
        swap(candidates[j], candidates[j - 1])
        dec j
    for selected in 0 ..< candidateCount:
      var difference = -1
      for i in 0 ..< solutionLength:
        if candidates[selected][i] != solution[i]:
          difference = i
          break
      if difference < 0: continue
      let newCity = candidates[selected][difference]
      let oldCity = solution[difference]
      var isTabu = false
      for i in 0 ..< tabuCount:
        if (tabu[i][0] == newCity and tabu[i][1] == oldCity) or
            (tabu[i][0] == oldCity and tabu[i][1] == newCity): isTabu = true
      if isTabu: continue
      tabu[tabuCount] = [newCity, oldCity]
      inc tabuCount
      if tabuCount >= tabuSize:
        for i in 0 ..< tabuCount - 1: tabu[i] = tabu[i + 1]
        dec tabuCount
      solution = candidates[selected]
      if candidateCosts[selected] < bestCost:
        bestCost = candidateCosts[selected]
        bestSolution = solution
      break

  var staged: array[MaxOutputBytes, uint8]
  let stagedPtr = cast[ptr UncheckedArray[uint8]](addr staged[0])
  storeI32Le(stagedPtr, 0, int64(solutionLength))
  for i in 0 ..< solutionLength: storeI32Le(stagedPtr, 4 * (i + 1), bestSolution[i])
  storeI32Le(stagedPtr, 4 * (solutionLength + 1), bestCost)
  let outputBytes = (solutionLength + 2) * 4
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for i in 0 ..< outputBytes: output[i] = staged[i]
  int64(outputBytes)
