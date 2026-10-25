const MaxModules = 8
const MaxNets = 16
const MaxInput = 146

type
  Nets = array[MaxNets, array[MaxModules, int]]
  Degrees = array[MaxNets, int]

proc edgeCut(side: array[MaxModules, int], nets: Nets, degrees: Degrees, netCount: int): int =
  for net in 0 ..< netCount:
    for i in 0 ..< degrees[net]:
      for j in i + 1 ..< degrees[net]:
        if side[nets[net][i]] != side[nets[net][j]]: inc result

proc netCut(side: array[MaxModules, int], nets: Nets, degrees: Degrees, netCount: int): int =
  for net in 0 ..< netCount:
    let first = side[nets[net][0]]
    for i in 1 ..< degrees[net]:
      if side[nets[net][i]] != first:
        inc result
        break

proc ptrdist_ks*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "ptrdist_ks".} =
  if input == nil or length < 2 or length > MaxInput: return -1
  let moduleValue = input[0]
  let netValue = input[1]
  if moduleValue < 2 or moduleValue > MaxModules or moduleValue mod 2 != 0 or netValue < 0 or netValue > MaxNets: return -1
  let modules = int(moduleValue)
  let netCount = int(netValue)
  var nets: Nets
  var degrees: Degrees
  var cursor = 2
  for net in 0 ..< netCount:
    if cursor >= int(length): return -1
    let degreeValue = input[cursor]
    inc cursor
    if degreeValue < 2 or degreeValue > moduleValue or cursor + int(degreeValue) > int(length): return -1
    let degree = int(degreeValue)
    degrees[net] = degree
    for i in 0 ..< degree:
      let memberValue = input[cursor]
      inc cursor
      if memberValue < 0 or memberValue >= moduleValue: return -1
      let member = int(memberValue)
      for j in 0 ..< i:
        if nets[net][j] == member: return -1
      nets[net][i] = member
  if cursor != int(length): return -1

  let half = modules div 2
  var orderA, orderB: array[MaxModules, int]
  var side: array[MaxModules, int]
  for i in 0 ..< half:
    orderA[i] = i
    orderB[i] = half + i
    side[i] = 0
    side[half + i] = 1
  var acceptedPasses = 0
  while true:
    var work = side
    var remainingA = orderA
    var remainingB = orderB
    var selectedA, selectedB: array[MaxModules, int]
    var countA = half
    var countB = half
    var cumulativeGain = 0
    var bestGain = low(int)
    var bestPrefix = 0
    for step in 0 ..< half:
      let baseline = edgeCut(work, nets, degrees, netCount)
      var pairGain = low(int)
      var chosenA = -1
      var chosenB = -1
      for ai in 0 ..< countA:
        let a = remainingA[ai]
        for bi in 0 ..< countB:
          let b = remainingB[bi]
          work[a] = 1
          work[b] = 0
          let gain = baseline - edgeCut(work, nets, degrees, netCount)
          work[a] = 0
          work[b] = 1
          if gain > pairGain:
            pairGain = gain
            chosenA = a
            chosenB = b
      selectedA[step] = chosenA
      selectedB[step] = chosenB
      work[chosenA] = 1
      work[chosenB] = 0
      for i in 0 ..< countA:
        if remainingA[i] == chosenA:
          for j in i ..< countA - 1: remainingA[j] = remainingA[j + 1]
          dec countA
          break
      for i in 0 ..< countB:
        if remainingB[i] == chosenB:
          for j in i ..< countB - 1: remainingB[j] = remainingB[j + 1]
          dec countB
          break
      cumulativeGain += pairGain
      if cumulativeGain > bestGain:
        bestGain = cumulativeGain
        bestPrefix = step + 1
    if bestGain <= 0: break
    var nextA, nextB: array[MaxModules, int]
    for i in 0 ..< bestPrefix:
      nextA[i] = selectedB[i]
      nextB[i] = selectedA[i]
    for i in bestPrefix ..< half:
      nextA[i] = selectedA[i]
      nextB[i] = selectedB[i]
    orderA = nextA
    orderB = nextB
    for i in 0 ..< half:
      side[orderA[i]] = 0
      side[orderB[i]] = 1
    inc acceptedPasses

  var mask = 0'i64
  for i in 0 ..< modules:
    if side[i] == 0: mask = mask or (1'i64 shl i)
  mask + (int64(edgeCut(side, nets, degrees, netCount)) shl 8) +
    (int64(netCut(side, nets, degrees, netCount)) shl 17) + (int64(acceptedPasses) shl 22)
